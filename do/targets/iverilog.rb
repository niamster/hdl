require 'pp'
require 'pathname'

class IverilogSim < Target
  def initialize(options)
    super(options, 'isim')

    @files = Utils.expand(@options.path, @options.meta[:files])
    @requires = @files

    @vvp = project_file(".vvp")
    @vcd = project_file(".vcd")
    @provides = [@vvp, @vcd]
  end

  def do(what)
    Utils.run("iverilog",
        param=['-o', @vvp] + @files,
        pwd: @build_root, silent: @silent)
    Utils.run("vvp",
        param=[@vvp],
        pwd: @build_root, silent: @silent)
  end
end

def iverilog_init(options, targets)
  targets.push(IverilogSim.new options)
end
