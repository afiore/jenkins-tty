module Presenter
  class Base
    def render
      if $stdout.tty?
        render_tty
      else
        render_no_tty
      end
    end

    private
    def render_tty
      raise NotImplementedError
    end

    def render_no_tty
      raise NotImplementedError
    end

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
  end
end
