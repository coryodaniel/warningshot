class MockResolver
  include WarningShot::Resolver
  
  ######### Flags
  disable!
  rescue_me!
  
  ######### Attributes
  order 1
  branch :mock
  description 'A mock resolver'

  def initialize;end;
  
end

# TODO RENAME order to order