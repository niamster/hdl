require 'pp'
require 'pathname'
require 'fileutils'

class BuildClean < Target
  def initialize(env, project)
    super(env, project, 'clean')
    @requires = nil
    @provides = nil
  end

  def do(what)
    return unless @build_root.directory?
    puts "Removing #{@build_root}" unless @silent
    FileUtils.rmtree(@build_root)
  end
end

def init
  yield BuildClean
end
