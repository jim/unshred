require 'optparse'
require 'ostruct'

module Unshred
  class CLI
    def initialize(args)
      @options = OpenStruct.new

      @options.path = args.first
      OptionParser.new do |opts|
        opts.banner = "Usage: shred file [options]"

        @options.operation = 'shred'
        opts.on("-u", "--unshred", "Unshred file instead of shredding") do |u|
          @options.operation = 'unshred'
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
      image = Image.new(@options.path, @options)
      @options.operation == 'shred' ? image.shred! : image.unshred!
    end

  end
end
