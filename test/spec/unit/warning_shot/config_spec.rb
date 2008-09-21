describe WarningShot::Config do
  
  it 'should provide access to configuration' do
    WarningShot::Config.respond_to? :configuration
  end
  
  it 'should be able to parse an ARGV string' do
    args = ['--no-verbose','--heal','--environment=rspec_test','-g','-aRspecTest']
    WarningShot::Config.parse_args(args)
    WarningShot::Config.configuration[:verbose].should be(false)
    WarningShot::Config.configuration[:heal].should be(true)
    WarningShot::Config.configuration[:environment].should == 'rspec_test'
    WarningShot::Config.configuration[:growl].should be(true)
    WarningShot::Config.configuration[:application].should == 'RspecTest'
  end
  
  it 'should provide defaults' do
    WarningShot::Config.defaults.class.should be(Hash)
  end
  
  it 'should allow access like a hash' do
    WarningShot::Config.respond_to?(:[]).should be(true)
    WarningShot::Config.respond_to?(:[]=).should be(true)
  end
  
  it 'should allow configurations to be changed with a block' do
    WarningShot::Config.use do|c|
      c[:growl] = true
      c[:heal]= true
    end
    
    WarningShot::Config[:growl].should be(true)
    WarningShot::Config[:heal].should be(true)
  end
end