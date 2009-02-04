class WarningShot::SymlinkResolver
  include WarningShot::Resolver
  add_dependency :core, 'fileutils'

  order       50
  branch      :symlink
  description 'Validates symlinks exist'
       
  SymlinkResource = Struct.new(:source,:target,:force) do
    def link!;FileUtils.ln_s(self.source,self.target,:force=>self.force);end;
    
    #Is the symlink present
    def linked?
      self.target ? File.symlink?(self.target) : false
    end
    
    # Determines if link points at correct file
    def correct?
      !!(File.readlink(self.target) == self.source)
    end
    
    def valid?
      !!(self.linked? && self.correct?)
    end
      
  end

  typecast do |yaml|
    use_force = yaml[:force].nil? ? true : yaml[:force]
    _src = File.expand_path yaml[:source]
    _trg = File.expand_path yaml[:target]
    SymlinkResource.new _src, _trg, use_force
  end
  
  # If the target wasn't specified, it doesn't exist
  register :test do |dep| 
    if symlink_correct = dep.valid?
      logger.debug "[PASSED] Symlink found: #{dep.target}"
    else
      logger.warn "[FAILED] Symlink not found: #{dep.target}"
    end
    symlink_correct
  end

  register :resolution do |dep|
    begin
      dep.link! if dep.target
      logger.debug "[RESOLVED] Symlink created: #{dep.target}"
    rescue Errno::EEXIST, Errno::ENOTDIR => ex
      logger.error "[UNRESOLVED] Symlink not created: #{dep.source} => #{dep.target}"
    end
    dep.valid?
  end
end