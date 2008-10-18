require "." / "lib" / "resolvers" / "manual_resolver"

describe WarningShot::ManualResolver do
  before :all do
    WarningShot::ManualResolver.logger = $logger
  end
  
  it 'should have tests registered' do
    WarningShot::ManualResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::ManualResolver.resolutions.empty?.should be(true)
  end

  #Does this need any further test?
end