require 'pp'
require 'pathname'

module Utils
  def self.require_dir(path)
    out = Array.new

    return out if not path.directory?

    Dir.new(path).each do |file|
      next if file == '.' or file == '..'
      require path.join(file)
      out.push(file)
      yield file if block_given?
    end
    out
  end

  def self.run(cmd, args, opts)
    cwd = Pathname.pwd if not cwd
    argv = Array.new
    args.each {|o| argv.push o.to_s}
    if opts[:silent]
      out = "/dev/null"
    else
      out = STDOUT
    end
    pid = Process.spawn(cmd, *argv,
                        chdir: opts[:pwd].to_s,
                        out: out, err: out)
    r = Process.wait2 pid
    if $?.exitstatus != 0
      puts "Command '#{cmd} #{args.join(' ')}' failed to execute"
      exit $?.exitstatus
    end
  end

  def self.expand(path, files)
    out = Array.new
    files.each do |file|
      Dir.glob(path.join(file)).each do |f|
        file = Pathname.new f
        out.push(file)
        yield file if block_given?
      end
    end
    out
  end

  def self.die
    yield if block_given?
    exit 1
  end
end
