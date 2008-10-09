class MockResolver
  include WarningShot::Resolver
  
  ######### Flags
  disabled!
  rescue_me!
  
  ######### Attributes
  order 1
  name 'mock'
  description 'A mock resolver'
  
  before :tests do
    puts "MockResolver tests are about to runner"
  end
  
  after :resolutions do
    puts "MockResolver resolutions just ran"
  end
  
  def initialize;end;
  
end

# TODO RENAME order to order