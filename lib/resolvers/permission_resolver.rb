class WarningShot::PermissionResolver
  include WarningShot::Resolver
  order  100
  branch :permission
  description 'Validates mode, user, and group permission on files and directories'
       
  cast do |yaml|
  end
  
  register :test do |dep|
  end
  
  register :resolution do |dep|
  end
end