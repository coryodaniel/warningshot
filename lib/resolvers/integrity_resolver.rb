class WarningShot::IntegrityResolver
  include WarningShot::Resolver
  add_dependency :core, 'digest/md5',   :disable => false, :unregister => [:md5_digest_test]
  add_dependency :core, 'digest/sha1',  :disable => false, :unregister => [:sha1_digest_test]
  
  order  600
  
  # Uses the same config files as file resolver, just add md5 field to config YML
  branch :file
  description 'Check file integrity via md5 or sha1 digest'
  
  # Define FileResource struct
  FileResource = Struct.new(:source,:target,:digest,:digest_method) do
    def exists?;File.exists?(File.expand_path(target.path));end;
  end
    
  typecast String do |file|
    FileResource.new URI.parse(''), URI.parse(file), nil, nil
  end
  
  typecast Hash do |file|
    file[:source].sub!(/file:\/\//i,'') unless file[:source].nil?
    
    if file[:sha1] && file[:md5]
      digest, digest_method = nil, nil
    elsif file[:sha1]
      digest, digest_method = file[:sha1], :sha1
    elsif file[:md5]
      digest, digest_method = file[:md5], :md5
    end
    
    FileResource.new URI.parse(file[:source] || ''), URI.parse(file[:target]), digest, digest_method
  end
  
  register(:test,{:name=>:sha1_digest_test,
    :if => lambda{|dep| dep.digest_method == :sha1}
  })do |dep|
    dep_ok = (dep.exists? ? Digest::SHA1.hexdigest(File.read(File.expand_path(dep.target.path))) == dep.digest : false)
    
    if dep_ok
      logger.debug "[PASSED] Valid checksum #{dep.target}"
    else
      logger.warn "[FAILED] Invalid checksum #{dep.target}"
    end
    
    dep_ok
  end
  
  register(:test,{:name=>:md5_digest_test,
    :if => lambda{|dep| dep.digest_method == :md5}
  })do |dep|
    dep_ok = (dep.exists? ? Digest::MD5.hexdigest(File.read(File.expand_path(dep.target.path))) == dep.digest : false)

    if dep_ok
      logger.debug "[PASSED] Valid checksum #{dep.target}"
    else
      logger.warn "[FAILED] Invalid checksum #{dep.target}"
    end
    
    dep_ok
  end
  
  register :test,{:name=>:no_digest,
    :if => lambda{|dep| dep.digest_method == nil}
  } do |dep|
    true
  end
end
