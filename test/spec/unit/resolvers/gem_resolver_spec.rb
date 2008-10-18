#Note, this fails if the gem yard is already installed, which sucks.  Waiting on rubyforge to
# approve ws-dummy gem

require "." / "lib" / "resolvers" / "gem_resolver"
require 'fileutils'
describe WarningShot::GemResolver do
  before :all do
    WarningShot::GemResolver.logger = $logger
    
    FileUtils.rm_rf "./test/output/gems"
  end
  
  after :all do
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
    
    Gem.path[0].should == "./test/output/gems"
    Gem.path[1].should == "./test/outputs/gems2"
  end
  
  it 'should be able to determine if a gem is installed' do
    resolver = WarningShot::GemResolver.new({:name => "rake"},{:name => "rspec",:version => ">=1.1.4"})
    resolver.test!
    
    resolver.passed.size.should be(2)
  end
    
  # The gem name is the healing instructions, so if its provide, there
  #   are instructions 
  it 'should install the gems when healing is enabled' do
    resolver = WarningShot::GemResolver.new({:name => "yard"})
    resolver.test!
    
    resolver.failed.size.should be(1)
    
    resolver.resolve!
    resolver.resolved.size.should be(1)
  end
    
  it 'should use warningshot_dummy instead of the gems listed above' do
    #it should also uninstall it before :all and after :all
    pending
  end
end