require 'uri'
require 'net/http'
require 'net/https'

module WarningShot
  class UrlResolver
    include WarningShot::Resolver
    order  900
    #disable!

    branch :url
    description 'Validates that URLs are reachable.'
    
    cli(
      :long         => "--strict",
      :description  => "Success is only for 200 instead of 2xx|3xx",
      :name         => "url_strict",
      :default      => false
    )
    
    cli(
      :long         => "--rootcert",
      :description  => "Path to root ca certificate",
      :name         => "root_ca",
      :default      => nil
    )
    
    cli(
      :long         => "--vdepth",
      :description  => "SSL Verify Peer Depth",
      :name         => "ssl_verify_depth",
      :default      => 5
    )
    
    UrlResource = Struct.new(:uri)
    cast do |dep|
      UrlResource.new URI.parse(dep)
    end
    
    register :test do |dep|
      begin
        http = Net::HTTP.new(dep.uri.host,dep.uri.port)
        
        if dep.uri.scheme == 'https'
          http.use_ssl = true

          if WarningShot::Config.configuration[:root_ca] && File.exist?(WarningShot::Config.configuration[:root_ca])
            http.ca_file = WarningShot::Config.configuration[:root_ca]
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
            http.verify_depth = WarningShot::Config.configuration[:ssl_verify_depth]
          else
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
        end
        
        dep.uri.path = '/' if dep.uri.path.empty?
        resp = http.head(dep.uri.path)

        valid_codes = WarningShot::Config.configuration[:url_strict] ? /200/ : /^[23][0-9][0-9]$/
        
        page_found = (resp.code =~ valid_codes)
        
        if page_found
          logger.debug " ~ [PASSED] url #{dep.uri.to_s}"
        else
          logger.warn " ~ [FAILED] url #{dep.uri.to_s}"
        end
        
        page_found
      rescue Exception
        logger.error "Could not reach #{dep.uri.to_s}"
        false
      end
    end
  end
end
