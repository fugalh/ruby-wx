require 'wx/exceptions'
require 'ruby-units'

module WX
  class Wind
    # all with units
    attr_accessor :speed, :direction, :gust, :variable
    def initialize(speed, dir)
      @speed = speed
      @direction = dir
      @gust = nil
      @variable = nil
    end
    def calm?
      @speed == '0 knots'.unit
    end
    # a,b should be angles e.g. '240 degrees'.unit
    def variable=(d)
      if not Array === d or d.size != 2
        raise ArgumentError, "Expected array of two directions, got #{d.inspect}"
      end
      d.reverse! if d[1] < d[0]
      @variable = d
    end
  end

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

      # type
      case g = groups.shift
      when 'METAR'
        m.speci = false
      when 'SPECI'
        m.speci = true
      else
        raise ParseError, "Invalid Report Type '#{g}'"
      end

      # station
      if (g = groups.shift) =~ /^([a-zA-Z]{4})$/
        m.station = $1
      else
        raise ParseError, "Invalid Station Identifier '#{g}'"
      end

      # date and time
      if (g = groups.shift) =~ /^(\d\d)(\d\d)(\d\d)Z$/
        m.time = relative_time($1, $2, $3)
      else
        raise ParseError, "Invalid Date and Time of Report '#{g}'"
      end

      # modifier
      g = groups.shift
      if g == 'AUTO'
        m.auto = true
        g = groups.shift
      elsif g == 'COR'
        m.cor = true
        g = groups.shift
      end

      # wind
      if g =~ /^((\d\d\d)|VRB)(\d\d\d?)(G(\d\d\d?))?KT$/
        speed = "#{$3} knots".unit
        if $1 == 'VRB'
          if speed > '6 knots'.unit
            raise ParseError, "Invalid Wind '#{g}' (VRB but speed > 6 knots)"
          end
          direction = :variable
        else
          direction = "#{$1} degrees".unit
        end
        m.wind = Wind.new(speed, direction)

        m.wind.gust = "#{$5} knots".unit if $4

        if (g = groups.shift) =~ /^(\d\d\d)V(\d\d\d)$/
          m.wind.variable = ["#{$1} degrees".unit, "#{$2} degrees".unit]
          g = groups.shift
        end
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
