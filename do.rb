#!/usr/bin/env ruby

require 'pp'

require_relative 'do/env'
require_relative 'do/targets'

options = Env.new(ARGV).options

meta = options.path.join(options.project+".rb")
if not meta.file?
  puts "File #{project} does not exist"
  exit
end
options.meta = eval(meta.read)

targets = Targets.new(options)

if not options.target
  targets.print
  exit
end

target = nil
targets.targets.each do |t|
  if t.name == options.target
    target = t
    break
  end
end

if not target
  puts "Target #{options.target} not found."
  puts "Available targets:"
  targets.print(" "*4)
  exit
end

targets.resolve(target)
target.do(:all)
