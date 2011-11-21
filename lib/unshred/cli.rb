require 'optparse'
require 'ostruct'

module Unshred
  class CLI
    def initialize(args)
      @options = OpenStruct.new

      @options.path = args.first
      OptionParser.new do |opts|
        opts.banner = "Usage: shred file [options]"

        @options.operation = 'unshred'
        opts.on("-s", "--shred", "Shred file instead of unshredding") do |u|
          @options.operation = 'shred'
        end

        opts.on('-o', '--output [OUTPUT_PATH]', 'Path to write output to') do |o|
          @options.output_path = o
        end

        opts.on('-w', '--width', 'Width of shreds when shredding') do |w|
          @options.width = w
        end

        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          @options.verbose = v
        end
      end.parse!
    end

    def run
      image = Image.new(@options)
      @options.operation == 'shred' ? image.shred! : image.unshred!
    end

  end
end
