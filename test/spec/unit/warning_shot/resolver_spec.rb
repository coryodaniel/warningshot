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
    MockResolver.disable!
    MockResolver.disabled?.should be(true)
    MockResolver.instance_variable_set('@disabled',false)
  end

  it 'should allow a resolution branch to be set' do
    MockResolver.branch :a_test_branch
    MockResolver.branch.should == :a_test_branch
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
    MockResolver.register :test do |dependency|
      "This is a dependency test #{dependency}"
    end

    MockResolver.tests.first[:test].call("TEST").should == "This is a dependency test TEST"
    MockResolver.flush_tests!

    MockResolver.register :test do
      "This is a test"
    end

    MockResolver.tests.first[:test].call("TEST").should == "This is a test"
  end

  it 'should allow a resolver to flush out tests' do
    MockResolver.register :test do |dependency|
      'This is a dependency test'
    end

    MockResolver.tests.empty?.should be(false)
    MockResolver.flush_tests!
    MockResolver.tests.empty?.should be(true)
  end

  it 'should be able to register a conditional test' do
    is_test_env = lambda{ |dependency| 
      WarningShot.environment == 'test'
    }
    MockResolver.flush_tests!
    MockResolver.register :test, :if => is_test_env do |dependency|
      'This is a conditional dependency test'
    end

    MockResolver.tests.first[:test].call(nil).should == 'This is a conditional dependency test'
    MockResolver.tests.first[:if].class.should be(Proc)
  end
  
  it 'should be able to specify additional attributes for a test' do
    test_details = {
      :name => :named_test,
      :desc => "This is a named test",
    }
    
    MockResolver.flush_tests!
    MockResolver.register :test, test_details do |dependency|
      'This is a named test'
    end

    (MockResolver.tests.first[:name]== :named_test).should be(true)
    MockResolver.tests.first[:desc].should == test_details[:desc]
  end
  
  it 'should be able to register multiple tests' do
    MockResolver.flush_tests!
    MockResolver.register :test do 
      'Pass one'
    end
    MockResolver.register :test do 
      'Pass two'
    end
    
    MockResolver.tests.length.should be(2)
    MockResolver.tests.last[:test].call(nil).should == 'Pass two'
  end
  
  it 'should be able to register a resolution' do
    MockResolver.register :resolution do |dependency|
      "I resolved the issue, #{dependency}."
    end
    
    MockResolver.resolutions.first[:resolution].call('sirs').should == "I resolved the issue, sirs."
    
    MockResolver.flush_resolutions!
    
    MockResolver.register :resolution do
      "This is a resolution"
    end
    
    MockResolver.resolutions.first[:resolution].call(nil).should == "This is a resolution"
  end
  
  it 'should raise an exception if :if and :unless are specified on the same test or resolution' do
    lambda{
      MockResolver.register :resolution, :if => lambda{}, :unless => lambda{} do
        puts 'This should fail'
      end
    }.should raise_error(Exception)
    
    lambda{
      MockResolver.register :test, :if => lambda{}, :unless => lambda{} do
        puts 'This should fail'
      end
    }.should raise_error(Exception)
  end
  
  it 'should allow a resolver to flush out resolutions' do
    MockResolver.register :resolution do |dependency|
      'This is a dependency resolution'
    end
    
    MockResolver.resolutions.empty?.should be(false)
    MockResolver.flush_resolutions!
    MockResolver.resolutions.empty?.should be(true)
  end
  
  it 'should be able to register a conditional resolution' do
    is_test_env = lambda{ |dependency| 
      WarningShot.environment == 'production'
    }
    MockResolver.flush_resolutions!
    MockResolver.register :resolution, :if => is_test_env do |dependency|
      "id only resolve if this was production"
    end
    
    MockResolver.resolutions.first[:resolution].call(nil).should == "id only resolve if this was production"
    MockResolver.resolutions.first[:if].class.should be(Proc)
  end

  it 'should be able to specify additional attributes for a resolution' do
    res_details = {
      :name => :named_resolution,
      :desc => "This is a named resolution",
    }

    MockResolver.flush_resolutions!
    MockResolver.register :resolution, res_details do |dependency|
      'This is a named resolution'
    end

    (MockResolver.resolutions.first[:name]== :named_resolution).should be(true)
    MockResolver.resolutions.first[:desc].should == res_details[:desc]
  end

  it 'should be able to register multiple resolutions' do
    MockResolver.flush_resolutions!
    MockResolver.register :resolution do 
      'Part one of fix'
    end
    MockResolver.register :resolution do 
      'Part two of fix'
    end
    
    MockResolver.resolutions.length.should be(2)
    MockResolver.resolutions.last[:resolution].call(nil).should == 'Part two of fix'
  end

  it 'should allow before filters for tests' do
    MockResolver.before :test do
      puts "Im before a test"
    end

    MockResolver.before_filters(:test).length.should be(1)
  end

  it 'should allow after filters for tests' do
    MockResolver.after :test do
      puts "Im after a test"
    end

    MockResolver.after_filters(:test).length.should be(1)
  end

  it 'should allow before filters for resolutions' do
    MockResolver.before :resolution do
      puts "Im before a resolution"
    end

    MockResolver.before_filters(:resolution).length.should be(1)
  end

  it 'should allow after filters for resolutions' do
    MockResolver.after :resolution do
      puts "Im after a resolution"
    end

    MockResolver.after_filters(:resolution).length.should be(1)
  end

  it 'should be able to specify an :if condition on tests' do
    #This is false, wtf? Fuck string comparison.
    condition = lambda{ ("david lee roth" > "eddie van halen") }
    MockResolver.register(:test, :if => condition, :name => :rock_out_test) {|dep| true}

    MockResolver.tests(:rock_out_test)[:if].call.should be(false)
  end

  it 'should be able to specify an :unless condition on tests' do
    # String comparison has no taste in music
    condition = lambda{ ("weezer" > "the rentals") }
    MockResolver.register(:test, :unless => condition, :name => :rock_out_test2) {|dep| true}
  
    MockResolver.tests(:rock_out_test2)[:unless].call.should be(true)
  end

  it 'should be able to specify an :if condition on resolutions' do
    condition = lambda{ (3 > 5) }
    MockResolver.register(:resolution, :if => condition, :name => :number_resolution) {|dep| true}
  
    MockResolver.resolutions(:number_resolution)[:if].call.should be(false)
  end

  it 'should be able to specify an :unless condition on resolutions' do
    condition = lambda{ (5 == 5) }
    MockResolver.register(:resolution, :unless => condition, :name => :number_resolution1) {|dep| true}

    MockResolver.resolutions(:number_resolution1)[:unless].call.should be(true)
  end
  
  it 'should incremenet #succeeded if the test passed' do
    pending
  end
  
  it 'should increment #failed if the test failed' do
    pending
  end
  
  it 'should increment #resolved if the resolution succeeded' do
    pending
  end
  
  it 'should increment #unresolved if the resolution was unresolved' do
    pending
  end

  it 'should be able to determine if a test passed' do
    MockResolver.flush_tests!
    MockResolver.flush_resolutions!

    test_meta = {
      :name => :process_block_test,
      :test => lambda {|dep| dep[:fav_color] == :blue}
    }
    
    dep = {:fav_color => :blue}

    MockResolver.new.send(:process_block, :test, dep, test_meta).should be(true)
  end
  
  it 'should be able to determine if a test failed' do
    MockResolver.flush_tests!
    MockResolver.flush_resolutions!

    test_meta = {
      :name => :process_block_test,
      :test => lambda {|dep| dep[:fav_color] == :blue}
    }
    
    dep = {:fav_color => :red}

    MockResolver.new.send(:process_block, :test, dep, test_meta).should be(false)
  end

  it 'should be able to determine if a resolution passed' do
    MockResolver.flush_tests!
    MockResolver.flush_resolutions!

    resolution_meta = {
      :name => :process_block_test,
      :resolution => lambda {|dep| 
        dep[:fav_color] = :blue
        dep[:fav_color] == :blue
      }
    }
    
    dep = {:fav_color => :red}

    MockResolver.new.send(:process_block, :resolution, dep, resolution_meta).should be(true)
  end

  it 'should be able to determine if a resolution failed' do
    MockResolver.flush_tests!
    MockResolver.flush_resolutions!

    resolution_meta = {
      :name => :process_block_test,
      :resolution => lambda {|dep| 
        begin
          dep[:fav_color] = :blue
        rescue Exception
          # nada
        end
        dep[:fav_color] == :blue
      }
    }
    
    dep = {:fav_color => :red}.freeze

    MockResolver.new.send(:process_block, :resolution, dep, resolution_meta).should be(false)
  end
end