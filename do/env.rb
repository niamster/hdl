require 'optparse'
require 'pathname'
require 'ostruct'
require 'pp'
require 'find'

require_relative 'utils'

class OptionParser
  def usage
    puts help
    exit
  end
end

class Env
  attr_reader :options
  attr_reader :projects
  attr_reader :project
  attr_reader :target
  attr_reader :root
  attr_reader :build_root

  def find_projects
    Dir.new(@root).each do |e|
      next if e == '.' or e == '..' or e == 'do'
      e = @root.join(e)
      next unless FileTest.directory?(e)
      Find.find(e.to_s) do |path|
        Find.prune if File.basename(path)[0] == '.'
        if FileTest.file?(path) and path[-3..-1] == '.do'
          desc = @root.join(path)

          begin
            meta = eval(desc.read)
          rescue Exception => e
            Utils.die {
              puts "Project description #{desc} is not valid:"
              puts "    >> #{e.message}"
            }
          end
          if not meta[:name]
            Utils.die {puts "Project description #{desc} does not have a valid name"}
          end

          project = OpenStruct.new
          project.path = desc
          project.root = Pathname.new File.dirname(desc)
          project.meta = meta
          project.name = meta[:name].to_s

          @projects[meta[:name]] = project
        end
      end
    end
    
    if @projects.length == 0
      Utils.die {puts "No available projects within #{@root}"}
    end
  end
  private :find_projects

  def list_projects
    puts "List of available projects:"
    @projects.each do |n, p|
      path = p.path.to_s[@root.to_s.length+1..-1]
      puts "    #{n}(@#{path})"
    end
  end
  private :list_projects

  def get_project(name)
    @projects.each do |n, p|
      return p if n.to_s == name
    end
    Utils.die {puts "Project '#{name}' not found"}
  end
  private :get_project

  def resolve_files
    @projects.each do |n, p|
      p.files = Utils.expand(p.root, p.meta[:files])
      next unless p.meta[:include]
      p.meta[:include].each do |i|
        Utils.die {puts "Project #{i} is not defined(needed for project #{n}"} unless @projects[i]
        p.files += Utils.expand(@projects[i].root, @projects[i].meta[:files])
      end
    end
  end
  private :resolve_files

  def initialize(args)
    @options = OpenStruct.new

    @options.silent = false
    @options.force = false
    @root = Pathname.new(Dir.pwd)

    @projects = {}

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: do.rb [options] <project>[/<target>]"

      opts.on("-s", "--silent", "Be silent on actions") do |silent|
        @options.silent = silent
      end

      opts.on("-b", "--builddir=", "Path to build directory") do |builddir|
        @build_root = Pathname.new(builddir).realdirpath
      end

      opts.on("-f", "--force", "Force dependencies rebuild") do |force|
        @options.force = force
      end

      opts.on("-p", "--projects", "List available projects") do |projects|
        find_projects
        list_projects
        exit
      end

      opts.on("-r", "--root=", "Root of tree with projects") do |root|
        @root = Pathname.new(root).realdirpath
      end
    end
    parser.parse!(args)

    find_projects
    resolve_files

    parser.usage unless args.length == 1
    project, *target = args[0].split '/'

    @project = get_project project
    @target = (target.length > 0 and target[0] or nil)

    if @build_root == nil
      @build_root = Pathname.new(@project.root).join('.build')
    end
  end
end
