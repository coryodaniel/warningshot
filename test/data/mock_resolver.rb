class MockResolver
  include WarningShot::Resolver
  
  ######### Flags
  disabled!
  rescue_me!
  
  ######### Attributes
  order 1
  name 'mock'
  description 'A mock resolver'

  def initialize;end;
  
end

# TODO RENAME order to order