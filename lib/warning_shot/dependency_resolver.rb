# Auto-generated ruby debug require       
require "ruby-debug"
Debugger.start
Debugger.settings[:autoeval] = true if Debugger.respond_to?(:settings)

# TODO callbacks, casting, conditional test, test, resolve, etc        

module WarningShot
  class DependencyResolver
    
    attr_reader :environment, :dependency_tree
    def initialize(config={},&block)
      @config = config
      @environment = @config[:environment].to_sym
        
      # Parsed yml files
      @dependency_tree = {}
      self.load_configs
      @dependency_tree.symbolize_keys!
      
      @resolvers = []
    end
    
    def run
      WarningShot::BeforeCallbacks.each {|b| b.call(self)}

      WarningShot::Resolver.descendents.each do |klass|
        branch = @dependency_tree[klass.branch.to_sym]

        if branch.nil?
          WarningShot.logger.info "No config file was found for branch #{klass.branch}"
          next
        end

        resolver = klass.new(*branch)
        @resolvers << resolver
        WarningShot.logger.info "Testing branch #{klass.branch} w/ #{resolver.class}"
                
        # Start test
        resolver.test!
        WarningShot.logger.info "Passed: #{resolver.passed.size}"
        WarningShot.logger.info "Failed: #{resolver.failed.size}"

        if WarningShot::Config.configuration[:resolve] && !klass.resolutions.empty?
          WarningShot.logger.info "Resolving branch #{klass.branch} w/ #{resolver.class}"
          resolver.resolve! 
          WarningShot.logger.info "Resolved: #{resolver.resolved.size}"
          WarningShot.logger.info "Unresolved: #{resolver.unresolved.size}"
        end
        
        WarningShot.logger.info "*" * 60
      end

      WarningShot::AfterCallbacks.each {|b| b.call(self)}
    end
    
    protected
    # Loads configuration files
    #
    # @api protected
    def load_configs
      @config[:config_paths].each do |config_path|
        #Parse the global/running env configs out of the YAML files.
        Dir[File.join(config_path,WarningShot::ConfigExt)].each do |config_file|
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