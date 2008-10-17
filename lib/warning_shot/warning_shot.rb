module WarningShot
  BeforeCallbacks= []
  AfterCallbacks   = []
  
  PATHS       = {
    :templates  => 'templates',
    :images     => 'images',
    :resolvers => File.join('lib','warning_shot','resolvers')
  }
  
  ConfigExt = "*.{yml,yaml}".freeze
  
  class << self
    def root
      File.join(File.expand_path(File.dirname(__FILE__)),"..","..")
    end
    
    # Gets the absolute path for a resource.
    # if it is not listed in PATHS then the string is appended to
    # WarningShot.root
    #
    # @param dir [Symbol]
    #   directory to look up
    # @returns [String]
    #   absolute path to resource
    #
    # @api public
    def dir_for(dir)
      dir = PATHS[dir.to_sym] || dir.to_s
      File.join(WarningShot.root,dir)
    end
    
    def platform;end;
    
    def environment
      WarningShot::Config.configuration[:environment]
    end
    
    def parser
      @opt_parser ||= OptionParser.new
    end
    
    def before_run(&block)
      BeforeCallbacks << block if block_given?
    end
    
    def after_run(&block)
      AfterCallbacks << block if block_given?      
    end
    
    def logger
      if @logger.nil?
        @logger = Logger.new STDOUT
        @logger.level = Logger::DEBUG
        @logger.formatter = WarningShot::LoggerFormatter.new
      end
      @logger
    end
    
    def fire!
      ws_dr = DependencyResolver.new WarningShot::Config.configuration
      ws_dr.run
      ws_dr
    end
    alias :run :fire!
    
  end
end