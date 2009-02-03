require File.dirname(__FILE__) / 'config' 
require File.dirname(__FILE__) / 'resolver' 
require File.dirname(__FILE__) / 'dependency_resolver' 

module WarningShot
  BeforeCallbacks   = []
  AfterCallbacks    = []
  ApplicationTypes  = {}
  
  # Relative paths from WarningShot.root
  PATHS       = {
    :templates  => 'templates',
    :images     => 'images',
    :resolvers  => 'lib' / 'resolvers'
  }

  RecipeExt = "*.{yml,yaml}".freeze
  
  class << self
    def register_application_type(type,&block)
      ApplicationTypes[type] = block
    end
    
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
      when /linux/i: :linux
      when /darwin/i: :mac
      when /mswin|windows/i: :windows
      when /sunos|solaris/i: :solaris
      else
        :unknown
      end
    end
    
    # the application type warningshot is running in
    #   uses constants to determine
    # Additional application types can be registered with
    #   WarningShot.register_application_type
    #
    # @return [Symbol] Name of framework/application type
    # @api public
    def application_type
      ApplicationTypes.each do |type,block| 
        @@application_type = type if block.call
      end if (@@application_type ||=nil).nil?
      
      @@application_type
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
    # @param config [WarningShot::Config]
    #
    # @return WarningShot::DependencyResolver
    #   a processed dependency resolver   
    #
    # @api public
    def fire!(config=nil)
      config ||= WarningShot::Config.create

      ws_dr = DependencyResolver.new config
      
      BeforeCallbacks.each {|p| p.call }
      ws_dr.run
      AfterCallbacks.each {|p| p.call }
      
      ws_dr
    end
    alias :run :fire!
    
    # loads only specified resolvers
    # 
    # @param *params [Array[~to_s]]
    #   list of resolvers to load
    #
    # @note
    # this is equivalent to:
    #   require 'warningshot'
    #   require 'warningshot/../resolvers/each_resolver_listed'
    # 
    # all add'l resolvers will be loaded still (not sure if this is good or bad)
    # @see WarningShot.load_addl_resolvers
    # 
    def only_load(*params)
      params.each{ |f| require WarningShot.dir_for(:resolvers) / "#{f}_resolver" }
    end
    
    # loads only specified resolvers
    # 
    # @param *params [Array[~to_s]]
    #   list of resolvers to load
    #
    # @note
    # this is equivalent to:
    #   require 'warningshot'
    #   require 'warningshot/../resolvers/each_resolver_listed'
    #   WarningShot::EachResolverListed.order(sequential_number)
    # 
    # all add'l resolvers will be loaded still (not sure if this is good or bad)
    #
    # @see WarningShot.load_addl_resolvers
    #
    def priority_load(*params)
      params.each_with_index do |f,idx|
        _resolver_name = "#{f}_resolver"
        require WarningShot.dir_for(:resolvers) / _resolver_name
        klass_name = _resolver_name.downcase.split('_').inject([]){|memo,part| memo << part.capitalize}.join('')
        const_get(klass_name).order(idx)
      end
    end

    def header
      "WarningShot v. #{WarningShot::VERSION}"
    end

    # returns names of all loaded resolvers in priority order
    #
    # @see WarningShot::Resolver.descendants
    #
    # @return [Array[String]]
    #   Name of loaded resolvers
    #
    def resolvers
      WarningShot::Resolver.descendants.sort_by{|d|d.order}.inject([]){|a,klass| a << klass.name}
    end
    

    # Changes the working directory to that of the application
    #   Default application is '.'
    def load_app(app)
      Dir.chdir app
    end

    # Loads any additional resolvers specified by --resolvers= or self[:resolvers]
    def load_addl_resolvers(resolver_paths)
      resolver_paths.each do |resolver_path|
        Dir[File.expand_path(resolver_path)].each {|r| load r}
      end
    end
  end
end

WarningShot.register_application_type(:merb){ !!defined?(Merb) }
WarningShot.register_application_type(:rails){ !!defined?(RAILS_ROOT) }
WarningShot.register_application_type(:console){true}
