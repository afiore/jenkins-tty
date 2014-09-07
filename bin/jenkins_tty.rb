#! /usr/bin/env ruby
#
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'presenter'))


require 'jenkins_tty/presenter/base'
require 'jenkins_tty/presenter/status'
require 'jenkins_tty/presenter/job_status'
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

  opts.on("-b", "Perform a build") do
    options[:cmd] = :build
  end

end.parse!

cmd   = options[:cmd]
build = options[:build]

if job
  case cmd
  when :print_build_log
    client.build_log(job, build)
  when :build
    client.build(job)
  else
    client.job_status(job)
  end
else
  client.status
end
