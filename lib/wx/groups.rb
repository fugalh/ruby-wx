require 'ruby-units'

# Extends ruby-unit's Unit class
class Unit
  attr_accessor :minus 
  attr_accessor :plus
  # Was this value reported as "less than"?
  def minus?
    @minus
  end
  # Was this value reported as "greater than"?
  def plus?
    @plus
  end
end

module WX
  # METAR codes are subdivided into "groups". The classes in this module do the
  # heavy lifting of parsing, and provide the API to access the relevant
  # information
  module Groups
    class Time < ::Time
      # raw date/time group, e.g. 252018Z
      # creates a ::Time object within the past month
      def self.parse(raw)
        raise ArgumentError unless raw =~ /^(\d\d)(\d\d)(\d\d)Z$/
        t = ::Time.now.utc
        y = t.year
        m = t.month
        mday = $1.to_i
        hour = $2.to_i
        min  = $3.to_i
        
        if t.mday < mday
          m -= 1
        end
        if m < 1
          m = 12
          y -= 1
        end
        return ::Time.utc(y,m,mday,hour,min)
      end
    end

    class Wind
      # Angle Unit
      attr_reader :direction
      # Speed Unit
      attr_reader :speed
      # Speed Unit
      attr_reader :gust
      # If wind is strong and variable, this will be a two-element Array
      # containing the angle Unit limits of the range, e.g. 
      #     ['10 deg'.unit, '200 deg'.unit]
      attr_reader :variable 
      def initialize(raw)
        raise ArgumentError unless raw =~/(\d\d\d|VRB)(\d\d\d?)(G(\d\d\d?))?(KT|KMH|MPS)( (\d\d\d)V(\d\d\d))?/

        case $5 
        when 'KT'
          unit = 'knots'
        when 'KMH'
          unit = 'kph'
        when 'MPS'
          unit = 'm/s'
        end
        @speed = "#{$2} #{unit}".unit
        if $1 == 'VRB'
          @direction = 'VRB'
        else
          @direction = "#{$1} degrees".unit
        end

        @gust = "#{$4} knots".unit if $3

        if $6
          @variable = ["#{$7} deg".unit, "#{$8} deg".unit]
        end
      end
      # If wind is strong and variable or light and variable
      def variable?
        (@variable or @direction == 'VRB') ? true : false
      end
      def calm?
        @speed == '0 knots'.unit
      end
    end

    # How many statute miles of horizontal visibility. May be reported as less
    # than so many miles, in which case Unit#minus? returns true.
    class Visibility < Unit
      def initialize(raw)
        raise ArgumentError unless raw =~ /^(M?)(\d+ )?(\d+)(\/(\d+))?SM$/
        @minus = true if $1
        if $4
          d = $3.to_f / $5.to_f
        else
          d = $3.to_f
        end
        if $2
          d += $2.to_f
        end
        super("#{d} mi")
      end
    end

    # How far down a runway the lights can be seen
    class RunwayVisualRange
      # Which runway
      attr_reader :runway
      # How far. If variable, this is a two-element Array giving the limits.
      attr_reader :range
      def initialize(raw)
        raise ArgumentError unless raw =~ /^R(\d+[LCR]?)\/([PM]?)(\d+)(V([P]?)(\d+))?FT$/
        @runway = $1
        @range = ($3+' feet').unit
        @range.minus = true if $2 == 'M'
        @range.plus = true if $2 == 'P'
        if $4
          r1 = @range
          r2 = "#{$6} feet".unit
          r2.plus = true if $5 == 'P'
          @range = (r1..r2)
        end
      end
      # Is the visibility range variable?
      def variable?
        Range === @range
      end
    end
    # Weather phenomena in the area. At the moment this is a very thin layer
    # over the present weather group of METAR. Please see
    # FMH-1 Chapter
    # 12[http://www.nws.noaa.gov/oso/oso1/oso12/fmh1/fmh1ch12.htm#ch12link]
    # section 6.8 for more details.
    class PresentWeather
      # One of [:light, :moderate, :heavy]
      attr_reader :intensity
      # The descriptor. e.g. 'SH' means showers
      attr_reader :descriptor
      # The phenomena. An array of two-character codes, e.g. 'FC' for funnel
      # cloud or 'RA' for rain.
      attr_reader :phenomena
      def initialize(raw)
        r = /^([-+]|VC)?(MI|PR|BC|DR|BL|SH|TS|FZ)?((DZ|RA|SN|SG|IC|PE|GR|GS|UP)*|(BR|FG|FU|VA|DU|SA|HZ|PY)*|(PO|SQ|FC|SS|DS)*)$/
        raise ArgumentError unless raw =~ r

        case $1
        when '-'
          @intensity = :light
        when nil
          @intensity = :moderate
        when '+'
          @intensity = :heavy
        when 'VC'
          @intensity = :vicinity
        end

        @descriptor = $2

        @phenomena = []
        s = $3
        until s.empty?
          @phenomena.push(s.slice!(0..1))
        end
      end
      # Alias for intensity
      def proximity
        @intensity
      end
    end
    # Information about clouds or lack thereof
    class Sky
      # Cloud cover. A two-character code. (See FMH-1
      # 12.6.9[http://www.nws.noaa.gov/oso/oso1/oso12/fmh1/fmh1ch12.htm#ch12link])
      attr_reader :cover
      # Distance Unit to the base of the cover type. 
      attr_reader :height
      def initialize(raw)
        raise ArgumentError unless raw =~ /^(SKC|CLR)|(VV|FEW|SCT|BKN|OVC)(\d\d\d|\/\/\/)(CB|TCU)?$/

        if $1
          @clr = ($1 == 'CLR')
          @skc = ($1 == 'SKC')
        else
          @cover = $2
          @cb = ($4 == 'CB')
          @tcu = ($4 == 'TCU')
          @height = "#{$1}00 feet".unit if $3 =~ /(\d\d\d)/
        end
      end
      # Is the sky clear?
      def skc?
        @skc
      end
      # Is the sky reported clear by automated equipment (meaning it's clear up
      # to 12,000 feet at least)?
      def clr?
        @clr
      end
      # Are there cumulonimbus clouds? Only when reported by humans.
      def cb?
        @cb
      end
      # Are there towering cumulus clouds? Only when reported by humans.
      def tcu?
        @tcu
      end
      # Is this a vertical visibility restriction (meaning they can't tell
      # what's up there above this height)
      def vv?
        @cover == 'VV'
      end
    end
  end
end
