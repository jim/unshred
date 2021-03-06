require 'chunky_png'

module Unshred
  module Calculations
    include ChunkyPNG

    # Calculate the average difference between the pixels in two columns
    def compute_match(lcol, rcol)
      differences = lcol.each_with_index.map do |lval, index|
        right_pixel = rcol[index]
        pixel_difference(lval, right_pixel)
      end

      differences.inject {|sum,n| sum + n} / lcol.size.to_f
    end

    # Calculate the difference by comparing the red channel data, as it
    # which typically contains the most contrast.
    def pixel_difference(left_pixel, right_pixel)
      lg = Color.r(left_pixel)
      rg = Color.r(right_pixel)
      (lg - rg).abs
    end

  end
end
