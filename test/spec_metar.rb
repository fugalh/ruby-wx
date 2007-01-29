require 'wx/metar'
require 'ruby-units'

include WX

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
context 'Date and Time' do
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
  (1..31).each do |d|
    t = sprintf('%02d',d)+'0000Z'
    month = 31*24*60*60
    specify "#{t} within the past month" do
      m = METAR.parse("KLRU #{t}")
      (Time.now.utc - m.time).should >= 0
      (Time.now.utc - m.time).should <= month
    end
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
    m.rvr.first.range.should  == ['600 feet'.u,'1000 ft'.u]
    m.rvr.first.should_be_variable
  end
  specify 'minus' do
    m = METAR.parse('KLRU 251733Z R12L/M0600FT')
    m.rvr.first.range.should == '600 feet'.u
    m.rvr.first.range.should_be_minus
    m = METAR.parse('KLRU 251733Z R12L/M0600V0800FT')
    m.rvr.first.range.should == ['600 ft'.u , '800 feet'.u]
    m.rvr.first.range.first.should_be_minus
    m.rvr.first.should_be_variable
  end
  specify 'plus' do
    m = METAR.parse('KLRU 251733Z R12L/P6000FT')
    m.rvr.first.range.should == '6000 feet'.u
    m.rvr.first.range.should_be_plus
    m = METAR.parse('KLRU 251733Z R12L/2000VP6000FT')
    m.rvr.first.range.should == ['2000 ft'.u , '6000 feet'.u]
    m.rvr.first.range.last.should_be_plus
    m.rvr.first.should_be_variable
  end
end
context 'Present Weather' do
  specify 'heavy rain showers' do
    m = METAR.parse('KLRU 260352Z +SHRA')
    m.weather.first.intensity.should == :heavy
    m.weather.first.descriptor.should == 'SH'
    m.weather.first.phenomena.should == ['RA']
  end
  specify 'moderate' do
    m = METAR.parse('KLRU 260352Z SHRA')
    m.weather.first.intensity.should == :moderate
  end
  specify 'thunderstorm in vicinity' do
    m = METAR.parse('KLRU 260352Z VCTS')
    m.weather.first.intensity.should == :vicinity
    m.weather.first.descriptor.should == 'TS'
  end
  specify 'tornado' do
    m = METAR.parse('KLRU 260352Z +FC')
    m.weather.first.intensity.should == :heavy
    m.weather.first.phenomena.should == ['FC']
  end
  specify 'three types of precipitation' do
    m = METAR.parse('KLRU 260352Z -SHSNRAGS')
    m.weather.first.intensity.should == :light
    m.weather.first.descriptor.should == 'SH'
    m.weather.first.phenomena.should == ['SN','RA','GS']
  end
  specify 'multiple pw groups' do
    m = METAR.parse('KLRU 260352Z -SHRA VCFG')
    m.weather.size.should == 2
    m.weather.first.intensity.should == :light
    m.weather.last.intensity.should == :vicinity
  end
end
context 'Sky Condition' do
  specify 'clear' do
    m = METAR.parse('KLRU 260352Z SKC')
    m.sky.first.should_be_skc
    m = METAR.parse('KLRU 260352Z CLR')
    m.sky.first.should_be_clr
  end
  specify 'scattered at 3000 feet' do
    m = METAR.parse('KLRU 260352Z SCT030')
    m.sky.first.cover.should == 'SCT'
    m.sky.first.height.should == '3000 feet'.unit
  end
  specify 'vertical visibility 500 feet' do
    m = METAR.parse('KLRU 260352Z VV005')
    m.sky.first.should_be_vv
    m.sky.first.height.should == '500 feet'.unit
  end
  specify 'cumulonimbus and towering cumulus' do
    m = METAR.parse('KLRU 260352Z FEW050CB')
    m.sky.first.cover.should == 'FEW'
    m.sky.first.height.should == '5000 feet'.unit
    m.sky.first.should_be_cb
    m = METAR.parse('KLRU 260352Z FEW050TCU')
    m.sky.first.should_be_tcu
  end
  specify 'BKN///' do
    m = METAR.parse('KLRU 260352Z BKN///')
    m.sky.first.cover.should == 'BKN'
    m.sky.first.height.should_be_nil
  end
  specify 'multiple' do
    m = METAR.parse('KLRU 260533Z AUTO 12013G19KT 10SM SCT026 SCT032 OVC039 07/02 A3020 RMK AO2')
    m.sky.size.should == 3
  end
end
context 'Temperature' do
  setup do
    @m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM CLR 01/M02 A3031 RMK AO2'
  end

  specify "01/M02" do
    @m.temp.should == '1 tempC'.u
    @m.dewpoint.should == '-2 tempC'.u
  end
  specify "M01/M02" do
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM CLR M01/M02 A3031 RMK AO2'
    m.temp.should == '-1 tempC'.u
    m.dewpoint.should == '-2 tempC'.u
  end
  specify 'no dewpoint' do
    m = METAR.parse 'METAR KLRU 241517Z 02/'
    m.dewpoint.should_be_nil
  end
end
context 'Altimiter' do
  setup do
    @m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM CLR 01/M02 A3031 RMK AO2'
  end

  specify 'A3031' do
    @m.altimiter.should == '30.31 inHg'
  end
end
context 'Remarks' do
  specify 'AO2' do
    m = METAR.parse 'METAR KLRU 241517Z AUTO 00000KT 10SM CLR 01/M02 A3031 RMK AO2'
    m.rmk.should == 'AO2'
  end
end

context 'convenience methods' do
  specify 'wind radians' do
    w = Groups::Wind.new '18005KT'
    w.radians.should == '180 deg'.u
    w.radians.to_s.should =~ /rad/i
  end
  specify 'wind mph' do
    w = Groups::Wind.new '18005KT'
    w.mph.should == '5 knots'.u
    w.mph.to_s.should =~ /mph/i
  end
  specify 'metar tempF' do
    m = METAR.parse('KLRU 241517Z 01/M02')
    m.tempF.should == '1 tempC'.unit
    m.tempF.to_s.should =~ /tempF/
  end
end

# TODO non-US units
# TODO parse rmk
