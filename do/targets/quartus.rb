require 'pp'

class QuartusBuild < Target
#   QSF_TEMPLATE = "
# set_global_assignment -name FAMILY "#{family}"
# set_global_assignment -name DEVICE #{device}
# "
  def initialize(options)
    super(options, 'qbuild')

    @files = Utils.expand(@options.path, @options.meta[:files])
    @requires = @files

    @qsf = project_file(".qsf")
    @sof = project_file(".sof")
    @sdc = @options.path.join(@options.meta[:sdc]).realpath

    @provides = [@qsf, @sof]

    @top = @options.meta[:top]
    @family = @options.meta[:target][:family]
    @device = @options.meta[:target][:device]
  end

  def do(what)
    File.open(@qsf, "w+") do |qsf|
      qsf.puts("set_global_assignment -name FAMILY \"#{@family}\"")
      qsf.puts("set_global_assignment -name DEVICE #{@device}")
      qsf.puts("set_global_assignment -name TOP_LEVEL_ENTITY #{@top}")
      @files.each do |f|
        qsf.puts("set_global_assignment -name VERILOG_FILE #{f}")
      end
      if @options.meta[:pins]
        @options.meta[:pins].each do |entity, pin|
          if pin.kind_of? Array
            i = 0
            pin.each do |p|
              qsf.puts("set_location_assignment PIN_#{p} -to #{entity}[#{i}]")
              i += 1
            end
          else
            qsf.puts("set_location_assignment PIN_#{pin} -to #{entity}")
          end
        end
      end
      qsf.puts("set_global_assignment -name SDC_FILE #{@sdc}") if @sdc
    end

    Utils.run("quartus_sh",
        param=["--flow", "compile", @qsf],
        pwd: @build_root, silent: @silent)
  end
end

class QuartusBlast < Target
  def initialize(options)
    super(options, 'qblast')

    @sof = project_file(".sof")
    @requires = [@sof]

    @provides = nil
  end

  def do(what)
    Utils.run("quartus_pgm",
        param=["-c", "USB-Blaster", "-m", "JTAG", "-o", "P;#{@sof}"],
        pwd: @build_root, silent: @silent)
  end
end

def quartus_init(options, targets)
  targets.push(QuartusBuild.new options)
  targets.push(QuartusBlast.new options)
end