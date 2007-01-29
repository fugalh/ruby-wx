#!/usr/bin/ruby

require 'wx/metar'

m = WX::METAR.parse('KLRU 291433Z AUTO 00000KT 10SM CLR 02/02 A3015 RMK AO2')
puts m.to_s
puts 
m = WX::METAR.parse('KLRU 291553Z AUTO 00000KT 10SM CLR 06/04 A3016 RMK AO2')
puts m.to_s
