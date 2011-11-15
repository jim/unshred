require 'chunky_png'

module Unshred
  class Strip
    include ChunkyPNG

    attr_accessor :columns

    # Create a strip from an array of pixel column arrays
    def initialize(columns)
      @columns = columns
    end

    def match_left(strip)
      compute_match(@columns.first, strip.columns.last)
    end

    def match_right(strip)
      compute_match(@columns.last, strip.columns.first)
    end

    private

    def compute_match(lcol, rcol)
      differences = lcol.each_with_index.map do |lval, index|
        right_pixel = rcol[index]
        pixel_difference(lval, right_pixel)
      end

      differences.inject {|sum,n| sum + n} / lcol.size.to_f
    end

    def pixel_difference(left_pixel, right_pixel)
      r = Color.r(left_pixel) - Color.r(right_pixel)
      g = Color.g(left_pixel) - Color.g(right_pixel)
      b = Color.b(left_pixel) - Color.b(right_pixel)

      [r,g,b].inject {|sum,n| sum + n.abs }
    end
  end
end
