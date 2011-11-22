require 'chunky_png'

require 'unshred/strip'
require 'unshred/calculations'

module Unshred
  class Image
    include Calculations

    # The options hash should include:
    # path - the file to process
    # width - when shredding, the width of shred to create
    # output - the path to write output to
    def initialize(options)
      @options = options
      @image = ChunkyPNG::Image.from_file(@options.path)
    end

    def shred!
      Unshred.logger.info 'Shredding...'

      shredded = ChunkyPNG::Image.new(@image.width, @image.height)
      valid_widths = valid_strip_widths(@image.width)

      unless valid_widths.include?(@options.width)
        Unshred.logger.info "#{@options.width} is not a valid strip width!" unless @options.width.nil?
        Unshred.logger.info "Please specify a strip width using the -w option."
        Unshred.logger.info "Valid widths are: #{valid_widths.map(&:to_s).join(', ')}"
        exit(1)
      end

      strip_width = @options.width

      create_strips(strip_width)
      @arranged_strips = @strips.shuffle
      save_arranged_image(output_path, strip_width)
    end

    def unshred!
      Unshred.logger.info 'Unshredding...'

      strip_width = find_strip_width
      create_strips(strip_width)

      match_strips
      arrange_strips
      save_arranged_image(output_path, strip_width)
    end


    private

    # Determine the width of strips in the source image.
    #
    # This is computed by calculating a score for all potental strip edges,
    # and then rating the possible strip widths by how low their score was.
    # This number is weighted slightly to give smaller strips an advantage
    # over wider ones.
    def find_strip_width
      differences = []
      last = 0
      edges = []

      # Calculate the difference between the columns of pixels surrounding
      # potential strip edges, resulting in an array of [index, score] pairs.
      (0...(@image.width - 1)).each do |i|
        l = @image.column(i)
        r = @image.column(i+1)
        this = compute_match(l,r)
        # puts "#{i}+#{i+1} #{compute_match(l,r)}"
        last = this
        differences << [i, this]
      end

      max_strips = @image.width / 2

      # Quartile calculations require having the data in numeric order.
      differences.sort_by!{|a| a[1]}

      # Find the lower and upper quartiles, and the iq
      q3 = find_quartile(differences, :upper)
      q1 = find_quartile(differences, :lower)
      iq = q3 - q1

      # Calculate the range to be used to determine if an edge is statistically an
      # outlier, with the assumption that an outlier is most likely to be a strip
      # edge. Using 1.5 as an iq multiplier will find mild outliers. This number
      # may need to be adjusted depending on the dataset, but for photographic
      # images it seems to work fairly well.
      mild_outlier_threshold = iq * 1.5
      mild_outlier_range = Range.new(q1 - mild_outlier_threshold,
                                     q3 + mild_outlier_threshold)

      # Resort the data by index to make it easer to work with.
      differences.sort_by!{|a| a[0]}

      # Calculate a score for all possible strip widths, resulting in an array
      # of [strip_count, score] pairs. The score is based on what proportion of that
      # strip width's edges are outliers.

      valid_widths = valid_strip_widths(@image.width)
      strip_width_options = (4..max_strips).map do |number_of_strips|
        strip_width = @image.width / number_of_strips

        # Skip invalid strip widths
        next unless valid_widths.include?(strip_width)

        # Find the edges for a given strip width
        edges = differences.select do |(index, score)|
          (index + 1) % strip_width == 0
        end

        # Keep only outliers
        outliers = edges.select do |(index, score)|
          !mild_outlier_range.include?(score)
        end

        # Subtracting 1 from the nominator weights the score in favor of smaller
        # strip widths, as it's easier for a smaller number of strips (such as 2)
        # to have all outliers.
        score = (outliers.size.to_f - 1) / edges.size

        [strip_width, score]
      end.compact

      # Order by score, with the highest score first.
      strip_width_options.sort_by!{|(width, score)| score}.reverse!
      strip_width, score = strip_width_options.first

      Unshred.logger.info "Most likely strip width is #{strip_width} at #{score}"

      strip_width
    end

    def valid_strip_widths(width)
      (4..(width/2)).select do |number_of_strips|
        width % number_of_strips == 0
      end
    end

    # This assumes that values has already been sorted
    def find_quartile(values, which)
      index = if which == :lower
        ((values.size + 1) / 4).abs
      else
        ((3 * values.size + 3) / 4).abs
      end
      values[index][1]
    end

    # Create Strip objects with the specified width using image data from @image.
    def create_strips(width)
      @strips = []

      number_of_strips = @image.width / width

      number_of_strips.times.each do |strip_index|
        strip_offset = strip_index * width

        columns = width.times.map do |i|
          @image.column(i + strip_offset)
        end

        @strips << Strip.new(columns, strip_index)
      end

      Unshred.logger.info "Created #{@strips.size} strips"
    end

    def match_strips
      @strips.each do |strip|
        strip.score_strips(@strips - [strip])
      end
    end

    def arrange_strips
      strips_to_place = @strips.dup

      # Get a list of strips that have been matched by another strip
      placed = @strips.map { |strip| strip.left.index }

      # The right edge is most likely to not have been matched, and have the
      # lowest match score.
      right_edge = @strips.select do |strip|
        !placed.include?(strip.index)
      end.sort_by {|s| s.left_score }.last

      # If we don't have a right edge yet, use the left match with the weakest score
      unless right_edge
        right_edge = @strips.sort_by{|s|s.left_score}.last.left
      end

      Unshred.logger.info "Using slice #{right_edge.index} as the right edge."

      @arranged_strips = [strips_to_place.delete(right_edge)]

      until strips_to_place.empty?
        first = @arranged_strips.first
        next_strip = strips_to_place.find {|s| first.left == s }
        strips_to_place.delete(next_strip)
        @arranged_strips.unshift(next_strip)
      end

    end

    def save_arranged_image(path, strip_width)
      output = ChunkyPNG::Image.new(@image.width, @image.height)

      @arranged_strips.each_with_index do |strip, strip_index|
        strip_offset = strip_index * strip_width
        strip.columns.each_with_index do |column, column_index|
          output.replace_column!(strip_offset + column_index, column)
        end
      end

      Unshred.logger.info "Writing to #{path}"
      output.save(path)
    end

    def output_path
      return @options.output_path if @options.output_path
      extension = File.extname(@options.path)
      operation = @options.operation + 'ded'
      @options.path.sub(extension, "-#{operation}#{extension}")
    end

  end
end
