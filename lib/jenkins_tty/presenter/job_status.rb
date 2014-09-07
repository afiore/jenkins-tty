module Presenter
  class JobStatus < Base
    def initialize(build_h)
      k              = 'lastBuiltRevision'
      last_built_rev = build_h['actions'].find { |h| h[k] }
      number         = build_h.fetch('number')
      @result        = build_h.fetch('result')
      @timestamp     = build_h.fetch('timestamp') / 1000
      @duration      = build_h.fetch('duration') / 1000
      @datetime      = Time.at(@timestamp)
      @minutes       = @duration / 60
      @seconds       = @duration % 60
      @num           = number.to_s

      if last_built_rev
        regex    = /(^refs\/remotes\/origin\/|^origin\/)/
        branch_h = last_built_rev[k].fetch('branch').first
        @sha1    = last_built_rev[k].fetch('SHA1')[0..9]
        @branch   = branch_h['name'].gsub(regex,'') if branch_h
      end
    end

    def render_tty
      [
        "- #{colorize(@result, "#{@num}")}:",
        @sha1,
        @branch.rjust(8),
        @datetime.strftime('%e %b %y - %R'),
        "(#{@minutes}m #{@seconds}s)".rjust(8)
      ].join(' ')
    end

    def render_no_tty
      puts [
        @number,
        @sha1,
        @branch,
        @result,
        @timestamp,
        @duration
      ].join(',')
    end
  end
end
