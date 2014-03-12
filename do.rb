#!/usr/bin/env ruby

require 'pp'

require_relative 'do/env'
require_relative 'do/targets'

env = Env.new(ARGV)

targets = Targets.new(env)

if not env.target
  targets.print
  exit
end

target = targets.find env.target

if not target
  puts "Target #{env.target} not found."
  puts "Available targets:"
  targets.print(" "*4)
  exit
end

targets.resolve(target)
target.do(:all)
