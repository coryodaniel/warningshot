
# TODO Branch should take a params of branches, here: file, directory, symlink
# TODO uid, gid should be integer or string (string for name, interger for id)
# 

class WarningShot::PermissionResolver
  include WarningShot::Resolver
  order  100
  branch :permission
  description 'Validates mode, user, and group permission on files and directories'
         
  PermissionResource = Struct.new(:path,:target_mode,:target_user,:target_group,:recursive) do
    def exists?
      File.exist? self.path
    end
    
    def correct_owner!
      false
    end
    
    def correct_group!
      false
    end
    
    def correct_mode!
      false
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
  
  typecast Hash do |yaml|
    PermissionResource.new  yaml.delete(:path), 
                            yaml.delete(:mode)      || '0755',
                            yaml.delete(:user)      || 'nobody',
                            yaml.delete(:group)     || 'nobody',
                            yaml.delete(:recursive) || 'none'
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