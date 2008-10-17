class WarningShot::SymlinkResolver
  include WarningShot::Resolver

  order       50
  branch      :symlink
  description 'Validates symlinks exist'
       
  SymlinkResource = Struct.new(:source,:target,:force) do
    def link!;FileUtils.ln_s(self.source,self.target,:force=>self.force);end;
    
    def exists?
      self.target ? File.symlink?(self.target) : false
    end
  end

  cast String do |yaml|
    SymlinkResource.new yaml, nil, false
  end

  cast Hash do |yaml|
    use_force = yaml[:force].nil? ? true : yaml[:force]
    SymlinkResource.new yaml[:source],yaml[:target], use_force
  end
  
  # If the target wasn't specified, it doesn't exist
  register :test do |dep| 
    if symlink_found = dep.exists?
      logger.debug " ~ [PASSED] symlink #{dep.target}"
    else
      logger.warn " ~ [FAILED] symlink #{dep.target}"
    end
    symlink_found
  end

  register :resolution do |dep|
    begin
      dep.link! if dep.target
    rescue Errno::EEXIST, Errno::ENOTDIR => ex
      logger.error " ~ Could not create symlink #{dep.source} => #{dep.target}"
    end
    dep.exists?
  end
end