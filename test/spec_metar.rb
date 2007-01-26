require 'wx/metar'
require 'ruby-units'

include WX
context 'METAR' do
  setup do
    @m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM CLR 01/M02 A3031 RMK AO2'
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


# refactoring
context 'Type' do
  specify 'METAR' do
    m = METAR.parse 'METAR KLRU 250455Z'
    m.should_not_be_speci
  end
  specify 'SPECI' do
    m = METAR.parse 'SPECI KLRU 250455Z'
    m.should_be_speci
  end
  specify 'omitted' do
    m = METAR.parse 'KLRU 250455Z'
    m.should_not_be_speci
  end
end
context 'Station' do
  specify 'KLRU' do
    m = METAR.parse 'METAR KLRU 250455Z'
    m.station.should == 'KLRU'
  end
end
context '250455Z' do
  setup do
    @m = METAR.parse 'METAR KLRU 250455Z'
  end
  specify 'day 25' do
    @m.time.mday.should == 25
  end
  specify 'hour 4' do
    @m.time.hour.should == 4
  end
  specify 'minute 55' do
    @m.time.min.should == 55
  end
  specify 'utc' do
    @m.time.should_be_utc
  end
  specify 'in the past' do
    (Time.now - @m.time).should >= 0            # observation must be in the past
  end
  specify 'within the past month' do
    (Time.now - @m.time).should < 31*24*60*60   # within the past month
  end
end
context 'AUTO/COR' do
  specify 'AUTO' do
    m = METAR.parse('KLRU 250513Z AUTO 24005KT 10SM CLR 02/M01 A3038 RMK AO2')
    m.should_be_auto
    m.should_not_be_cor
  end
  specify 'COR' do
    m = METAR.parse('KLRU 250513Z COR 24005KT 10SM CLR 02/M01 A3038 RMK AO2')
    m.should_not_be_auto
    m.should_be_cor
  end
  specify 'omitted' do
    m = METAR.parse('KLRU 250513Z')
    m.should_not_be_auto
    m.should_not_be_cor
  end
end
context 'Wind' do
  specify 'calm' do
    m = METAR.parse('KLRU 250513Z 00000KT')
    m.wind.should_be_calm
  end
  specify 'ordinary' do
    m = METAR.parse('KLRU 250513Z 24005KT')
    m.wind.speed.should == '5 kts'.u
    m.wind.direction.should == '240 deg'.u
  end
  specify 'gust' do
    m = METAR.parse('KLRU 250513Z 27020G35KT')
    m.wind.speed.should == '20 kts'.u
    m.wind.direction.should == '270 deg'.u
    m.wind.gust.should == '35 kts'.u
  end
  specify 'three-digit wind' do
    m = METAR.parse('KLRU 250513Z 270120G135KT')
    m.wind.speed.should == '120 kts'.u
    m.wind.direction.should == '270 deg'.u
    m.wind.gust.should == '135 kts'.u
  end
  specify 'light and variable' do
    m = METAR.parse 'METAR KLRU 241517Z VRB02KT'
    m.wind.direction.should == 'VRB'
    m.wind.speed.should == '2 knots'.u
    m.wind.should_be_variable
  end
  specify 'strong and variable' do
    m = METAR.parse 'KLRU 241517Z 21010KT 100V240'
    m.wind.variable.should == ['100 deg'.u, '240 deg'.u]
    m.wind.should_be_variable
  end
  specify 'other units' do
    m = METAR.parse 'KLRU 250533Z 27007KMH'
    m.wind.speed.should == '7 kph'.u
    m = METAR.parse 'KLRU 250533Z 27002MPS'
    m.wind.speed.should == '2 m/s'.u
  end
end
context 'Visibility' do
  specify '10 miles' do
    METAR.parse('KLRU 251733Z AUTO 01005KT 10SM').visibility.should == '10 mi'.u
  end
  specify '5 miles' do
    METAR.parse('KLRU 251733Z 01005KT 5SM').visibility.should == '5 mi'.u
  end
  specify '1/2SM' do
    METAR.parse('KLRU 251733Z 01005KT 1/2SM').visibility.should == '.5 mi'.u
  end
  specify '1 7/8SM' do
    METAR.parse('KLRU 251733Z 01005KT 1 7/8SM').visibility.should == '1.875 miles'.u
  end
  specify '2 3/4SM' do
    METAR.parse('KLRU 251733Z 01005KT 2 3/4SM').visibility.should == '2.75 miles'.u
  end
  specify 'less than' do
    m = METAR.parse('KLRU 251733Z 01005KT M1/4SM')
    m.visibility.should == '.25 miles'.u
    m.visibility.should_be_minus
  end
end
context 'Runway Visual Range' do
  specify 'R12L/0800FT' do
    m = METAR.parse('KLRU 251733Z R12L/0800FT')
    m.rvr.first.runway.should  == '12L'
    m.rvr.first.range.should  == '800 feet'.u
  end
  specify 'R30/0600V1000FT' do
    m = METAR.parse('KLRU 251733Z R30/0600V1000FT')
    m.rvr.first.runway.should  == '30'
    m.rvr.first.range.should  == ('600 feet'.u .. '1000 ft'.u)
    m.rvr.first.should_be_variable
  end
  specify 'minus' do
    m = METAR.parse('KLRU 251733Z R12L/M0600FT')
    m.rvr.first.range.should == '600 feet'.u
    m.rvr.first.range.should_be_minus
    m = METAR.parse('KLRU 251733Z R12L/M0600V0800FT')
    m.rvr.first.range.should == ('600 ft'.u .. '800 feet'.u)
    m.rvr.first.range.first.should_be_minus
    m.rvr.first.should_be_variable
  end
  specify 'plus' do
    m = METAR.parse('KLRU 251733Z R12L/P6000FT')
    m.rvr.first.range.should == '6000 feet'.u
    m.rvr.first.range.should_be_plus
    m = METAR.parse('KLRU 251733Z R12L/2000VP6000FT')
    m.rvr.first.range.should == ('2000 ft'.u .. '6000 feet'.u)
    m.rvr.first.range.last.should_be_plus
    m.rvr.first.should_be_variable
  end
end
# etc.
