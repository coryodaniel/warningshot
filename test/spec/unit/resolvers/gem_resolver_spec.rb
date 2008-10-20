# NOTE: All tests that install/uninstall gems should use 'ws-dummy' gem.
#   All tests for testing existance of gems should use 'warningshot' or 'ws-dummy'

require "." / "lib" / "resolvers" / "gem_resolver"
require 'fileutils'
describe WarningShot::GemResolver do
  before :all do
    WarningShot::GemResolver.logger = $logger
    
    FileUtils.rm_rf "./test/output/gems"
  end
  
  after :each do
    FileUtils.rm_rf "./test/output/gems"
  end

  it 'should have tests registered' do
    WarningShot::GemResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::GemResolver.resolutions.empty?.should be(false)
  end
  
  it 'should provide the command line option gem_path' do
    WarningShot.parser.to_s.include?("Alternate gem path ':' separated to check.  First in path is where gems will be installed").should be(true)
    WarningShot::Config.configuration.key?(:gem_path).should be(true)
  end
  
  it 'should provide the command line option minigems' do
    WarningShot.parser.to_s.include?("Not supported yet.").should be(true)
    WarningShot::Config.configuration.key?(:minigems).should be(true)
  end
  
  it 'should override Gem.path if gem_path is given' do
    WarningShot::Config.configuration[:gem_path] = "./test/output/gems:./test/outputs/gems2"
    WarningShot::GemResolver.load_paths
    
    Gem.path[0].should == File.expand_path("./test/output/gems")
    Gem.path[1].should == File.expand_path("./test/outputs/gems2")
  end
  
  it 'should be able to determine if a gem is installed' do
    resolver = WarningShot::GemResolver.new({:name => "warningshot"})
    resolver.test!
    
    resolver.passed.size.should be(1)
  end
    
  # The gem name is the healing instructions, so if its provide it is the instructions 
  it 'should install the gems when healing is enabled' do
    resolver = WarningShot::GemResolver.new({:name => "ws-dummy"})
    resolver.test!
    
    resolver.failed.size.should be(1)
    
    resolver.resolve!
    resolver.resolved.size.should be(1)
    
    _version_found = Gem.cache.search('ws-dummy')
    # 1.5.0 is the newest version...
    _version_found.first.version.to_s.should == '1.5.0'
  end
  
  it 'should be able to install a specific version' do
    resolver = WarningShot::GemResolver.new({:name => "ws-dummy", :version=>"0.2.0"})
    resolver.test!
    resolver.failed.size.should be(1)
    #resolver.resolve!
    
    #_version_found = Gem.cache.search('ws-dummy')
    #_version_found.first.version.to_s.should == '0.2.0'
    pending
  end

  it 'should be able to determine if a specific version is installed' do
    pending
  end
  

  
  it 'should check for gems in --gempath when specified' do
    pending
  end
  
  it 'should install gems in --gempath when specified and resolving' do
    pending
  end
end