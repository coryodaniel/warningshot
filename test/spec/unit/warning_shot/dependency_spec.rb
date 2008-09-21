require File.join($test_data, 'mock_dependency')

describe WarningShot::Dependency do
  it 'should provide a base set of dependencies' do
    WarningShot::Dependency.descendents.class.should be(Array)
    WarningShot::Dependency.descendents.empty?.should be(false)
  end
  
  it 'should allow a dependency to set a priority' do
    MockDependency.priority 500
    MockDependency.priority.should be(500)
  end
  
  it 'should allow a dependency to be disabled' do
    MockDependency.disabled? false
    MockDependency.disabled?.should be(false)
  end
  
  it 'should allow a name to be set' do
    MockDependency.name "Boogertron"
    MockDependency.name.should == "Boogertron"
  end
  
  it 'should allow a description to be set' do
    MockDependency.description "An awesome mock dependency"
    MockDependency.description.should == "An awesome mock dependency"
  end
  
  it 'should allow the CLI to be extended' do
    MockDependency.cli(
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
  
  it 'should raise an exception if Dependency#test is not implemented' do
    lambda{MockDependency.new.test}.should raise_error(Exception)
  end
end