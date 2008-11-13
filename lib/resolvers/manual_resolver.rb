class WarningShot::ManualResolver
  include WarningShot::Resolver
  order  10000
  #disable!

  branch :manual
  description 'A glorified todo list of things that need to be resolved manually'
      
  cli(
    :long         => "--notes",
    :description  => "List all the notes in the manual branch",
    :name         => "notes",
    :default      => false,
    :action       => lambda{
      puts "HERE ARE THE NOTES"
      WarningShot::ManualResolver.notes
      exit
    }
  )
  
  #Encapsulated in a struct so Resolver doesn't freak out when we instance_eval #met & #resolved
  NoteResource = Struct.new(:msg)
    
  typecast do |note|
    NoteResource.new(note)
  end
  
  register :test do |dep|
    logger.info " ~ #{dep.msg}"
  end
end