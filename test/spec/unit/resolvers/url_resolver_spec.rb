require '.' / 'lib' / 'resolvers' / 'url_resolver'

describe WarningShot::UrlResolver do
  before :all do    
    WarningShot::UrlResolver.logger = $logger 
  end

  it 'should have tests registered' do
    WarningShot::UrlResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::UrlResolver.resolutions.empty?.should be(true)
  end

  it 'should extend the command line interface' do
    WarningShot.parser.to_s.include?("Success is only for 200 instead of 2xx").should be(true)    
    WarningShot.parser.to_s.include?("SSL Verify Peer Depth").should be(true)    
    WarningShot.parser.to_s.include?("Path to root ca certificate").should be(true)    
  end

  it 'should be able to determine if an http address is reachable' do
    resolver = WarningShot::UrlResolver.new WarningShot::Config.new,"http://example.com"
    resolver.test!
    resolver.failed.length.should be(0)
  end
  
  it 'should be able to determine if an https address is reachable' do
    #Yeah, what https page to use, huh?
    resolver = WarningShot::UrlResolver.new WarningShot::Config.new,"https://www.google.com/analytics/home/"
    resolver.test!
    resolver.failed.length.should be(0)
  end
  
  it 'should be able to determine if an http address is unreachable' do
    resolver = WarningShot::UrlResolver.new WarningShot::Config.new, "http://example.com", "http://127.0.0.1:31337"
    resolver.test!
    resolver.failed.length.should be(1)
    resolver.passed.length.should be(1)
  end
  
  it 'should be able to determine if an https address is unreachable' do
    resolver = WarningShot::UrlResolver.new WarningShot::Config.new,"https://www.google.com/analytics/home/", "https://127.0.0.1:31337"
    resolver.test!
    resolver.failed.length.should be(1)
    resolver.passed.length.should be(1)
  end
    
  it 'should be able to receive --strict from the command line' do
    config = WarningShot::Config.new({:url_strict=>true})
    config[:url_strict].should be(true)
    
    #google redirects, ever heard of no-www.org?
    resolver = WarningShot::UrlResolver.new config, "http://example.com","http://google.com"

    resolver.test!
    resolver.failed.length.should be(1)
    resolver.passed.length.should be(1)
  end
  
  it 'should be able to verify CA certificate and peer' do
    pending
  end
end