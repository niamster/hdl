require 'pp'
require 'pathname'

class IverilogSim < Target
  def initialize(env, project)
    super(env, project, 'isim')

    @files = @project.files
    @requires = @files

    @vvp = project_file(".vvp")
    @vcd = project_file(".vcd")
    @provides = [@vvp, @vcd]

    @sim = @project.meta[:sim]
  end

  def do(what)
    extra = []
    extra += ['-s', @sim] if @sim
    extra += ['-DIVERILOG']
    extra += ["-DVCD_PATH=\"#{@vcd}\""]
    Utils.run("iverilog",
        param=['-o', @vvp] + extra + @files,
        pwd: @build_root, silent: @silent)
    Utils.run("vvp",
        param=[@vvp],
        pwd: @build_root, silent: @silent)
  end
end

def init
  yield IverilogSim
end
