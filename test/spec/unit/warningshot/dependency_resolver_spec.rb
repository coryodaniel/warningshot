describe WarningShot::DependencyResolver do
  before :all do
    @config = WarningShot::Config.create({
      :config_paths => [$test_data / "*.{yml,yaml}"],
      :environment => 'rspec',
      :log_path => $log_file
    })
    
  end
  
  it 'should accept a glob to find config files' do
    dr = WarningShot::DependencyResolver.new(@config)
    dr.dependency_tree.length.should_not be(0)
  end
  
  it 'should create a dependency tree from a set of config files' do    
    dr = WarningShot::DependencyResolver.new(@config)
    
    dr.dependency_tree[:mock].empty?.should be(false)
    dr.dependency_tree[:mock].class.should be(Array)
    dr.dependency_tree[:mock].size.should == 10

    dr.dependency_tree.key?(:faux).should be(true)
    dr.dependency_tree[:faux].empty?.should be(true)        
  end
  
  it 'should respond to #stats' do
    dr = WarningShot::DependencyResolver.new(@config)
    dr.respond_to?(:stats).should be(true)
    dr.stats.class.should be(Hash)
  end
  
  it 'should ignore resolvers that dont have dependencies registered' do
    pending
  end
  
  it 'should ignore disabled resolvers' do
    pending
  end
  
  it 'should be able to run a set of resolvers' do
    config = WarningShot::Config.create({
      :config_paths => [$test_data],
      :environment => 'rspec',
      :log_path => $log_file,
      :oload => :faux_test
    })
    
    pending
  end
  
end