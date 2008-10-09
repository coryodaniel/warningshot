describe WarningShot::DependencyResolver do
  it 'should accept a glob to find config files' do
    # Consider taking a glob instead of a set of paths
    pending
  end
  
  it 'should create a dependency tree from a set of config files' do
    config = {
      :config_paths => [$test_data],
      :environment => 'rspec'
    }
    
    dr = WarningShot::DependencyResolver.new(config)
    
    dr.dependency_tree[:mock].empty?.should be(false)
    dr.dependency_tree[:mock].class.should be(Array)
    dr.dependency_tree[:mock].size.should == 10

    dr.dependency_tree.key?(:faux).should be(true)
    dr.dependency_tree[:faux].empty?.should be(true)        
  end
  
  it 'should have some sort of neat way to deal with conflicts between files & environments.' do
    # if fileA has two conflicting settings between global & running env, running env wins
    # if fileA and fileB have to conflicting settings, WHO WINS?!
    pending
  end
end