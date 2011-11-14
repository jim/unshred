require 'logger'
require 'chunky_png'

require_relative 'unshred/strip'
require_relative 'unshred/image'
require_relative 'unshred/cli.rb'

module Unshred
  class << self
    attr_accessor :logger
  end
  self.logger = Logger.new($stdout)
  self.logger.formatter = proc do |severity, datetime, progname, msg|
    "#{msg}\n"
  end
end
