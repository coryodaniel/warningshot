require "." / "lib" / "resolvers" / "symlink_resolver"
require 'digest/md5'

describe WarningShot::SymlinkResolver do
  before :all do
    WarningShot::SymlinkResolver.logger = $logger 
    
    @@data_path = File.expand_path("." / "test" / "data")
    @@base_path = File.expand_path("." / "test" / "data" / "resolvers" / "symlink")
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
        :source => @@data_path / 'mock_resolver.rb',
        :target => @@base_path / 'linked_mock_resolver.rb'
      }
      resolver = WarningShot::SymlinkResolver.new WarningShot::Config.create,:symlink,symlink_dep
      
      resolver.test!
      resolver.failed.length.should be(1)
      resolver.resolve!
      resolver.resolved.length.should be(1)
      
      File.symlink?(symlink_dep[:target]).should be(true)
    end
  end # End healing enabled, instructions provided
  
  describe 'it should expand the target and source paths' do
    sym = WarningShot::SymlinkResolver.yaml_to_object({:source => "./test_src_expand",:target => "../test_target_expand",:force => true})
    sym.source.should == File.expand_path("./test_src_expand")
    sym.target.should == File.expand_path("../test_target_expand")
  end
end