require 'wx/exceptions'

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
        m.time = "#{$1.to_i - 1} days".unit + "#{$2} hours" + "#{$3} minutes"
      end

      return m
    end

    def initialize
      @speci = false
      @station = 'KLRU'
      @time = '241517'
    end
  end
end
