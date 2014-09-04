#! /usr/bin/env ruby
#
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'jenkins_tty/client'
require 'optparse'

client  = JenkinsTty::Client.new
job     = ARGV[0]
options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [job-name] [-l]"
  opts.on("-l n", OptionParser::DecimalNumeric, "print build log") do |n|
    options[:build] = n
    options[:cmd]   = :print_build_log
  end
end.parse!

cmd   = options[:cmd]
build = options[:build]

if job
  case cmd
  when :print_build_log
    client.build_log(job, build)
  else
    client.job_status(job)
  end
else
  client.status
end
