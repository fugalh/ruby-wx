require 'wx/METAR'
require 'rubygems'
require 'ruby-units'

include WX
context 'METAR' do
  setup do
    @m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM CLR 01/M02 A3031 RMK AO2'
  end

  specify 'type - METAR/SPECI' do
    @m.should_not_be_speci
    METAR.parse('SPECI KLRU 241517Z AUTO 00000KT 10SM CLR 01/M02 A3031 RMK AO2').should_be_speci
    lambda { METAR.parse('foo') }.should_raise WX::ParseError
  end

  specify 'station identifier - CCCC' do
    @m.station.should == 'KLRU'
  end

  specify 'date and time - YYGGggZ' do
    @m.date.should == 24
    @m.time.should == 1517 # FIXME
  end

  specify 'report modifier - AUTO/COR' do
    @m.should_be_auto
    m.should_not_be_cor
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
    # TODO gusty, over 100 kts, variable, light and variable, etc.
  end

  specify 'visibility - VVVVVSM' do
    @m.visibility.should == '10 miles'.u
    # TODO other units
  end

  specify 'runway visual range - RDRDR/VRVRVRVRFT or RDRDR/VNVNVNVNVVXVXVXVXFT' do
    @m.rvr.should_be_nil
    # TODO
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
end
