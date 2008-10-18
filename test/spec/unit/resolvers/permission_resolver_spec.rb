require "." / "lib" / "resolvers" / "permission_resolver"

describe WarningShot::PermissionResolver do
  before :all do
    WarningShot::PermissionResolver.logger = $logger
  end

  it 'should have tests registered' do
    WarningShot::PermissionResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::PermissionResolver.resolutions.empty?.should be(false)
  end
  
  it 'should be able to determine if the user permission is correct' do
    pending
  end
  
  it 'should be able to determine if the group permission is correct' do
    pending
  end
  
  it 'should be able to determine if the mode is correct' do
    pending
  end
  
  describe 'with healing enabled and with healing instructions' do
    it 'should be able to correct the user' do
      pending
    end
    
    it 'should be able to correct the group' do
      pending
    end
    
    it 'should be able to correct the mode' do
      pending
    end
  end
end