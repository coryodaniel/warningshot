=begin
class WarningShot::PermissionResolver
  include WarningShot::Resolver
  order  100
  #disable! 

  branch :permission
  description 'Validates mode, user, and group permission on files and directories'
       
  cast do |yaml|
    #HOW TO CAST YAML DATA
  end
  
  register :test do |dep|
    
  end
  
  register :resolution do |dep|
    
  end
end
=end