require File.join(%w(. lib resolvers symlink_resolver))

describe WarningShot::SymlinkResolver do
  before :all do
    @@data_path = File.expand_path(File.join(%w(. test data)))
    @@base_path = File.expand_path(File.join(%w(. test data resolvers symlink)))
  end
  
  before :each do
    FileUtils.mkdir_p @@base_path
  end

  after :each do
    FileUtils.rm_rf @@base_path
  end

  it 'should have tests registered' do
    WarningShot::SymlinkResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::SymlinkResolver.resolutions.empty?.should be(false)
  end
     
  describe 'with healing enabled & with heal instructions' do
    it 'should create a symlink' do

      symlink_dep = {
        :source => File.join(@@data_path,'mock_resolver.rb'),
        :target => File.join(@@base_path,'linked_mock_resolver.rb')
      }
      resolver = WarningShot::SymlinkResolver.new symlink_dep
      
      resolver.test!
      resolver.failed.length.should be(1)
      resolver.resolve!
      resolver.resolved.length.should be(1)
      
      File.symlink?(symlink_dep[:target]).should be(true)
    end
  end # End healing enabled, instructions provided
end