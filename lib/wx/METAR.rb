require 'wx/exceptions'
require 'ruby-units'

module WX
  class METAR
    attr_accessor :station, :time, :wind, :visibility, :sky, :temp, :dewpoint, :altimiter
    attr_writer :auto, :cor, :speci

    def auto?
      @auto ? true : false
    end

    def cor?
      @cor ? true : false
    end

    def speci?
      @speci ? true : false
    end

    def self.parse(raw)
      m = METAR.new
      groups = raw.split

      case g = groups.shift
      when 'METAR'
        m.speci = false
      when 'SPECI'
        m.speci = true
      else
        raise ParseError, "Invalid Report Type '#{g}'"
      end

      if (g = groups.shift) =~ /^([a-zA-Z]{4})$/
        m.station = $1
      else
        raise ParseError, "Invalid Station Identifier '#{g}'"
      end

      if (g = groups.shift) =~ /^(\d\d)(\d\d)(\d\d)Z$/
        m.time = relative_time($1, $2, $3)
      else
        raise ParseError, "Invalid Date and Time of Report '#{g}'"
      end

      return m
    end

    def initialize
      @speci = false
      @station = 'KLRU'
      @time = Time.now
    end

    def self.relative_time(mday, hour, min)
      t = Time.now
      y = t.year
      m = t.month
      mday = mday.to_i
      hour = hour.to_i
      min = min.to_i
      if t.mday > mday
        m -= 1
      end
      if m < 1
        m = 1
        y -= 1
      end
      return Time.utc(y, m, mday, hour, min)
    end

  end
end
