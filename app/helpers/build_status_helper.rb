module BuildStatusHelper

STATUS_NAMES = {
  "succeeded" => { name: "Success",   class: "text-success", icon: "bi bi-check-circle-fill"  },
  "failed"    => { name: "Failed",    class: "text-danger",  icon: "bi bi-exclamation-triangle-fill" },
  "updating"  => { name: "Running",   class: "text-info",    icon: "bi bi-cloud-download-fill" },
  "building"  => { name: "Building",  class: "text-info",    icon: "bi bi-funnel-fill" },
  "uploading" => { name: "Uploading", class: "text-info",    icon: "bi bi-cloud-upload-fill" },
}

STATUS_NAMES.default = { name: "Unknown", class: "text-danger" }


def status_name(status)
  STATUS_NAMES[status][:name]
end

def status_class(status)
  STATUS_NAMES[status][:class]
end

def status_icon(status)
  STATUS_NAMES[status][:icon]
end

E = Struct.new(:name, :label_color, :number_color)
WARN_BG  = "rgb(170, 109, 14)"
WARN_FG  = "rgb(243, 200, 118)"
ERROR_BG = "rgb(161, 22, 8)"
ERROR_FG = "rgb(255, 186, 160)"
INFO_BG  = "rgb(18, 90, 138)"
INFO_FG  = "rgb(152, 152, 255)"

ERROR_TYPES = {
  "alt"  => E.new("Alt",      ERROR_BG, ERROR_FG),
  "fn"   => E.new("Footnote", WARN_BG,  WARN_FG),
  "lc"   => E.new("Wide",     WARN_BG,  WARN_FG),
  "mu"   => E.new("Markup",   ERROR_BG, ERROR_FG),
  "xr"   => E.new("XRef",     ERROR_BG, ERROR_FG),
  "rest" => E.new("Other",    INFO_BG,  INFO_FG),
}

def map_build_errors(counts, &block)
  counts = counts.dup

  ERROR_TYPES.each do |error, attrs|
    count = counts[error] || next
    counts.delete(error)
    yield(attrs.name, attrs, count)
  end
  counts.each do |error, count|
    next if error == "all"
    name = error
    format = ERROR_TYPES["rest"]
    yield(name, format, count)
  end
end

  # destitute terminal emulator....
  class State

    MAP_COLOR = {
      "30" => "black",
      "31" => "red",
      "32" => "green",
      "33" => "yellow",
      "34" => "blue",
      "35" => "magenta",
      "36" => "cyan",
      "37" => "white",
      "39" => "inherit"
    }

    def initialize()
      @fg = nil
      @bold = false
    end

    def reset
      result = []
      if @fg
        result << "</span>"
        @fg = nil
      end
      if @bold
        result << "</span>"
        @bold = false
      end
      result.join
    end

    def fg(color)
      return "" if @fg == color
      result = []
      if @fg
        result << "</span>"
      end
      @fg = color
      result << "<span style=\"color: #{MAP_COLOR[color]}\">"
      result.join
    end

    def bold
      if !@bold
        @bold = true
        %{<span style="font-weight: 800">}
      else
        ""
      end
    end
  end

  def map_one_line(state, line)

    result = line.split("\033[").reduce([]) do |result, part|
      case part

      when /^(\d+(;\d+)*)m(.*)/
        rest = $3
        attrs = $1.split(";")
        attrs.each do |attr|

          case attr
          when "0"
            result << state.reset
          when "1"
            result << state.bold
          else
            result << state.fg(attr)
          end
        end

        result << CGI::escapeHTML(rest)

      else
        result << CGI::escapeHTML(part)
      end
    end
    result << state.reset
    result.join
  end

  def decode_ansii_sequences(text)
    state = State.new

    text.split("\n").map do |line|
      map_one_line(state, line)
    end
      .join("\n").html_safe
  end
end

