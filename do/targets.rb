require 'pp'
require 'pathname'
require 'fileutils'

require_relative 'utils'

class Target
  attr_reader :name
  attr_reader :provides
  attr_reader :requires
  attr_reader :implicit

  def initialize(options, name)
    @name = name
    @options = options
    @requires = []
    @provides = []
    @build_root = @options.build_root
    @silent = @options.silent
  end

  def project_file(ext)
    @options.build_root.join(@options.project+ext)
  end
end

class Targets
  attr_reader :targets

  def load(path)
    Utils.require_dir(path) do |file|
      name = file.chomp('.rb')
      send("#{name}_init", @options, @targets)
    end
  end
  private :load

  def print(prefix='')
    @targets.each {|t| puts "#{prefix}#{t.name}" if not t.implicit}
  end

  def initialize(options)
    @options = options

    @targets = Array.new

    load(@options.do_root.join('do', 'targets'))
    load(@options.path.join('targets'))

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

  def dirs(path)
    dir, base = path.split
    if not dir.directory?
      puts "Creating #{dir}" unless @options.silent
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
      next if r.exist? and not @options.force
      dirs(r)
      @targets.each do |t|
        next if t == target
        next unless t.provides
        next unless t.provides.include?(r)
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
