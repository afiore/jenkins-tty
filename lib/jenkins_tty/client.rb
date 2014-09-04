require 'net/http'
require 'uri'
require 'json'

require 'pp'

module JenkinsTty
  class Client
    TEMPLATE_URL = "http://localhost:8080%s/api/json"

    def status
      h = req('/')
      h.fetch('jobs').each do |j|
        if $stdout.tty?
          color  = j.fetch('color')
          print "- "
          puts colorize(color, j.fetch('name'))
        else
          puts j.fetch('name')
        end
      end
    end

    def job_status(job_id)
      h       = req("/job/#{job_id}")
      threads = h.fetch('builds').take(10).map do |b|
        Thread.new do
          build_number = b.fetch('number')
          b_h = req("/job/#{job_id}/#{build_number}")
          Thread.current[:build] = b_h
        end
      end
      threads.each(&:join)

      threads.each do |t|
        build          = t[:build]
        k              = 'lastBuiltRevision'
        last_built_rev = build['actions'].find { |h| h[k] }
        result         = build.fetch('result')
        number         = build.fetch('number')
        timestamp      = build.fetch('timestamp') / 1000
        duration       = build.fetch('duration') / 1000
        datetime       = Time.at(timestamp)
        minutes        = duration / 60
        seconds        = duration % 60
        num            = number.to_s.rjust(3)

        if last_built_rev
          sha1     = last_built_rev[k].fetch('SHA1')[0..9]
          branch_h = last_built_rev[k].fetch('branch').first
          branch   = branch_h['name'].gsub(/^refs\/remotes\/origin\//,'') if branch_h
        end

        if $stdout.tty?
          puts "- #{colorize(result, "#{num}")}: #{sha1} #{branch}  #{datetime.strftime('%e %b %y - %R')} (#{minutes}m #{seconds}s)"
        else
          puts [number, sha1, branch, result, timestamp, duration].join(',')
        end
      end
    end

    private

    def colorize(color, s)
      code = case color
             when 'green', 'blue', 'SUCCESS'
               "0;32"
             when 'red', 'FAILURE'
               "0;31"
             when 'green_anime', 'red_anime'
               "1;33"
             when 'grey', 'gray'
               "0;37"
             else
               "1;37"
             end

      "\e[0#{code}m#{s}\e[00m"
    end

    def req(path)
      res_body = Net::HTTP.get(URI(TEMPLATE_URL % path))
      JSON.parse(res_body)
    end
  end
end
