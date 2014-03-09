require 'optparse'
require 'pathname'
require 'ostruct'
require 'pp'

class OptionParser
  def usage
    puts help
    exit
  end
end

class Env
  attr_reader :options

  def initialize(args)
    @options = OpenStruct.new

    @options.silent = false
    @options.force = false

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: do.rb [options] <project>/<target>"

      opts.on("-s", "--silent", "Be silent on actions") do |silent|
        @options.silent = silent
      end

      opts.on("-b", "--builddir=", "Path to build directory") do |builddir|
        @options.build_root = Pathname.new(builddir).realdirpath
      end

      opts.on("-f", "--force", "Force dependencies rebuild") do |force|
        @options.force = force
      end
    end
    parser.parse!(args)

    parser.usage unless args.length == 1

    command = Pathname.new(args[0])

    if command.directory?
      path = command.realdirpath
      target = nil
    else
      path, target = File.split(command)
      path = Pathname.new(path).realdirpath
    end

    if not path.directory? or path == Pathname.pwd
      puts "Not valid command: #{command}"
      puts
      parser.usage
    end

    root, project = File.split(path)

    @options.root = Pathname.new(root)
    @options.path = path
    @options.project = project
    @options.target = target

    if @options.build_root == nil
      @options.build_root = Pathname.new(@options.path).join('.build')
    end

    @options.do_root = Pathname.pwd
  end
end
