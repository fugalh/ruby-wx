require 'wx/METAR'
require 'ruby-units'

include WX
context 'METAR' do
  setup do
    @m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM CLR 01/M02 A3031 RMK AO2'
  end

  specify 'type - METAR/SPECI' do
    @m.should_not_be_speci
    METAR.parse('SPECI KLRU 241517Z AUTO 00000KT 10SM CLR 01/M02 A3031 RMK AO2').should_be_speci
    lambda { METAR.parse('foo') }.should_raise WX::ParseError, /type/i
  end

  specify 'station identifier - CCCC' do
    @m.station.should == 'KLRU'
    lambda { METAR.parse('METAR LRU') }.should_raise WX::ParseError, /station/i
    lambda { METAR.parse('METAR foo1') }.should_raise WX::ParseError, /station/i
  end

  specify 'date and time - YYGGggZ' do
    @m.time.mday.should == 24
    @m.time.hour.should == 15
    @m.time.min.should == 17
    (Time.now - @m.time).should < 31*24*60*60   # within the past month
    (Time.now - @m.time).should >= 0            # observation must be in the past
    lambda { METAR.parse('METAR KLRU foo') }.should_raise WX::ParseError, /time/i
  end

  specify 'report modifier - AUTO/COR' do
    @m.should_be_auto
    @m.should_not_be_cor
    m = METAR.parse 'METAR KLRU 241517Z COR 00000KT 10SM CLR 01/M02 A3031 RMK AO2'
    m.should_be_cor
    m.should_not_be_auto
    m = METAR.parse 'METAR KLRU 241517Z 00000KT 10SM CLR 01/M02 A3031 RMK AO2'
    m.should_not_be_auto
    m.should_not_be_cor
  end

  specify 'wind - ddff(f)Gfmfm(fm)KT_dndndnVdxdxdx' do
    @m.wind.speed.should == '0 knots'.u
    @m.wind.direction.should == '0 degrees'.u
    @m.wind.should_be_calm

    m = METAR.parse 'METAR KLRU 241517Z 27020G35KT'
    m.wind.direction.should == '270 degrees'.u
    m.wind.speed.should == '20 knots'.u
    m.wind.gust.should == '35 knots'.u

    m = METAR.parse 'METAR KLRU 241517Z 270120G135KT'
    m.wind.direction.should == '270 degrees'.u
    m.wind.speed.should == '120 knots'.u
    m.wind.gust.should == '135 knots'.u

    m = METAR.parse 'METAR KLRU 241517Z VRB03KT'
    m.wind.direction.should == :variable
    m.wind.speed.should == '3 knots'.u

    lambda {m = METAR.parse 'METAR KLRU 241517Z VRB07KT'}.should_raise ParseError, /wind/i

    m = METAR.parse 'METAR KLRU 241517Z 21010KT 180V240'
    m.wind.variable.should == ['180 degrees'.u, '240 degrees'.u]
  end

  specify 'visibility - VVVVVSM' do
    @m.visibility.should == '10 miles'.u
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 5SM'
    m.visibility.should == '5 miles'.u
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 1/2SM'
    m.visibility.should == '.5 miles'.u
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 1 7/8SM'
    m.visibility.should == '1.875 miles'.u
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 2 3/4SM'
    m.visibility.should == '2.75 miles'.u
  end

=begin
  specify 'runway visual range - RDRDR/VRVRVRVRFT or RDRDR/VNVNVNVNVVXVXVXVXFT' do
    @m.rvr.should_be_nil
  end

  specify "present weather - w'w'" do
    @m.weather.should_be_nil
  end

  specify 'sky condition - NsNsNshshshs or VVhshshs or SKC/CLR' do
    @m.sky.should_be_clr
  end

  specify "temperature and dew point - T'T'/T'dT'd" do
    @m.temp.should == '1 temp-C'.u
    @m.dewpoint.should == '-2 temp-C'.u
  end

  specify 'altimiter - APHPHPHPH' do
    @m.altimiter.should == '30.31 inHg'
  end

  specify 'remarks' do
    @m.remarks.should == @m.rmk
    @m.rmk.should == 'A02'
  end

  specify 'mandatory groups: station, and datetime' do
    @m.station.should_not_be_nil
    @m.datetime.should_not_be_nil
  end

  # TODO non-US units
=end
end
