#! /usr/bin/env ruby
#
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'jenkins_tty/client'
require 'optparse'

client = JenkinsTty::Client.new
job    = ARGV[0]

if job
  client.job_status(job)
else
  client.status
end
