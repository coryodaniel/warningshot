describe WarningShot::DependencyResolver do
  it 'should accept a glob to find config files' do
    # Consider taking a glob instead of a set of paths
    pending
  end
  
  it 'should create a dependency tree from a set of config files' do
    config = {
      :config_paths => [$test_data],
      :environment => 'rspec',
      :log_path => $log_file
    }
    
    dr = WarningShot::DependencyResolver.new(config)
    
    dr.dependency_tree[:mock].empty?.should be(false)
    dr.dependency_tree[:mock].class.should be(Array)
    dr.dependency_tree[:mock].size.should == 10

    dr.dependency_tree.key?(:faux).should be(true)
    dr.dependency_tree[:faux].empty?.should be(true)        
  end
  
end