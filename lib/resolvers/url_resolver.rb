module WarningShot
  class UrlResolver
    include WarningShot::Resolver
    add_dependency :core, 'uri'
    add_dependency :core, 'net/http'
    add_dependency :core, 'net/https'
    
    order  900

    branch :url
    description 'Validates that URLs are reachable.'
    
    cli("--strict", "Success is only for 200 instead of 2xx|3xx") do |val|
      options[:url_strict] = val
    end
    
    cli("--rootcert", "Path to root ca certificate") do |val|
      options[:root_ca] = val
    end
    
    cli("--vdepth", "SSL Verify Peer Depth") do |val|
      options[:ssl_verify_depth] = val
    end
            
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
