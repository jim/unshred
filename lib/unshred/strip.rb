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

    def pixel_difference(left_pixel, right_pixel)
      # r = Color.r(left_pixel) - Color.r(right_pixel)
      lg = Color.g(left_pixel) # / 255.0 * 10
      rg = Color.g(right_pixel)#  / 255.0 * 10
      # b = Color.b(left_pixel) - Color.b(right_pixel)

      # total = [r,g,b].inject {|sum,n| sum + n.abs }
      (lg - rg).abs
    end

  end

  class Strip
    include Calculations

    attr_accessor :columns
    attr_accessor :left
    attr_accessor :left_score
    attr_accessor :scores
    attr_accessor :index

    # Create a strip from an array of pixel column arrays
    def initialize(columns, index)
      @columns = columns
      @index = index
    end

    def score_strips(strips)
      @scores = strips.inject([]) do |array, strip|
        array << [match_left(strip), strip]
        array
      end
      scored = @scores.sort_by {|(value, method, strip)| value}
      @left_score, @left = scored.first
    end

    def score_for(strip_to_find)
      return 1000 if strip_to_find == self
      @scores.find {|(strip, score)| strip == strip_to_find}[1]
    end

    def match_left(strip)
      compute_match(@columns.first, strip.columns.last)
    end

    def match_right(strip)
      compute_match(@columns.last, strip.columns.first)
    end

    def to_s
      'Strip'
    end

  end
end
