# TODO It would be really sweet if there was a way for FileResolver, 
#   DirectoryResolver, and SymlinkResolver inherited this functionality if
#   mode, user, or group is set in its config file.
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
    
  PermissionResource = Struct.new(:path,:target_mode,:target_user,:target_group,:recursive) do
    def exists?
      File.exist? self.path
    end
    
    def correct_owner?
      false
    end
    
    def correct_group?
      false
    end
    
    def correct_mode?
      false
    end
  end
  
  cast Hash do |yaml|
    _path       = yaml.delete(:path)
    _mode       = yaml.delete(:mode)      || '0755'
    _user       = yaml.delete(:user)      || 'nobody'
    _group      = yaml.delete(:group)     || 'nobody'
    _recursive  = yaml.delete(:recursive) || 'none'
    
    PermissionResource.new _path, _mode, _user, _group, _recursive
  end
  
  register :test do |resource|
    _valid = resource.exists?
    
    if _valid
      _valid &= resource.correct_owner?
      _valid &= resource.correct_group?
      _valid &= resource.correct_mode?
    end
    
    if _valid
      logger.debug " ~ [PASSED] permission: #{resource.path}"
    else
      logger.warn " ~ [FAILED] permission: #{resource.path}"
    end
      
    _valid
  end
  
  register :resolution do |resource|
  end
end