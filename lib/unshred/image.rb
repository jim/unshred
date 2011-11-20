require 'chunky_png'
require 'ruby-debug'

module Unshred
  class Image
    include Calculations

    def initialize(path, options)
      @path = path
      @image = ChunkyPNG::Image.from_file(path)
      @options = options
      @arranged = []
    end

    def shred!
      Unshred.logger.info 'shredding...'
      Unshred.logger.info "writing to #{output_path}"
    end

    def unshred!
      Unshred.logger.info 'unshredding...'
      Unshred.logger.info "writing to #{output_path}"

      width = find_strips
      create_strips(width)

      match_strips
      arrange_strips
      save_arranged_image(output_path, width)
    end

    private

    def find_strips
      differences = []
      last = 0
      edges = []
      (0...(@image.width - 1)).each do |i|
        l = @image.column(i)
        r = @image.column(i+1)
        this = compute_match(l,r)
        # puts "#{i}+#{i+1} #{compute_match(l,r)}"
        last = this
        differences << [i, this]
      end

      max_strips = @image.width / 2


      differences.sort_by!{|a| a[1]}

      q3 = find_quartile(differences, :upper)
      q1 = find_quartile(differences, :lower)
      iq = q3 - q1

      mild_outlier_threshold = iq * 1.5
      mild_outlier_range = Range.new(q1 - mild_outlier_threshold,
                                     q3 + mild_outlier_threshold)
      differences.sort_by!{|a| a[0]}

      strip_width_options = (4..max_strips).map do |number_of_strips|
        next unless @image.width % number_of_strips == 0
        strip_width = @image.width / number_of_strips
        edges = differences.select do |(index, score)|
          (index + 1) % strip_width == 0
        end
        outliers = edges.select do |(index, score)|
          !mild_outlier_range.include?(score)
        end
        score = (outliers.size.to_f - 1) / edges.size

        [strip_width, score]
      end.compact

      strip_width_options.sort_by!{|(width, score)| score}.reverse!

      strip_width, score = strip_width_options.first
      Unshred.logger.info "Most likely strip width is #{strip_width} at #{score}"
      strip_width
    end

    # This assumes that values have already been sorted
    def find_quartile(values, which)
      index = if which == :lower
        ((values.size + 1) / 4).abs
      else
        ((3 * values.size + 3) / 4).abs
      end
      values[index][1]
    end

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

      Unshred.logger.info "created #{@strips.size} strips"
    end

    def match_strips
      @strips.each do |strip|
        strip.score_strips(@strips - [strip])
      end

      # @strips.each do |strip|
      #   puts strip
      #   puts (@strips - [strip]).map {|s| s.score_for(strip) }.sort
      #   # debugger
      #   best_match = (@strips - [strip]).sort_by {|s| s.score_for(strip) }[-2]
      #   puts best_match
      #   best_match.left = strip
      #   puts
      # end
    end

    def arrange_strips
      strips_to_place = @strips.dup

      placed = @strips.map do |strip|
        unless strip.left
          puts "#{strip.index} NO LEFT"
          next
        end
        puts "#{strip.index}  #{strip.left.index}  #{strip.left_score}"
        strip.left.index
      end

      right_edge = @strips.select do |strip|
        !placed.include?(strip.index)
      end.sort_by {|s| s.left_score }.last

      unless right_edge
        right_edge = @strips.sort_by{|s|s.left_score}.last.left
      end

      puts "Using slice #{right_edge.index} as the right edge."

      @arranged_strips = [strips_to_place.delete(right_edge)]

      until strips_to_place.empty?
        first = @arranged_strips.first
        # puts first.index
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

      output.save(path)
    end

    def output_path
      extension = File.extname(@path)
      @path.sub(extension, "-unshredded#{extension}")
    end

  end
end
