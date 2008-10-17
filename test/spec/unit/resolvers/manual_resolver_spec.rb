require File.join(%w(. lib resolvers manual_resolver))

describe WarningShot::ManualResolver do

  it 'should have tests registered' do
    WarningShot::ManualResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::ManualResolver.resolutions.empty?.should be(true)
  end

  #Does this need any further test?
end