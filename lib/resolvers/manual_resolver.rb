class WarningShot::ManualResolver
  include WarningShot::Resolver
  order  10000
  branch :manual
  description 'A glorified todo list of things that need to be resolved manually'
      
  cli("--notes", "List all the notes in the manual branch") do |val|
    WarningShot::Resolver.descendants.each{|d| d.disable!}
    self.enable!
    
    config = WarningShot::Config.parse_args
    config[:verbose] = true
    
    dr = WarningShot::DependencyResolver.new(config)    
    dr.dependency_tree[:manual].each { |note| puts "~ #{note}" }
    
    exit
  end
  
  #Encapsulated in a struct so Resolver doesn't freak out when we instance_eval #met & #resolved
  NoteResource = Struct.new(:msg)
    
  typecast do |note|
    NoteResource.new(note)
  end
  
  register :test do |dep|
    logger.info " ~ #{dep.msg}"
  end
  
  class << self
    def notes
      puts "TODO Output notes here..."
    end
  end
end