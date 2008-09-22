require File.join($test_data, 'mock_resolver')

describe WarningShot::Resolver do
  it 'should provide a base set of resolvers' do
    WarningShot::Resolver.descendents.class.should be(Array)
    WarningShot::Resolver.descendents.empty?.should be(false)
  end
  
  it 'should allow a resolver to set a order' do
    MockResolver.order 500
    MockResolver.order.should be(500)
  end
  
  it 'should allow a resolver to be disabled' do
    MockResolver.disabled!
    MockResolver.disabled?.should be(false)
  end
  
  it 'should allow a name to be set' do
    MockResolver.name "Boogertron"
    MockResolver.name.should == "Boogertron"
  end
  
  it 'should allow a description to be set' do
    MockResolver.description "An awesome mock resolver"
    MockResolver.description.should == "An awesome mock resolver"
  end
  
  it 'should allow the CLI to be extended' do
    MockResolver.cli(
      :short        => "-t",
      :long         => "--test=STRING",
      :description  => "Test extending the CLI",
      :default      => 'whatever',
      :name         => 'rspec_test',
      :type         => String,
      :default_desc => "Default: whatever"
    )
    
    WarningShot.parser.to_s.include?("Test extending the CLI").should be(true)    
  end
  
  it 'should be able to cast YAML data to an Object the resolver can work with' do
    MockDependency = Struct.new :more, :less
    
    MockResolver.cast do |dep|
      MockDependency.new dep[:more], dep[:less]
    end
    
    yaml_hash = {:more => 'is less', :less => 'is more'}
    my_obj = MockResolver.yaml_to_object(yaml_hash)
    my_obj.class.should be(MockDependency)
    my_obj.more.should == (yaml_hash[:more])
  end
  

  it 'should be able to register a test' do
    MockResolver.register_test do |dependency|
      "This is a dependency test #{dependency}"
    end
        
    MockResolver.instance_variable_get("@test_blocks").first[:test].call("TEST").should == "This is a dependency test TEST"
    
    MockResolver.flush_tests!
    
    MockResolver.register_test do
      "This is a test"
    end
    
    MockResolver.instance_variable_get("@test_blocks").first[:test].call("TEST").should == "This is a test"
  end

  it 'should allow a resolver to flush out tests' do
    MockResolver.register_test do |dependency|
      'This is a dependency test'
    end
    
    MockResolver.instance_variable_get("@test_blocks").empty?.should be(false)
    MockResolver.flush_tests!
    MockResolver.instance_variable_get("@test_blocks").empty?.should be(true)
  end
  
  it 'should be able to register a conditional test' do
    is_test_env = lambda{ |dependency| 
      WarningShot.environment == 'test'
    }
    MockResolver.flush_tests!
    MockResolver.register_test :condition => is_test_env do |dependency|
      'This is a conditional dependency test'
    end
    
    MockResolver.instance_variable_get("@test_blocks").first[:test].call(nil).should == 'This is a conditional dependency test'
    MockResolver.instance_variable_get("@test_blocks").first[:condition].class.should be(Proc)
  end
  
  it 'should be able to specify additional attributes for a test' do
    test = {
      :name => :named_test,
      :desc => "This is a named test",
    }
    
    MockResolver.flush_tests!
    MockResolver.register_test test do |dependency|
      'This is a named test'
    end

    (MockResolver.instance_variable_get("@test_blocks").first[:name]== :named_test).should be(true)
    MockResolver.instance_variable_get("@test_blocks").first[:desc].should == test[:desc]
  end
  
  it 'should be able to register multiple tests' do
    MockResolver.flush_tests!
    MockResolver.register_test do 
      'Pass one'
    end
    MockResolver.register_test do 
      'Pass two'
    end
    
    MockResolver.instance_variable_get("@test_blocks").length.should be(2)
    MockResolver.instance_variable_get("@test_blocks").last[:test].call(nil).should == 'Pass two'
  end
  
  it 'should be able to register a resolution' do
    MockResolver.register_resolution do |dependency|
      "I resolved the issue, #{dependency}."
    end
    
    MockResolver.instance_variable_get("@resolution_blocks").first[:resolution].call('sirs').should == "I resolved the issue, sirs."
    
    MockResolver.flush_resolutions!
    
    MockResolver.register_resolution do
      "This is a resolution"
    end
    
    MockResolver.instance_variable_get("@resolution_blocks").first[:resolution].call(nil).should == "This is a resolution"
  end
  
  it 'should allow a resolver to flush out resolutions' do
    MockResolver.register_resolution do |dependency|
      'This is a dependency resolution'
    end
    
    MockResolver.instance_variable_get("@resolution_blocks").empty?.should be(false)
    MockResolver.flush_resolutions!
    MockResolver.instance_variable_get("@resolution_blocks").empty?.should be(true)
  end
  
  it 'should be able to register a conditional resolution' do
    is_test_env = lambda{ |dependency| 
      WarningShot.environment == 'production'
    }
    MockResolver.flush_resolutions!
    MockResolver.register_resolution :condition => is_test_env do |dependency|
      "id only resolve if this was production"
    end
    
    MockResolver.instance_variable_get("@resolution_blocks").first[:resolution].call(nil).should == "id only resolve if this was production"
    MockResolver.instance_variable_get("@resolution_blocks").first[:condition].class.should be(Proc)
  end
  
  it 'should be able to specify additional attributes for a resolution' do
    res = {
      :name => :named_resolution,
      :desc => "This is a named resolution",
    }
    
    MockResolver.flush_resolutions!
    MockResolver.register_resolution res do |dependency|
      'This is a named resolution'
    end

    (MockResolver.instance_variable_get("@resolution_blocks").first[:name]== :named_resolution).should be(true)
    MockResolver.instance_variable_get("@resolution_blocks").first[:desc].should == res[:desc]
  end
  
  it 'should be able to register multiple resolutions' do
    MockResolver.flush_resolutions!
    MockResolver.register_resolution do 
      'Part one of fix'
    end
    MockResolver.register_resolution do 
      'Part two of fix'
    end
    
    MockResolver.instance_variable_get("@resolution_blocks").length.should be(2)
    MockResolver.instance_variable_get("@resolution_blocks").last[:resolution].call(nil).should == 'Part two of fix'
  end
    
  it 'should allow before filters for resolutions and tests (also, named)' do
    # TODO after implementing in resolver.rb & dependency_resolver.rb
    # two arrays named and unnamed
    # :name, &block
    pending
  end
  
  it 'should allow after filters for resolutions and tests (also, named)' do
    # TODO after implementing in resolver.rb & dependency_resolver.rb
    # two arrays named and unnamed
    # :name, &block
    pending
  end
end