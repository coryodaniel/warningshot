class MockResolver
  include WarningShot::Resolver
  
  ######### Flags
  disabled!
  rescue_me!
  
  ######### Attributes
  priority 1
  name 'mock'
  description 'A mock resolver'
  
  
  def initialize;end;
  
end

# TODO RENAME priority to order