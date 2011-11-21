require 'logger'
require 'chunky_png'

root = File.dirname(__FILE__)
$LOAD_PATH << root unless $LOAD_PATH.include?(root)

require 'unshred/strip'
require 'unshred/image'
require 'unshred/cli'
require 'unshred/calculations'

module Unshred
  class << self
    attr_accessor :logger
  end
  self.logger = Logger.new($stdout)
  self.logger.formatter = proc do |severity, datetime, progname, msg|
    "#{msg}\n"
  end
end
