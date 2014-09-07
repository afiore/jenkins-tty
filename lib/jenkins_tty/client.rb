require 'net/http'
require 'uri'
require 'json'
require 'set'

module JenkinsTty
  class Client
    BASE_URL     = "http://localhost:9999"
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
      responses         = http_muti_get(request_paths.take(10)).values
      presenters        = responses.map { |resp| Presenter::JobStatus.new(resp) }

      presenters.each do |job_status_presenter|
        puts job_status_presenter.render
      end
    end

    def build_log(job_id, build_n)
      uri = URI("#{BASE_URL}/job/#{job_id}/#{build_n}/logText/progressiveText?start=0")
      puts Net::HTTP.get(uri)
    end

    private

    def http_muti_get(paths)
      threads = paths.to_set.map do |path|
        Thread.new do
          t   = Thread.current
          b_h = http_get(path)
          t[:response]     = b_h
          t[:request_path] = path
        end
      end
      threads.each(&:join)
      threads.reduce({}) {|acc, t| acc.merge(t[:path] => t[:response]) }
    end

    def http_get(path)
      res_body = Net::HTTP.get(URI(TEMPLATE_URL % path))
      JSON.parse(res_body)
    end
  end
end
