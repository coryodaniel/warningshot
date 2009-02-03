# Tests and Heals File Dependencies
#
# @notes
#   source is were the file can be resolved FROM
#   target is were the file should exist
class WarningShot::FileResolver
  include WarningShot::Resolver
  
  add_dependency :core, 'fileutils'
  add_dependency :core, 'uri'
  add_dependency :core, 'net/http',   :disable => false, :unregister => [:http_protocol_resolver]
  add_dependency :core, 'net/https',  :disable => false, :unregister => [:https_protocol_resolver]
  
  order  500

  branch :file
  description 'Validates presence of files'

  # Define FileResource struct
  FileResource = Struct.new(:source,:target) do
    def exists?;File.exists?(File.expand_path(target.path));end;
    def remove;File.unlink(File.expand_path(target.path));end;
  end
    
  typecast String do |file|
    FileResource.new URI.parse(''), URI.parse(file)
  end
  
  typecast Hash do |file|
    file[:source].sub!(/file:\/\//i,'') unless file[:source].nil?
    FileResource.new URI.parse(file[:source] || ''), URI.parse(file[:target])
  end
    
  register :test, {:name => :file_test} do |file|
    if file_found = file.exists?
      logger.debug " ~ [PASSED] file: #{file.target.path}"
    else
      logger.warn " ~ [FAILED] file: #{file.target.path}"
    end

    file_found
  end
  
  # Resolve files from target sources
  # @notes
  #   :if matches FILE_PROTOCOL or uri.scheme == nil
  register(:resolution, { :name => :file_protocol_resolver,
    :desc => "Resolves files via local filesystem",
    :if => lambda { |file| 
      !!(file.source.scheme =~ /file/i || file.source.scheme == nil && !file.source.path.empty?)
    }
  }) do |file|    
    begin
      FileUtils.cp File.expand_path(file.source.path), File.expand_path(file.target.path)
    rescue Exception => ex
      logger.error " ~ Could not restore file (#{file.target.path}) from #{file.source.path}"
    end
    file.exists?
  end
  
  register(:resolution, { :name => :http_protocol_resolver,
    :desc => "Resolves files via HTTP",
    :if => lambda { |file| !!(file.source.to_s =~ /http/i)}
  }) do |file|
    begin
      http = Net::HTTP.new(file.source.host,file.source.port)
      file.source.path = '/' if file.source.path.empty?
      resp = http.get(file.source.path)

      File.open(file.target.path,"w+"){ |fs| fs.puts resp.body }  if resp.code == "200"
    rescue Exception => ex  
      logger.error " ~ Could not restore file (#{file.target.path}) from #{file.source.path}"
    end
    file.exists?
  end

  register(:resolution, { :name => :https_protocol_resolver,
    :desc => "Resolves files via HTTPS",
    :if => lambda { |file| !!(file.source.to_s =~ /https/i)}
  }) do |file|
    begin
      http = Net::HTTP.new(file.source.host,file.source.port)
      http.use_ssl = (file.source.scheme == 'https')
      file.source.path = '/' if file.source.path.empty?
      resp = http.get(file.source.path)

      File.open(file.target.path,"w+"){ |fs| fs.puts resp.body }  if resp.code == "200"
    rescue Exception => ex  
      logger.error " ~ Could not restore file (#{file.target.path}) from #{file.source.path}"
    end
    file.exists?
  end
  
=begin  
  register(:resolution, {:name => :scp_protocol,
    :desc => "Resolves files over SSH",
    :if => lambda {|file| }
  }){raise Exception, ' ~ SCP is not supported yet.'}
  
  register(:resolution, {:name => :ftp_protocol,
    :desc => "Resolves files over FTP",
    :if => lambda {|file| }
  }){raise Exception, ' ~ FTP is not supported yet.'}
=end
end