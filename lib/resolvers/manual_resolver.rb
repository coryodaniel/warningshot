class WarningShot::ManualResolver
  include WarningShot::Resolver
  order  10000
  #disable!

  branch :manual
  description 'A glorified todo list of things that need to be resolved manually'
      
  #Encapsulated in a struct so Resolver doesn't freak out when we instance_eval #met & #resolved
  NoteResource = Struct.new(:msg)
    
  cast do |note|
    NoteResource.new(note)
  end
  
  register :test do |dep|
    logger.info " ~ #{dep.msg}"
  end
end