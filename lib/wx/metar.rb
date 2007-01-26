require 'wx/exceptions'
require 'wx/groups'
require 'ruby-units'

module WX
  class METAR
    include Groups
    attr_accessor :station, :time, :wind, :visibility, :rvr, :weather, :sky
    attr_accessor :temp, :dewpoint, :altimiter, :rmk
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

    def clr?
      @sky == ['CLR']
    end

    def skc?
      @sky == ['SKC']
    end

    def self.parse(raw)
      m = METAR.new
      groups = raw.split

      # type
      m.speci = false
      case g = groups.shift
      when 'METAR'
        g = groups.shift
      when 'SPECI'
        m.speci = true
        g = groups.shift
      end

      # station
      if g =~ /^([a-zA-Z0-9]{4})$/
        m.station = $1
        g = groups.shift
      else
        raise ParseError, "Invalid Station Identifier '#{g}'"
      end

      # date and time
      if g =~ /^(\d\d)(\d\d)(\d\d)Z$/
        m.time = Time.parse(g)
        g = groups.shift
      else
        raise ParseError, "Invalid Date and Time '#{g}'"
      end

      # modifier
      if g == 'AUTO'
        m.auto = true
        g = groups.shift
      elsif g == 'COR'
        m.cor = true
        g = groups.shift
      end

      # wind
      if g =~ /^((\d\d\d)|VRB)(\d\d\d?)(G(\d\d\d?))?(KT|KMH|MPS)$/
        if groups.first =~ /^(\d\d\d)V(\d\d\d)$/
          g = g + ' ' + groups.shift
        end
        m.wind = Wind.new(g)
        g = groups.shift
      end

      # visibility
      if g =~ /^\d+$/ and groups.first =~ /^M?\d+\/\d+SM$/
        m.visibility = Visibility.new(g+' '+groups.shift)
        g = groups.shift
      elsif g =~ /^M?\d+(\/\d+)?SM$/
        m.visibility = Visibility.new(g)
        g = groups.shift
      end

      # RVR
      m.rvr = []
      while g =~ /^R(\d+[LCR]?)\/([PM]?)(\d+)(V([PM]?)(\d+))?FT$/
        m.rvr.push RunwayVisualRange.new(g)
        g = groups.shift
      end

      # present weather
      m.weather = []
      while g =~ /^([-+]|VC)?(MI|PR|BC|DR|BL|SH|TS|FZ|DZ|RA|SN|SG|IC|PE|GR|GS|UP|BR|FG|FU|VA|DU|SA|HZ|PY|PO|SQ|FC|SS|DS)+$/
        m.weather.push PresentWeather.new(g)
        g = groups.shift
      end
      
      # sky condition
      m.sky = []
      while g =~ /^(SKC|CLR)|(VV|FEW|SCT|BKN|OVC)/
        m.sky.push Sky.new(g)
        g = groups.shift
      end

      # temperature and dew point
      if g =~ /^(M?)(\d\d)\/((M?)(\d\d))?$/
        t = $2.to_i
        t = -t if $1 == 'M'
        m.temp = "#{t} degC".unit

        if $3
          d = $5.to_i
          d = -d if $4 == 'M'
          m.dewpoint = "#{d} degC".unit
        end
        
        g = groups.shift
      end

      if g =~ /^A(\d\d\d\d)$/
        m.altimiter = "#{$1.to_f / 100} inHg".unit
        g = groups.shift
      end

      if g == 'RMK'
        m.rmk = groups.join(' ')
        groups = []
      end

      unless groups.empty?
        raise ParseError, "Leftovers after parsing: #{groups.join(' ')}" 
      end

      return m
    end

    def initialize
      @speci = false
      @station = 'KLRU'
      @time = Time.now
    end
  end
end
