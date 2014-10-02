require 'net/http'
require 'uri'
require 'json'
require 'set'

module JenkinsTty
  class Client
    BASE_URL     = "http://localhost:8080"
    TEMPLATE_URL = "#{BASE_URL}%s/api/json"

    def status
      h = http_get('/')
      h.fetch('jobs').each do |j|
        puts Presenter::Status.new(j).render
      end
    end

    def job_status(job_id)
      h                 = http_get("/job/#{job_id}")
      request_paths     = h.fetch('builds').map { |b| "/job/#{job_id}/#{b.fetch('number')}" }
      responses         = http_multi_get(request_paths.take(10)).values
      presenters        = responses.map { |resp| Presenter::JobStatus.new(resp) }

      presenters.each do |job_status_presenter|
        puts job_status_presenter.render
      end
    end

    def build(job_id, params)
      params_str = params.empty? ? '' : '?' + params.map { |p| "#{p}=#{v}" }.join('&')
      uri        = URI(BASE_URL + "/job/#{job_id}/buildWithParameters#{params_str}")
      resp       = Net::HTTP.post_form(uri, {})
      if resp.code == '201'
        puts "OK"
      else
        $stderr.puts("Something went wrong posting to #{uri}: #{resp.inspect}")
        exit 1
      end
    end

    def build_log(job_id, build_n = nil)
      build_n ||= latest_build_number(job_id)
      uri = URI("#{BASE_URL}/job/#{job_id}/#{build_n}/logText/progressiveText?start=0")
      resp =  Net::HTTP.get_response(uri)

      if resp.code == '200'
        puts resp.body
      else
        $stderr.puts "Cannot find a build log for #{job_id} build ##{build_n}"
        exit 1
      end
    end

    private

    def latest_build_number(job_id)
      h       = http_get("/job/#{job_id}")
      build_n = h.fetch('lastBuild', {})['number']
      $stderr.puts "No builds available yet for job #{job_id}" unless build_n
      build_n
    end

    def http_multi_get(paths)
      threads = paths.to_set.map do |path|
        Thread.new do
          t   = Thread.current
          b_h = http_get(path)
          t[:response]     = b_h
          t[:request_path] = path
        end
      end
      threads.each(&:join)
      threads.reduce({}) {|acc, t| acc.merge(t[:request_path] => t[:response]) }
    end

    def http_get(path)
      res_body = Net::HTTP.get(URI(TEMPLATE_URL % path))
      JSON.parse(res_body)
    end
  end
end
