require File.join(%w(. lib resolvers directory_resolver))

describe WarningShot::DirectoryResolver do

  it 'should have tests registered' do
    WarningShot::DirectoryResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::DirectoryResolver.resolutions.empty?.should be(false)
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