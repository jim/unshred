require 'chunky_png'

module Unshred
  class Image
    STRIP_WIDTH = 32

    def initialize(path)
      @path = path
      @image = ChunkyPNG::Image.from_file(path)
      @arranged = []
    end

    def unshred!
      Unshred.logger.info 'unshredding...'
      Unshred.logger.info "writing to #{output_path}"

      create_strips
      match_strips
      arrange_strips
      save_arranged_image(output_path)
    end

    private

    def create_strips
      @strips = []

      number_of_strips.times.each do |strip_index|
        strip_offset = strip_index * STRIP_WIDTH

        columns = STRIP_WIDTH.times.map do |i|
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
    end

    def arrange_strips
      strips_to_place = @strips.dup

      placed = @strips.map do |strip|
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

    def save_arranged_image(path)
      output = ChunkyPNG::Image.new(@image.width, @image.height)

      @arranged_strips.each_with_index do |strip, strip_index|
        strip_offset = strip_index * STRIP_WIDTH
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

    def number_of_strips
      @image.width / STRIP_WIDTH
    end
  end
end
