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
    
    # Determines if link points at correct file
    def correct?
      File.identical? self.source, self.target
    end
      
  end

  cast String do |yaml|
    SymlinkResource.new File.expand_path(yaml), nil, false
  end

  cast Hash do |yaml|
    use_force = yaml[:force].nil? ? true : yaml[:force]
    _src = File.expand_path yaml[:source]
    _trg = File.expand_path yaml[:target]
    SymlinkResource.new _src, _trg, use_force
  end
  
  # If the target wasn't specified, it doesn't exist
  register :test do |dep| 
    if symlink_correct = dep.exists? && dep.correct?
      logger.debug " ~ [PASSED] symlink #{dep.target}"
    else
      logger.warn " ~ [FAILED] symlink #{dep.target}"
    end
    symlink_correct
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