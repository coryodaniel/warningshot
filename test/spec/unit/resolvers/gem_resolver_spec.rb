# NOTE: All tests that install/uninstall gems should use 'ws-dummy' gem.
#   All tests for testing existance of gems should use 'warningshot' or 'ws-dummy'

require "." / "lib" / "resolvers" / "gem_resolver"
require 'fileutils'
describe WarningShot::GemResolver do
  before :all do
    WarningShot::GemResolver.logger = $logger
    
    FileUtils.rm_rf "./test/output/gems"
    FileUtils.rm_rf "./test/output/gems2"
  end
  
  before :each do
    FileUtils.mkdir_p "./test/output/gems"
    FileUtils.mkdir_p "./test/output/gems2"
  end
  
  after :each do
    FileUtils.rm_rf "./test/output/gems"
    FileUtils.rm_rf "./test/output/gems2"
  end

  it 'should have tests registered' do
    WarningShot::GemResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::GemResolver.resolutions.empty?.should be(false)
  end
  
  it 'should provide the command line option --gempath' do
    WarningShot::Config::PARSER.to_s.include?("Alternate gem path ':' separated to check.  First in path is where gems will be installed").should be(true)
    WarningShot::Config.parse_args(['--gempath',"./test/output/gems"]).key?(:gem_path).should be(true)
  end
      
  it 'should override Gem.path if gempath is given' do
    config = WarningShot::Config.create({:gem_path => "./test/output/gems:./test/outputs/gems2"})
    WarningShot::GemResolver.new config
    
    Gem.path[0].should == File.expand_path("./test/output/gems")
    Gem.path[1].should == File.expand_path("./test/outputs/gems2")
    Gem.path.shift
    Gem.path.shift
  end
    
  it 'should provide the command line option --update-sources' do
    WarningShot::Config::PARSER.to_s.include?("Update gem sources before installing").should be(true)
    WarningShot::Config.parse_args(['--update-sources']).key?(:update_sources).should be(true)
  end
      
  # The gem name is the healing instructions, so if its provide it is the instructions 
  it 'should install the gems when healing is enabled' do
    config = WarningShot::Config.create({:gem_path => "./test/output/gems:./test/outputs/gems2"})
    resolver = WarningShot::GemResolver.new(config,{:name => "ws-dummy"})
    resolver.test!
    
    resolver.failed.size.should be(1)
    
    resolver.resolve!
    resolver.resolved.size.should be(1)
  end
    
  it 'should be able to determine if a gem is installed' do
    config = WarningShot::Config.create({:gem_path => "./test/output/gems:./test/outputs/gems2"})

    resolver = WarningShot::GemResolver.new(config, {:name => "ws-dummy"})
    resolver.test!
    resolver.failed.size.should be(1)
    resolver.resolve!
    
    resolver = WarningShot::GemResolver.new( config,{:name => "ws-dummy"})
    resolver.test!
    resolver.passed.size.should be(1)
  end
  
  it 'should be able to install a specific version' do
    config = WarningShot::Config.create({:gem_path => "./test/output/gems:./test/outputs/gems2"})
    dummy_gem = {:name => "ws-dummy", :version=>"= 0.2.0"}
    
    resolver = WarningShot::GemResolver.new(config,dummy_gem)
    resolver.test!
    resolver.failed.size.should be(1)
    resolver.resolve!
    
    resolver.resolved.size.should be(1)
    resolver.resolved.first.version.to_s.should == dummy_gem[:version]
  end

  it 'should be able to determine if a gem is installed in the default gem path' do
    Gem.clear_paths
    config = WarningShot::Config.create
    dummy_gem = {:name => "ws-dummy", :version=>"= 0.2.0"}
    
    resolver = WarningShot::GemResolver.new(config,dummy_gem)
    resolver.test!
    resolver.failed.size.should be(1)
    resolver.resolve!
    resolver.resolved.size.should be(1)
    resolver.resolved.first.version.to_s.should == dummy_gem[:version]
    
    WarningShot::GemResolver::GemResource.new(dummy_gem[:name],dummy_gem[:version]).uninstall!
  end
  
  it 'should be able to determine if a gem is installed in a different path (--gempath)' do
    config = WarningShot::Config.create({:gem_path => "./test/output/gems:./test/outputs/gems2"})
    resolver = WarningShot::GemResolver.new(config,{:name => "ws-dummy"})
    resolver.test!
    
    resolver.failed.size.should be(1)
    
    resolver.resolve!
    resolver.resolved.size.should be(1)
    
    config = WarningShot::Config.create({:gem_path => "./test/output/gems:./test/outputs/gems2"})
    resolver = WarningShot::GemResolver.new(config,{:name => "ws-dummy"})
    resolver.test!
    resolver.passed.size.should be(1)

    File.exist?("./test/output/gems/specifications/ws-dummy-1.5.0.gemspec").should be(true)
  end

  it 'should be able to determine if a specific version is installed' do
    config = WarningShot::Config.create({:gem_path => "./test/output/gems:./test/outputs/gems2"})
    dummy_gem = {:name => "ws-dummy", :version=>"= 0.2.0"}
    
    resolver = WarningShot::GemResolver.new(config,dummy_gem)
    resolver.test!
    resolver.failed.size.should be(1)
    resolver.resolve!
    
    resolver = WarningShot::GemResolver.new(config,dummy_gem)
    resolver.test!
    resolver.passed.size.should be(1)
  end
  
  it 'should be able to install gems from an alternate source' do
    config = WarningShot::Config.create({:gem_path => "./test/output/gems:./test/outputs/gems2"})
    dummy_gem = {:name => "coryodaniel-ws-dummy", :version=>"= 1.5.0", :source => "http://gems.github.com"}

    resolver = WarningShot::GemResolver.new(config,dummy_gem)
    resolver.test!
    resolver.failed.size.should be(1)
    resolver.resolve!
    
    resolver.resolved.size.should be(1)
    resolver.resolved.first.version.to_s.should == dummy_gem[:version]
  end
  
end