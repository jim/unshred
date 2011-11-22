require 'chunky_png'

require 'unshred/calculations'

module Unshred

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

    # Get the score for the provided strip.
    def score_for(strip_to_find)
      return 1000 if strip_to_find == self
      @scores.find {|(strip, score)| strip == strip_to_find}[1]
    end

    def match_left(strip)
      compute_match(@columns.first, strip.columns.last)
    end

    def to_s
      'Strip'
    end

  end
end
