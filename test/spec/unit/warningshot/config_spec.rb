describe WarningShot::Config do
    
  it 'should be able to parse an ARGV string' do
    args = ['--very-verbose','--resolve','--environment=rspec_test','-g','-aRspecTest']
    config = WarningShot::Config.parse_args(args)
    config[:verbose].should be(true)
    config[:resolve].should be(true)
    config[:environment].should == 'rspec_test'
    config[:growl].should be(true)
    config[:application].should == 'RspecTest'
  end
  
  it 'should provide defaults' do
    defined?(WarningShot::Config::DEFAULTS).should == 'constant'
    WarningShot::Config::DEFAULTS.class.should be(Hash)
  end
  
  it 'should set defaults if no configuration is passed in' do
    config = WarningShot::Config.create
    config.should == WarningShot::Config::DEFAULTS
  end
  
  it 'should allow configurations to be done with a hash and still set defaults' do
    _config = {
      :growl => true,
      :environment => :rspec_test
    }
    config = WarningShot::Config.create _config
    config[:growl].should be(true)
    config[:environment].should == :rspec_test
    config[:colorize].should be(true)
  end
  
  it 'should allow configurations to be changed with a block' do
    config = WarningShot::Config.create do|c|
      c[:growl] = true
      c[:resolve]= true
    end
    
    config[:growl].should be(true)
    config[:resolve].should be(true)
    config[:colorize].should be(true)
  end
  

  it 'should allow a hash and block to be passed, block wins' do
    conf = WarningShot::Config.create({:environment=>"hash",:something=>true}) do |c|
      c[:environment] = "blk"
      c[:else] = true
    end
    
    conf[:environment].should == "blk"
    conf[:something].should be(true)
    conf[:else].should be(true)
    conf[:colorize].should be(true)
   end
end