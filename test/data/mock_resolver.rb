class MockResolver
  include WarningShot::Resolver
  
  ######### Flags
  disable!
  
  ######### Attributes
  order 1
  branch :mock
  description 'A mock resolver for testing'

  def initialize(c,b,*d)
    super
    MockResolver.logger.debug 'A mock resolver was initialized'
  end
  
  MockStruct = Struct.new(:value)
  typecast String do |dep|
    MockStruct.new(dep)
  end
  
end