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

  specify 'runway visual range - RDRDR/VRVRVRVRFT or RDRDR/VNVNVNVNVVXVXVXVXFT' do
    @m.rvr.should_be_nil

    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 1 7/8SM R01L/0900FT'
    m.rvr.first.runway.should == '01L'
    m.rvr.first.range.distance.should == '900 feet'.u

    # TODO rethink variable
    #m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 1 7/8SM R01L/0600V1000FT'

    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 1 7/8SM R01L/0900FT R30/0300FT'
    m.rvr.size.should == 2
    m.rvr.last.runway.should == '30'
    m.rvr.last.range.distance.should == '300 feet'.u

    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM R01L/P6000FT'
    m.rvr.first.range.should_be_plus

    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM R01L/M0600FT'
    m.rvr.first.range.should_be_minus
  end

  specify "present weather - w'w'" do
    @m.weather.should_be_nil
    m = METAR.parse 'METAR KLRU 241517Z -SHRA'
    m.weather.intensity.should == '-'
    m.weather.descriptor.should == 'SH'
    m.weather.phenomena.should == ['RA']
    m = METAR.parse 'METAR KLRU 241517Z BCFG'
    m.weather.intensity.should_be_nil
    m.weather.descriptor.should == 'BC'
    m.weather.phenomena.should == ['FG']
    m = METAR.parse 'METAR KLRU 241517Z +FC'
    m.weather.intensity.should == '+'
    m.weather.phenomena.should == ['FC']
    m = METAR.parse 'METAR KLRU 241517Z TSSNGS'
    m.weather.intensity.should_be_nil
    m.weather.descriptor.should == 'TS'
    m.weather.phenomena.should == ['SN','GS']
    m = METAR.parse 'METAR KLRU 241517Z VCTS'
    m.weather.proximity.should == 'VC'
    m.weather.descriptor.should == 'TS'
    m.weather.phenomena.should == []
  end

  specify 'sky condition - NsNsNshshshs or VVhshshs or SKC/CLR' do
    @m.sky.should == 'CLR'
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM SKC 01/M02 A3031 RMK AO2'
    m.sky.should == 'SKC'
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM FEW048 01/M02 A3031 RMK AO2'
    m.sky.should == ['FEW','48 deg'.u]
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM SCT030 01/M02 A3031 RMK AO2'
    m.sky.should == ['SCT','30 deg'.u]
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM BKN030 01/M02 A3031 RMK AO2'
    m.sky.should == ['BKN','30 deg'.u]
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM OVC030 01/M02 A3031 RMK AO2'
    m.sky.should == ['OVC','30 deg'.u]
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM VV005 01/M02 A3031 RMK AO2'
    m.sky.should == ['VV','500 feet'.u]
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM BKN030CB'
    m.sky.should == ['BKN','30 deg'.u, 'CB']
  end

  specify "temperature and dew point - T'T'/T'dT'd" do
    @m.temp.should == '1 degC'.u
    @m.dewpoint.should == '-2 degC'.u
  end

  specify 'altimiter - APHPHPHPH' do
    @m.altimiter.should == '30.31 inHg'
  end

  specify 'remarks' do
    @m.rmk.should == @m.rmk
    @m.rmk.should == 'AO2'
  end
end

# TODO rethink wind, rvr, present weather, sky condition
# TODO refactor spec
# TODO non-US units
# TODO parse rmk
