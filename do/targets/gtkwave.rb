require 'pp'

class Gtkwave < Target
  def initialize(env, project)
    super(env, project, 'gwave')
    @vcd = project_file(".vcd")
    @requires = [@vcd]
    @provides = nil
  end
  
  def do(what)
    Utils.run("gtkwave",
        param=[@vcd],
        pwd: @build_root, silent: true)
  end
end

def init
  yield Gtkwave
end
