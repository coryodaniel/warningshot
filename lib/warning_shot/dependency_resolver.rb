module WarningShot
  class DependencyResolver
    
    attr_reader :environment, :dependency_tree, :resolvers
    def initialize(config={})
      @config           = config
      @environment      = @config[:environment].to_sym
      @dependency_tree  = {}
      @resolvers        = []
        
      init_logger
            
      # Parsed yml files
      self.load_configs
      @dependency_tree.symbolize_keys!
    end
    
    # gets stats of all resolvers
    # @return [Hash] 
    #   :passed, :failed, :resolved, :unresolved
    #
    # @api public
    def stats
      _stats = {
        :passed => 0, :failed => 0, :resolved => 0, :unresolved => 0
      }
      
      resolvers.each do |resolver|
        _stats[:passed]     += resolver.passed.size
        _stats[:failed]     += resolver.failed.size
        _stats[:resolved]   += resolver.resolved.size
        _stats[:unresolved] += resolver.unresolved.size
      end
      
      _stats
    end
    
    # initializes the logger
    # 
    # @api private
    def init_logger
      FileUtils.mkdir_p(File.dirname(File.expand_path(@config[:log_path]))) unless @config[:verbose]
      
      @logger = Logger.new(
        @config[:verbose] ? STDOUT : @config[:log_path], 10, 1024000
      )
      _log_level = (@config[:log_level] || :debug).to_s.upcase

      _formatter = WarningShot::LoggerFormatter.new
      _formatter.colorize = @config[:colorize]

      @logger.formatter = _formatter
      @logger.level     = Object.class_eval("Logger::#{_log_level}")
    end
    
    # runs all loaded resolvers
    #
    # @api private
    def run
      @logger.info "WarningShot v. #{WarningShot::VERSION}"
      @logger.info "Environment: #{@environment}; Application: #{WarningShot.framework}"
      
      WarningShot::Resolver.descendents.each do |klass|
        @logger.info "\n#{'*'*60}"

        branch = @dependency_tree[klass.branch.to_sym]

        if branch.nil?
          @logger.info "No config file was found for branch #{klass.branch}"
          next
        end
        
        klass.logger = @logger
        resolver = klass.new(*branch)

        @resolvers << resolver
        
        @logger.info "Testing branch #{klass.branch} w/ #{resolver.class}"
                
        # Start test
        klass.before_filters(:test).each{|p| p.call}
        resolver.test!
        klass.after_filters(:test).each{|p| p.call}
        
        @logger.info "Passed: #{resolver.passed.size}"
        @logger.info "Failed: #{resolver.failed.size}"

        if WarningShot::Config.configuration[:resolve] && !klass.resolutions.empty?
          @logger.info "Resolving branch #{klass.branch} w/ #{resolver.class}"

          klass.before_filters(:resolution).each{|p| p.call}
          resolver.resolve! 
          klass.after_filters(:resolution).each{|p| p.call}
          
          @logger.info "Resolved: #{resolver.resolved.size}"
          @logger.info "Unresolved: #{resolver.unresolved.size}"
        end
      end
    end
    
    protected
    # Loads configuration files
    #
    # @api protected
    def load_configs
      @config[:config_paths].each do |config_path|
        #Parse the global/running env configs out of the YAML files.
        Dir[config_path / WarningShot::ConfigExt].each do |config_file|
          # Use WarningShot::ConfigExt & regexp on extension to make supporting add'l
          # file types easier in the future
          case File.extname(config_file)
          when /.y(a)?ml/
            parse_yml config_file
          end
        end
      end
    end
    
    # parses dependencies info from a yaml file
    #
    # @param file [String]
    #   File path to parse
    #
    # @notes
    #   yaml file should contain an array of configs, 
    #     get name of each config set, find global and current environment
    #     from set, merge into dependency_tree
    #
    # @api protected
    def parse_yml(file)
      #if only on branch is specified in a yaml file it may not come back as an array
      branches  = YAML::load(File.open(file,'r'))
      branches = [branches] unless branches.is_a? Array
      
      branches.each do |branch|
        branch_name = branch[:branch]
        dependency_tree[branch_name] ||= []

        #Add current environment's configs to branch
        current_env = branch[:environments][@environment]
        @dependency_tree[branch_name].concat(current_env) unless current_env.nil?
        
        #Add global environment's configs to branch
        global = branch[:environments][:global]
        @dependency_tree[branch_name].concat(global) unless global.nil?
        
        #remove nil's if they made it into branch somehow (bad yaml probably)
        @dependency_tree[branch_name].delete(nil)
      end
    end
    
  end
end