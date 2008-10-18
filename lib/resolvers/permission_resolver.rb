require 'open4'

class WarningShot::PermissionResolver
  include WarningShot::Resolver
  order  100
  branch :permission
  description 'Validates mode, user, and group permission on files and directories'
     
  module UnixPermissionsInterface;end;  
  module WindowsPermissionsInterface;end;
       
  if WarningShot.platform != :windows
    include WarningShot::PermissionResolver::UnixPermissionsInterface
    #http://www.ruby-doc.org/core/classes/File/Stat.html
    #http://www.ruby-doc.org/stdlib/libdoc/etc/rdoc/index.html
    #http://www.ruby-doc.org/stdlib/libdoc/pathname/rdoc/index.html
    #http://www.ruby-doc.org/stdlib/libdoc/fileutils/rdoc/index.html
    #http://www.ruby-doc.org/core/classes/File.html#M002574
  else
    include WarningShot::PermissionResolver::WindowsPermissionsInterface
  end     
  
  PermissionResource = Struct.new(:path,:target_mode,:target_owner,:target_group) do
    def owner;end;
    def group;end;
    def mode;end;
  end
  
  cast Hash do |yaml|
    PermissionResource.new
  end
  
  register :test do |dep|
  end
  
  register :resolution do |dep|
  end
end