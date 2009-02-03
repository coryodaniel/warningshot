class WarningShot::PermissionResolver
  include WarningShot::Resolver
  add_dependency :core, 'etc'
  add_dependency :core, 'fileutils'

  order  1000
  branch :directory, :file, :symlink
  description 'Validates mode, user, and group permission on files and directories'

  PermissionResource = Struct.new(:target,:target_mode,:target_user,:target_group,:recursive,:no_follow) do
    # Get File.stat by stat name
    # param s [Symbol]
    #   self.stat(:ftype) => File.stat(self.target).ftype
    #
    def stat(s)
      #Read with links because WS will need to read the actual link if its set to no follow for symlinks
      # For files, lstat still works for files
      File.lstat(self.target).send(s)
    rescue Exception => ex
      nil
    end

    def exists?
      File.exist? self.target
    end

    # @param type [Symbol]
    #   Retreive the target's current user ID or Name (:id,:name)
    #
    def user(type=:name)
      file_uid = self.stat(:uid)
      (type == :name) ? Etc.getpwuid(file_uid).name : file_uid
    end

    # @param type [Symbol]
    #   Retreive the targets's current group ID or Name (:id,:name)
    #
    def group(type=:name)
      file_gid = self.stat(:gid)
      (type == :name) ? Etc.getgrgid(file_gid).name : file_gid
    end

    # Retreive the target's current mode
    #
    def mode
      "%o" % (self.stat(:mode) & 007777)
    end

    #Attempt to change the user
    def change_user!
      tgt_uid = self.target_user.is_a?(Fixnum) ? self.target_user : Etc.getpwnam(self.target_user).uid
      chown_params = [tgt_uid, nil, self.target]

      if(File.symlink?(self.target) && (self.no_follow == 'both' || self.no_follow == 'chown'))
        File.lchown *chown_params
      elsif(self.stat(:ftype) == 'directory' && (self.recursive == 'both' || self.recursive == 'chown'))
        #DOcumenation for FileUtils.chown_R is wrong (at least for Ubuntu 8.1, takes ID as String.)
        chown_params[1] = chown_params[1].to_s
        FileUtils.chown_R *chown_params
      else
        File.chown *chown_params
      end
    rescue NotImplementedError => ex
      WarningShot::PermissionResolver.logger.error("lchown is not implemented on this machine, (disable nofollow).")
      return false
    rescue Exception => ex
      WarningShot::PermissionResolver.logger.error("Unable to change user for file: #{self.target}; Exception: #{ex.message}")
      return false
    end

    #Attempt to change the group
    def change_group!
      tgt_gid = self.target_group.is_a?(Fixnum) ? self.target_group : Etc.getgrnam(self.target_group).gid
      chown_params = [nil, tgt_gid, self.target]

      if(File.symlink?(self.target) && (self.no_follow == 'both' || self.no_follow == 'chown'))
        File.lchown *chown_params
      elsif(self.stat(:ftype) == 'directory' && (self.recursive == 'both' || self.recursive == 'chown'))
        #DOcumenation for FileUtils.chown_R is wrong (at least for Ubuntu 8.1, takes ID as String.)
        chown_params[1] = chown_params[1].to_s
        FileUtils.chown_R *chown_params
      else
        File.chown *chown_params
      end
    rescue NotImplementedError => ex
      WarningShot::PermissionResolver.logger.error("lchown is not implemented on this machine, (disable nofollow).")
      return false
    rescue Exception => ex
      WarningShot::PermissionResolver.logger.error("Unable to change group for file: #{self.target}; Exception: #{ex.message}")
      return false
    end

    #Attempt to change the mode
    def change_mode!
      chmod_params = [Integer("0" + self.target_mode), self.target]

      if(File.symlink?(self.target) && (self.no_follow == 'both' || self.no_follow == 'chmod'))
        File.lchmod *chmod_params
      elsif(self.stat(:ftype) == 'directory' && (self.recursive == 'both' || self.recursive == 'chmod'))
        FileUtils.chmod_R *chmod_params
      else
        File.chmod *chmod_params
      end
    rescue NotImplementedError => ex
      WarningShot::PermissionResolver.logger.error("lchmod is not implemented on this machine, (disable nofollow).")
      return false
    rescue Exception => ex
      WarningShot::PermissionResolver.logger.error("Unable to change mode for file: #{self.target}; Exception: #{ex.message}")
      return false
    end

    #Are all permissions correct
    def permissions_correct?
      (self.exists? & self.valid_user? & self.valid_group? & self.valid_mode?)
    end

    #Where permissions supplied by the dependency requirement
    def permissions_supplied?
      !!(self.target_mode || self.target_user || self.target_group)
    end

    # is the target's current user correct
    def valid_user?
      unless self.target_user.nil?
        if self.target_user.is_a? String
          !!(self.target_user == self.user)
        else
          !!(self.target_user == self.user(:id))
        end
      else
        # The user is OK if it wasn't specified
        return true
      end
    rescue ArgumentError => ex
      # The user is NOT OK if the user doesn't exist
      WarningShot::PermissionResolver.logger.error("User [#{self.target_user}] does not exist: #{ex.message}")
      return false
    end

    # is the target's current group correct
    def valid_group?
      unless self.target_group.nil?
        if self.target_group.is_a? String
          !!(self.target_group == self.group)
        else
          !!(self.target_group == self.group(:id))
        end
      else
        # The group is OK if it wasn't specified
        return true
      end
    rescue ArgumentError => ex
      # The group is NOT OK if the group doesn't exist
      WarningShot::PermissionResolver.logger.error("Group [#{self.target_group}] does not exist: #{ex.message}")
      return false
    end

    # is the target's current mode correct
    def valid_mode?
      unless self.target_mode.nil?
        !!(self.mode == self.target_mode)
      else
        return true
      end
    end
  end

  typecast Hash do |yaml|
    PermissionResource.new  File.expand_path(yaml[:target]),
                            yaml[:mode],
                            yaml[:user],
                            yaml[:group],
                            yaml[:recursive],
                            yaml[:no_follow]
  end

  #Symlinks, directories and files are sometimes plain strings, these cant be resolved
  # as far as permissions go, but should at least be cast properly
  typecast(String){|target| PermissionResource.new File.expand_path(target), nil, nil, nil, nil, nil }

  register :test do |resource|
    _valid = resource.exists?

    if _valid && resource.permissions_supplied?
      _valid &= resource.valid_user?
      _valid &= resource.valid_group?
      _valid &= resource.valid_mode?

      if _valid
        logger.debug " ~ [PASSED] permission: #{resource.target}"
      else
        logger.warn " ~ [FAILED] permission: #{resource.target}"
      end
    else
      logger.debug " ~ [N/A] no permissions supplied: #{resource.target}"
    end

    _valid
  end

  register :resolution do |resource|
    resource.change_user! unless resource.valid_user?
    resource.change_group! unless resource.valid_group?
    resource.change_mode! unless resource.valid_mode?

    resource.permissions_correct?
  end
end