require File.join(%w(. lib resolvers directory_resolver))

describe WarningShot::DirectoryResolver do
  before :all do
    @@base_path = File.expand_path(File.join(%w(. test data resolvers directory)))
  end
  
  after :each do
    FileUtils.rm_rf @@base_path
  end

  it 'should have tests registered' do
    WarningShot::DirectoryResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::DirectoryResolver.resolutions.empty?.should be(false)
  end
  
  describe 'with resolutions enabled & with resolution instructions' do

    it 'should create the directory if it does not exist' do
      resolver = WarningShot::DirectoryResolver.new
      
      control_dir = File.expand_path('.')
      test_dir1 = File.join(@@base_path,'test1')
      test_dir2 = File.join(@@base_path,'test2')
      resolver.init [control_dir,test_dir1, test_dir2]
      resolver.test!
      resolver.succeeded.length.should be(1)
      resolver.failed.length.should be(2)
      
      resolver.resolve!
      resolver.resolved.length.should be(2)
      File.directory?(test_dir1).should be(true)
      File.directory?(test_dir2).should be(true)        
    end      
  end # End healing enabled, instructions provided
end