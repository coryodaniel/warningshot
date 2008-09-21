class MockDependency
  include WarningShot::Dependency
  
  disabled? false
  priority 1
  name 'mock'
  description 'A mock dependency'
  
  def initialize;end;
end