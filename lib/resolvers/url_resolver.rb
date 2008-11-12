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
    
    typecast{ |dep| URI.parse(dep) }
    
    register :test do |uri,config|
      begin
        http = Net::HTTP.new(uri.host,uri.port)
        
        if uri.scheme == 'https'
          http.use_ssl = true

          if config[:root_ca] && File.exist?(config[:root_ca])
            http.ca_file = config[:root_ca]
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
            http.verify_depth = config[:ssl_verify_depth]
          else
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
        end
        
        uri.path = '/' if uri.path.empty?
        resp = http.head(uri.path)

        valid_codes = config[:url_strict] ? /200/ : /^[23][0-9][0-9]$/
        
        page_found = (resp.code =~ valid_codes)

        if page_found
          logger.debug " ~ [PASSED] url #{uri.to_s}"
        else
          logger.warn " ~ [FAILED] url #{uri.to_s}"
        end
        
        page_found
      rescue Exception => ex
        logger.error "Could not reach #{uri.to_s}"
        false
      end
    end
  end
end
