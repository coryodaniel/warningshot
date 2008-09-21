describe WarningShot::DependencyResolver do
  
  it 'should be able to load and store a set of config files' do
    config = {
      :config_paths => [$test_data],
      :environment => 'rspec'
    }
    
    dr = WarningShot::DependencyResolver.new(config)
    dr.data[:mock].empty?.should be(false)
    dr.data[:mock].class.should be(Array)  
  end
  
  it 'should have some sort of neat way to deal with conflicts between files & environments.' do
    # if fileA has two conflicting settings between global & running env, running env wins
    # if fileA and fileB have to conflicting settings, WHO WINS?!
    pending
  end
end