class FauxTestResolver
  include WarningShot::Resolver
    
  ######### Attributes
  
  branch :faux_test
  description "A resolver for testing DependencyResolver's test functionality"

  def initialize(c,b,*d)
    super
  end
  
  FauxTestStruct = Struct.new(:color,:number)
  typecast Hash do |dep|
    FauxTestStruct.new dep['fav_color'], dep['fav_number']
  end
  
  register(:test) do |dep|
    
  end
end