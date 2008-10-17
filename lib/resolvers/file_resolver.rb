require 'fileutils'
require 'uri'
require 'net/http'
require 'net/https'

# Tests and Heals File Dependencies
#
# @notes
#   source is were the file can be resolved FROM
#   target is were the file should exist
class WarningShot::FileResolver
  include WarningShot::Resolver
  order  500

  branch :file
  description 'Validates presence of files'
  
  class WarningShot::FileResolver::UnsupportedProtocolException < Exception;end;

  # Define FileResource struct
  FileResource = Struct.new(:source,:target) do
    def exists?;File.exists?(target.path);end;
    def remove;File.unlink(target.path);end;
  end
    
  cast String do |file|
    FileResource.new URI.parse(''), URI.parse(file)
  end
  
  cast Hash do |file|
    file[:source].sub!(/file:\/\//i,'') unless file[:source].nil?
    FileResource.new URI.parse(file[:source] || ''), URI.parse(file[:target])
  end
    
  register :test, {:name => :file_check} do |file|
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
  register(:resolution, { :name => :file_protocol,
    :desc => "Resolves files from target sources",
    :if => lambda { |file| 
      !!(file.source.scheme =~ /file/i || file.source.scheme == nil)
    }
  }) do |file|    
    begin
      FileUtils.cp file.source.path, file.target.path
    rescue Exception => ex
      logger.error " ~ Could not restore file (#{file.target.path}) from #{file.source.path}"
    end
    file.exists?
  end
  
  register(:resolution, { :name => :http_protocol,
    :desc => "Resolves files from HTTP sources",
    :if => lambda { |file| !!(file.source.to_s =~ /http(s)?/i)}
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
  }){raise UnsupportedProtocolException, ' ~ SCP is not supported yet.'}
  
  register(:resolution, {:name => :ftp_protocol,
    :desc => "Resolves files over FTP",
    :if => lambda {|file| }
  }){raise UnsupportedProtocolException, ' ~ FTP is not supported yet.'}
=end
end