require 'wx/exceptions'
require 'wx/groups'
require 'ruby-units'

module WX
  # METAR is short for a bunch of French words meaning "aviation routine
  # weather report". An example METAR code looks like:
  #     KLRU 261453Z AUTO 00000KT 3SM -RA OVC004 02/02 A3008 RMK AO2
  # This is intimidating, to say the least, to nonaviators. This class will
  # parse a METAR code and provide the information in its attribute readers.
  class METAR
    include Groups
    # The METAR station, as found in
    # stations.txt[http://weather.aero/metars/stations.txt]
    attr_accessor :station
    # A ::Time object. Note that METAR doesn't include year or month
    # information, so it is assumed that this time is intended to be within the
    # past month of ::Time.now 
    attr_accessor :time
    # A Groups::Wind object.
    attr_accessor :wind
    # A Groups::Visibility object.
    attr_accessor :visibility
    # An array of  Groups::RunwayVisualRange objects.
    attr_accessor :rvr
    # An array of Groups::PresentWeather objects.
    attr_accessor :weather
    # An array of Groups::Sky objects.
    attr_accessor :sky
    # A temperature Unit
    attr_accessor :temp
    # A temperature Unit
    attr_accessor :dewpoint
    # A pressure Unit, giving atmospheric pressure (by which one calibrates an
    # altimiter)
    attr_accessor :altimiter
    # Remarks.
    attr_accessor :rmk

    # Was this report entirely automated? (i.e. not checked by a human)
    def auto?
      @auto ? true : false
    end

    # Was this report corrected by a human?
    def cor?
      @cor ? true : false
    end

    # Was this a SPECI report? SPECI (special) reports are issued when weather
    # changes significantly between regular reports, which are generally every
    # hour.
    def speci?
      @speci ? true : false
    end

    # CLR means clear below 12,000 feet (because automated equipment can't tell
    # above 12,000 feet)
    def clr?
      @sky == ['CLR']
    end

    # SKC means sky clear. Only humans can report SKC
    def skc?
      @sky == ['SKC']
    end

    # Parse a raw METAR code and return a METAR object
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

    attr_accessor :speci, :auto, :cor
    def initialize #:nodoc:
      @speci = false
      @station = 'KLRU'
      @time = Time.now
    end
  end
end
