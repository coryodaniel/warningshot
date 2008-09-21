describe WarningShot, 'VERSION' do
  it 'should combine MAJOR, MINOR and REVISION' do
    v = [WarningShot::MAJOR, WarningShot::MINOR, WarningShot::REVISION].join('.')
    WarningShot::VERSION.should == (v)
  end
  
end