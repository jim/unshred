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
      arrange_strips
      save_arranged_image(output_path)
    end

    private

    def create_strips
      @strips = []

      number_of_strips.times.map do |strip_index|
        strip_offset = strip_index * STRIP_WIDTH

        columns = STRIP_WIDTH.times.map do |i|
          @image.column(i + strip_offset)
        end

        @strips << Strip.new(columns)
      end

      Unshred.logger.info "created #{@strips.size} strips"
    end

    def arrange_strips
      strips_to_place = @strips.dup
      @arranged << strips_to_place.pop
      runs = strips_to_place.size

      12.times do
        puts
        last = @arranged.last
        first = @arranged.first

        differences = strips_to_place.each_with_index.inject([]) do |acc, (strip, index)|
          acc << [last.match_right(strip), :push, index]
          acc << [first.match_left(strip), :unshift, index]
        end.sort_by {|a| a[0] }

        differences.each do |a|
          index = @strips.index(strips_to_place[a[2]])
          puts "#{a[0]}: #{index}"
        end

        score, method, strip_index = differences.first
        @arranged.send method, strips_to_place.slice!(strip_index)
      end
    end

    def save_arranged_image(path)
      output = ChunkyPNG::Image.new(@image.width, @image.height)

      @arranged.each_with_index do |strip, strip_index|
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
