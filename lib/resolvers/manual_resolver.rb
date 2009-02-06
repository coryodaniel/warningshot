class WarningShot::ManualResolver
  include WarningShot::Resolver
  order  10000
  branch :manual
  
  description 'A glorified todo list of things that need to be done manually'
      
  cli("--notes", "List all the notes in the manual branch") do |val|
    WarningShot::Resolver.descendants.each{|d| d.disable!}
    self.enable!
    
    #REmove any occurance of --notes
    args = ARGV - ARGV.find_all{|x| x =~ /--notes/i}
    config = WarningShot::Config.parse_args(args)
    
    config[:verbosity] = :verbose

    dr = WarningShot::DependencyResolver.new(config)    

    dr.dependency_tree[:manual].each { |note| puts "~ #{note}" }
    
    exit
  end
  
  #Encapsulated in a struct so Resolver doesn't freak out when we instance_eval #met & #resolved
  NoteResource = Struct.new(:msg)
    
  typecast do |note|
    NoteResource.new(note)
  end
  
  before(:test){logger.info "\nReminders:"}
  register(:test){|dep| logger.info " ~ #{dep.msg}"}
  after(:test){ logger.info ""}  
end