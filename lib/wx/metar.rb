require 'wx/exceptions'
require 'wx/groups'
require 'ruby-units'
require 'stringio'

module WX
  # METAR is short for a bunch of French words meaning "aviation routine
  # weather report". An example METAR code looks like:
  #     KLRU 261453Z AUTO 00000KT 3SM -RA OVC004 02/02 A3008 RMK AO2
  # This is intimidating, to say the least, to nonaviators. This class will
  # parse a METAR code and provide the information in its attribute readers.
  class METAR
    include Groups
    # The raw METAR observation as passed to parse
    attr_accessor :raw
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
    alias :vis :visibility
    # An array of  Groups::RunwayVisualRange objects.
    attr_accessor :rvr
    alias :runway_visual_range :rvr
    # An array of Groups::PresentWeather objects.
    attr_accessor :weather
    alias :present_weather :weather
    alias :present_wx :weather
    alias :wx :weather
    # An array of Groups::Sky objects.
    attr_accessor :sky
    alias :clouds :sky
    alias :cloud_cover :sky
    # A temperature Unit
    attr_accessor :temp
    alias :temperature :temp
    def tempF
      @temp.to 'tempF'
    end
    # A temperature Unit
    attr_accessor :dewpoint
    alias :dew :dewpoint
    # A pressure Unit, giving atmospheric pressure (by which one calibrates an
    # altimiter)
    attr_accessor :altimiter
    alias :pressure :altimiter
    def pressure_mb
      @altimiter.to 'millibar'
    end
    # Remarks.
    attr_accessor :rmk
    alias :remarks :rmk

    # Was this report entirely automated? (i.e. not checked by a human)
    def auto?
      @auto ? true : false
    end
    alias :automated? :auto?

    # Was this report corrected by a human?
    def cor?
      @cor ? true : false
    end
    alias :corrected? :cor?

    # Was this a SPECI report? SPECI (special) reports are issued when weather
    # changes significantly between regular reports, which are generally every
    # hour.
    def speci?
      @speci ? true : false
    end
    alias :special? :speci?

    # CLR means clear below 12,000 feet (because automated equipment can't tell
    # above 12,000 feet)
    def clr?
      @sky == ['CLR']
    end
    alias :auto_clear? :clr?

    # SKC means sky clear. Only humans can report SKC
    def skc?
      @sky == ['SKC']
    end
    alias :clear? :skc?

    # Parse a raw METAR code and return a METAR object
    def self.parse(raw)
      m = METAR.new
      m.raw = raw
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
        m.temp = "#{t} tempC".unit

        if $3
          d = $5.to_i
          d = -d if $4 == 'M'
          m.dewpoint = "#{d} tempC".unit
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

    # The output of this aims to be similar to 
    # http://adds.aviationweather.gov/tafs/index.php?station_ids=klru&std_trans=translated
    # But just plain text, not HTML tables or anything.
    def to_s
      s = StringIO.new
      deg = "\xc2\xb0" # UTF-8 degree symbol
      s.print <<EOF
#{raw}
Conditions at:        #{station}
Temperature:          #{temp.to('tempC').abs}#{deg}C (#{tempF.abs}#{deg}F)
Dewpoint:             #{dewpoint.to('tempC').abs}#{deg}C (#{dewpoint.to('tempF').abs}#{deg}F) [RH #{rh}%]
Pressure (altimiter): #{altimiter.to('inHg')} (#{altimiter.to('millibar')})
Winds:                #{wind.speed} from #{wind.dir}
Visibility:           #{visibility}
EOF
=begin TODO
Ceiling: 
Clouds:
Weather:
=end
      s.string
    end

    # Relative Humidity
    # See http://www.faqs.org/faqs/meteorology/temp-dewpoint/
    def relative_humidity
      es0 = 6.11 # hPa
      t0 = 273.15 # kelvin
      td = self.dewpoint.to('tempK').abs
      t = self.temp.to('tempK').abs
      lv = 2500000 # joules/kg
      rv = 461.5 # joules*kelvin/kg
      e  = es0 * Math::exp(lv/rv * (1.0/t0 - 1.0/td))
      es = es0 * Math::exp(lv/rv * (1.0/t0 - 1.0/t))
      rh = 100 * e/es
    end
    alias :rh :relative_humidity
  end
end
