require 'wx/exceptions'

module WX
  class METAR
    attr_accessor :station, :datetime, :wind, :visibility, :sky, :temp, :dewpoint, :altimiter
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
      case groups.shift
      when 'METAR'
        m.speci = false
      when 'SPECI'
        m.speci = true
      else
        raise ParseError, 'Invalid Report Type'
      end

      return m
    end

    def initialize
      @speci = false
      @station = 'KLRU'
      @datetime = '241517'
    end
  end
end
