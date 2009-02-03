class WarningShot::DirectoryResolver
  include WarningShot::Resolver
  order       100
  branch      :directory
  
  description 'Validates presence of directories'

  DirectoryResource = Struct.new(:target)

  typecast String do |target|
    DirectoryResource.new File.expand_path(target)
  end
  typecast Hash do |yaml|
    DirectoryResource.new File.expand_path(yaml[:target])
  end

  register :test do |dep|
    dir_found = File.directory? dep.target
    if dir_found
      logger.debug " ~ [PASSED] directory: #{dep.target}"
    else
      logger.warn " ~ [FAILED] directory: #{dep.target}"
    end
    
    dir_found
  end
  
  register :resolution do |dep|
    begin
      FileUtils.mkdir_p dep.target
    rescue Exception => ex
      logger.error " ~ Could not create directory #{dep.target}"
    end
  end
end