require 'chunky_png'

module Unshred
  module Calculations
    include ChunkyPNG
    def compute_match(lcol, rcol)
      differences = lcol.each_with_index.map do |lval, index|
        right_pixel = rcol[index]
        pixel_difference(lval, right_pixel)
      end

      differences.inject {|sum,n| sum + n} / lcol.size.to_f
    end

    # Calculate the difference by comparing the red channel data, as it
    # typically contains the msot contrast.
    def pixel_difference(left_pixel, right_pixel)
      # r = Color.r(left_pixel) - Color.r(right_pixel)
      lg = Color.g(left_pixel)
      rg = Color.g(right_pixel)
      # b = Color.b(left_pixel) - Color.b(right_pixel)

      (lg - rg).abs
    end

  end
end
