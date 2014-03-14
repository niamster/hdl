require 'pp'
require 'pathname'
require 'fileutils'

require_relative 'utils'

class Target
  attr_reader :name
  attr_reader :project
  attr_reader :provides
  attr_reader :requires
  attr_reader :implicit
  attr_reader :files

  def initialize(env, project, name)
    @env = env
    @project = project
    @name = name
    @requires = []
    @provides = []
    @build_root = @env.build_root
    @silent = @env.options.silent
  end

  def project_file(ext)
    @build_root.join(@project.name.to_s+ext)
  end
end

class Targets
  attr_reader :targets

  def initialize(env)
    @env = env
    @targets = Array.new

    load(@env.root.join('do', 'targets'))

    products = {}
    @targets.each do |t|
      next unless t.provides
      t.provides.each do |p|
        if products[p]
          puts "Multiple targets provide same entity #{p}:"
          puts "    #{products[p].name}, #{t.name}"
          exit 1
        end
        products[p] = t
      end
    end
  end

  def load(path)
    Utils.require_dir(path) do |file|
      send("init") do |t|
        @env.projects.each do |n, p|
          begin
            @targets.push(t.new(@env, p))
          rescue Exception => e
            if not @env.options.silent
              # puts e.message
              # puts e.backtrace
            end
          end
        end
      end
    end
  end
  private :load

  def print(prefix='')
    @targets.each do |t|
      next if t.implicit
      next unless @env.project == t.project
      puts "#{prefix}#{t.name}"
    end
  end

  def find(target)
    @targets.each do |t|
      if t.name == target and t.project == @env.project
        return t
      end
    end
    return nil
  end

  def dirs(path)
    dir, base = path.split
    if not dir.directory?
      puts "Creating #{dir}" unless @env.options.silent
      FileUtils.makedirs(dir)
    end
  end

  def resolve(target)
    if target.provides
      target.provides.each {|p| dirs(p)}
    end

    requires = target.requires
    return unless requires

    requires.each do |r|
      dirs(r)
      @targets.each do |t|
        next if t == target
        next unless t.provides
        next unless t.provides.include?(r)
        if r.exist? and not @env.options.force and t.files
          mtime = File.new(r).mtime
          tainted = false
          t.files.each do |f|
            if File.new(f).mtime > mtime
              tainted = true
              break
            end
          end
          next unless tainted
        end
        resolve(t)
        t.do(r)
        break
      end
      if not r.exist?
        puts "Requirement #{r} of target #{target.name} can't be satisfied"
        exit 1
      end
    end
  end
end
