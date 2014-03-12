require 'pp'

class QuartusBuild < Target
  def initialize(env, project)
    super(env, project, 'qbuild')

    @files = Utils.expand(@project.root, @project.meta[:files])
    @requires = @files

    @qsf = project_file(".qsf")
    @sof = project_file(".sof")
    @sdc = @project.root.join(@project.meta[:sdc]).realpath

    @provides = [@qsf, @sof]

    @top = @project.meta[:top]
    @family = @project.meta[:target][:family]
    @device = @project.meta[:target][:device]
  end

  def do_pin(file, pin, entity)
    if pin.kind_of? String
      file.puts("set_location_assignment PIN_#{pin} -to #{entity}")
      return
    end
    file.puts("set_location_assignment PIN_#{pin[:pad]} -to #{entity}")
    file.puts("set_instance_assignment -name IO_STANDARD \"#{pin[:voltage]}\" -to #{entity}")
    if pin[:current]
      if pin[:current] == :max
        current = "MAXIMUM CURRENT"
      else
        current = pin[:current]
      end
      file.puts("set_instance_assignment -name CURRENT_STRENGTH_NEW \"#{current}\" -to #{entity}")
    end
  end
  private :do_pin

  def do(what)
    File.open(@qsf, "w+") do |qsf|
      qsf.puts("set_global_assignment -name FAMILY \"#{@family}\"")
      qsf.puts("set_global_assignment -name DEVICE #{@device}")
      qsf.puts("set_global_assignment -name TOP_LEVEL_ENTITY #{@top}")
      @files.each do |f|
        qsf.puts("set_global_assignment -name VERILOG_FILE #{f}")
      end
      if @project.meta[:pins]
        @project.meta[:pins].each do |entity, pin|
          if pin.kind_of? Array
            i = 0
            pin.each do |p|
              do_pin(qsf, p, "#{entity}[#{i}]")
              i += 1
            end
          else
            do_pin(qsf, pin, entity)
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
  def initialize(env, project)
    super(env, project, 'qblast')

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

def init
  yield QuartusBuild
  yield QuartusBlast
end
