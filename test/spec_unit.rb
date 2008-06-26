require 'wx/groups'

context 'Unit' do
  setup do
    @m = '600 feet'.u
    @m.minus = true
    @p = '6000 feet'.u
    @p.plus = true
  end
  specify 'plus is greater_than' do
    @p.should be_greater_than
    @p.greater_than.should == true
  end
  specify 'minus is less_than' do
    @m.should be_less_than
    @m.less_than.should == true
  end
end
