require 'pp'

class Gtkwave < Target
  def initialize(options)
    super(options, 'gwave')
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

def gtkwave_init(options, targets)
  targets.push(Gtkwave.new options)
end
