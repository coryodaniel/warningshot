module WarningShot
  BeforeCallbacks= []
  AfterCallbacks   = []
  
  PATHS       = {
    :templates  => 'templates',
    :images     => 'images',
    :resolvers  => 'lib' / 'warning_shot' / 'resolvers'
  }
  
  ConfigExt = "*.{yml,yaml}".freeze
  
  class << self
    def root
      File.expand_path(File.dirname(__FILE__)) / ".." / ".."
    end
    
    def hostname
      `hostname`.strip
    end
    
    # Gets the absolute path for a resource.
    # if it is not listed in PATHS then the string is appended to
    # WarningShot.root
    #
    # @param dir [Symbol]
    #   directory to look up
    #
    # @return [String]
    #   absolute path to resource
    #
    # @api public
    def dir_for(dir)
      dir = PATHS[dir.to_sym] || dir.to_s
      WarningShot.root / dir
    end
    
    def platform
      case ::Config::CONFIG['host_os']
      when /darwin/i: :mac
      when /mswin|windows/i: :windows
      when /linux/i: :linux
      when /sunos|solaris/i: :solaris
      else
        :unknown
      end
    end
    
    # the application/framework warningshot is running in
    #   uses constants to determine
    #
    # @return [String] Name of framework/application
    # @api public
    def framework
      if defined?(RAILS_ROOT)
        return "RAILS"
      elsif defined?(Merb)
        return "MERB"
      else
        return "CONSOLE"
      end
    end
    
    # shortcut to current environment
    #
    # @return [String] name of the environment
    # @api public
    def environment
      WarningShot::Config.configuration[:environment]
    end
    
    # Parser used to parse Config hash
    #
    # @api private
    def parser
      @opt_parser ||= OptionParser.new
    end
    
    # register a callback to be run before starting 
    #   the dependency resolver
    # @param block [Proc]
    #   the before filter
    # @api public
    def before(&block)
      BeforeCallbacks << block if block_given?
    end
    
    # register a callback to be run after starting 
    #   the dependency resolver
    # @param block [Proc]
    #   the after filter
    # @api public
    def after(&block)
      AfterCallbacks << block if block_given?      
    end
        
    # creates and runs a new dependency resolver
    #
    # @return WarningShot::DependencyResolver
    #   a processed dependency resolver   
    #
    # @api public
    def fire!
      WarningShot.load_app
      WarningShot.load_addl_resolvers
      ws_dr = DependencyResolver.new WarningShot::Config.configuration
      BeforeCallbacks.each {|p| p.call }
      ws_dr.run
      AfterCallbacks.each {|p| p.call }
      
      ws_dr
    end
    alias :run :fire!
    
    # Changes the working directory to that of the application
    #   Default application is '.'
    def load_app
      Dir.chdir(WarningShot::Config[:application])
    end
    
    # Loads any additional resolvers specified by --resolvers= or WarningShot::Config[:resolvers]
    #   defaults to ~/.warningshot/*.rb
    def load_addl_resolvers
      WarningShot::Config[:resolvers].each do |resolver_path|
        Dir[File.expand_path(resolver_path)].each {|r| load r}
      end
    end
    
  end
end