require 'ruby-units'

class Unit
  # less than
  attr_writer :minus 
  # greater than
  attr_writer :plus
  def minus?
    @minus
  end
  def plus?
    @plus
  end
end

module WX
  module Groups
    class Time < ::Time
      # raw date/time group, e.g. 252018Z
      # creates a ::Time object within the past month with the given values for
      # mday, hour, min
      def self.parse(raw)
        raise ArgumentError unless raw =~ /^(\d\d)(\d\d)(\d\d)Z$/
        t = ::Time.now
        y = t.year
        m = t.month
        mday = $1.to_i
        hour = $2.to_i
        min  = $3.to_i
        
        if t.mday > mday
          m -= 1
        end
        if m < 1
          m = 1
          y -= 1
        end
        return ::Time.utc(y,m,mday,hour,min)
      end
    end

    class Wind
      attr_reader :direction, :speed, :gust, :variable 
      def initialize(g)
        raise ArgumentError unless g =~/(\d\d\d|VRB)(\d\d\d?)(G(\d\d\d?))?(KT|KMH|MPS)( (\d\d\d)V(\d\d\d))?/

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
      def variable?
        (@variable or @direction == 'VRB') ? true : false
      end
      def calm?
        @speed == '0 knots'.unit
      end
    end

    class Visibility < Unit
      def initialize(g)
        raise ArgumentError unless g =~ /^(M?)(\d+ )?(\d+)(\/(\d+))?SM$/
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

    class RunwayVisualRange
      attr_reader :runway, :range
      def initialize(g)
        raise ArgumentError unless g =~ /^R(\d+[LCR]?)\/([PM]?)(\d+)(V([P]?)(\d+))?FT$/
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
      def variable?
        Range === @range
      end
    end
    class PresentWeather
      attr_reader :intensity, :descriptor, :phenomena
      def initialize(g)
        r = /^([-+]|VC)?(MI|PR|BC|DR|BL|SH|TS|FZ)?((DZ|RA|SN|SG|IC|PE|GR|GS|UP)*|(BR|FG|FU|VA|DU|SA|HZ|PY)*|(PO|SQ|FC|SS|DS)*)$/
        raise ArgumentError unless g =~ r

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
      def proximity
        @intensity
      end
    end
    class Sky
      attr_reader :cover, :height
      def initialize(g)
        raise ArgumentError unless g =~ /^(SKC|CLR)|(VV|FEW|SCT|BKN|OVC)(\d\d\d|\/\/\/)(CB|TCU)?$/

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
      def skc?
        @skc
      end
      def clr?
        @clr
      end
      def cb?
        @cb
      end
      def tcu?
        @tcu
      end
      def vv?
        @cover == 'VV'
      end
    end
  end
end
