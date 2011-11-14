require 'chunky_png'

module Unshred
  class Image
    STRIP_WIDTH = 32

    def initialize(path)
      @path = path
      @image = ChunkyPNG::Image.from_file(path)
    end

    def unshred!
      Unshred.logger.info 'unshredding...'
      Unshred.logger.info "writing to #{output_path}"


      create_strips
    end

    private

    def create_strips
      @strips = []
      number_of_strips = @image.width / STRIP_WIDTH

      number_of_strips.times.map do |strip_index|
        strip_offset = strip_index * STRIP_WIDTH

        columns = STRIP_WIDTH.times.map do |i|
          @image.column(i + strip_offset)
        end

        @strips << Strip.new(columns)
      end

      Unshred.logger.info "created #{@strips.size} strips"
    end

    def output_path
      extension = File.extname(@path)
      @path.sub(extension, "-unshredded#{extension}")
    end
  end
end
