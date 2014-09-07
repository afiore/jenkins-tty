module Presenter
  class Status < Base
    def initialize(h)
      @color = h.fetch('color')
      @name  = h.fetch('name')
    end

    def render_tty
      "-#{colorize(@color, @name)}"
    end

    def render_no_tty
      @name
    end
  end
end
