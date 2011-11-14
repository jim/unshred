module Unshred
  class CLI
    def initialize(args)
      image = Image.new(args.first)
      image.unshred!
    end
  end
end
