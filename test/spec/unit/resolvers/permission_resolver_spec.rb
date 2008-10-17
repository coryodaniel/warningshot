require File.join(%w(. lib resolvers permission_resolver))

describe WarningShot::PermissionResolver do

  it 'should have tests registered' do
    WarningShot::PermissionResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::PermissionResolver.resolutions.empty?.should be(false)
  end
     
  describe 'with healing enabled' do
    describe 'with heal instructions' do
      it 'should' do
        pending
      end
    end # End healing enabled, instructions provided
    
    describe 'without heal instructions' do
      it 'should' do
        pending
      end
    end # End healing enabled, instructions not provided
  end # End healing enabled
  
  describe 'with healing disabled' do
    describe 'with heal instructions' do
      it 'should' do
        pending
      end
    end #End healing disabled, instructions provided
    
    describe 'without heal instructions' do
      it 'should' do
        pending
      end
    end # End healing disabled, instructions not provided
  end # End healing disabled
end