require 'pp'
require 'pathname'
require 'fileutils'

class BuildClean < Target
  def initialize(options)
    super(options, 'clean')
    @requires = nil
    @provides = nil
  end

  def do(what)
    return unless @build_root.directory?
    puts "Removing #{@build_root}" unless @silent
    FileUtils.rmtree(@build_root)
  end
end

def build_init(options, targets)
  targets.push(BuildClean.new options)
end
