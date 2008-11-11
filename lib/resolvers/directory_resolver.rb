class WarningShot::DirectoryResolver
  include WarningShot::Resolver
  order       100
  branch      :directory
  
  description 'Validates presence of directories'
      
  DirectoryResource = Struct.new(:path)  
  typecast do |path|
    DirectoryResource.new File.expand_path(path)
  end
  
  register :test do |dep|
    dir_found = File.directory? dep.path
    if dir_found
      logger.debug " ~ [PASSED] directory: #{dep.path}"
    else
      logger.warn " ~ [FAILED] directory: #{dep.path}"
    end
    
    dir_found
  end
  
  register :resolution do |dep|
    begin
      FileUtils.mkdir_p dep.path
    rescue Exception => ex
      logger.error " ~ Could not create directory #{dep.path}"
    end
  end
end