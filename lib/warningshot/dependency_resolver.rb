require File.dirname(__FILE__) / 'warning_shot' 
require File.dirname(__FILE__) / 'resolver' 
require File.dirname(__FILE__) / 'config'
require File.dirname(__FILE__) / 'logger'  

module WarningShot
  class DependencyResolver
    LINE_LENGTH = 71
    attr_reader :environment, :dependency_tree, :resolvers
    def initialize(config={})
      @config           = config
      @environment      = @config[:environment].to_sym
      @dependency_tree  = {}
      @resolvers        = []
        
      # set up logger
      @logger           = WarningShot::Logger.new(self[:log_path],10,1024000)
      @logger.formatter = WarningShot::LoggerFormatter.new
      @logger.level     = (self[:log_level] || :info).to_s.upcase
      @logger.verbosity = self[:verbosity]

      # Move to app dir, load add'l resolvers
      WarningShot.load_app(self[:application])
      WarningShot.load_addl_resolvers(self[:resolvers])

      # Parsed yml files
      self.load_configs
      @logger.debug "Dependencies were found for: #{@dependency_tree.keys.join(', ')}"
      
      @dependency_tree.symbolize_keys!
    end

    # config accessor; shortcut for @config
    def [](k)
      @config[k]
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

    

    # runs all loaded resolvers
    #
    # @api private
    def run
      @logger.info "WarningShot v. #{WarningShot::VERSION}"
      @logger.info "Environment: #{self.environment}; Application: #{WarningShot.application_type}"
      @logger.info "On host: #{WarningShot.hostname}"
      @logger.display_stdout_queue

      @logger.display "\n#{'-'*LINE_LENGTH}"
      @logger.display line_item('RESOLVER','BRANCH','MODE',"%% COMPLETE",'RESULTS')
      @logger.display "#{'-'*LINE_LENGTH}"
      
      WarningShot::Resolver.descendants.each do |klass|
        next if klass.disabled?        
        klass.logger = @logger

        #Process each branch for the Resolver Class (klass)
        klass.branch.each do |branch_name|
          branch = @dependency_tree[branch_name.to_sym]

          if branch.nil?
            klass.logger.warn "Skipping #{klass.demodulized_name}, #{branch_name}; No recipes were registered"
            next
          elsif branch.empty?
            klass.logger.warn "Skipping #{klass.demodulized_name}, #{branch_name}; No dependencies in recipe"
            next
          end

          @resolvers << klass.new(@config,branch_name.to_sym,*branch)
          run_tests(@resolvers.last)
          run_resolutions(@resolvers.last) if self[:resolve] && !klass.resolutions.empty?

          generate_results(@resolvers.last)
        end #Branch Loop

      end #Resolver Class Loop
      
      @logger.display "#{'-'*LINE_LENGTH}"
      @logger.info "Results: (See log for details: #{self[:log_path]})"
      pct_passed = ((stats[:passed] / (stats[:passed] + stats[:failed]).to_f) * 100).ceil
      @logger.info "> #{pct_passed}% of dependencies met"
      
      if self[:resolve]
        @logger.info("> " + stats[:resolved].to_s.green + " dependencies resolved.") if stats[:resolved] > 0
        @logger.info("> " + stats[:unresolved].to_s.red + " dependencies " + "not".red + " resolved") if stats[:unresolved] > 0
      end
      
      @logger.display_stdout_queue
    end

    protected
    
    #run all tests for a resolver
    def run_tests(resolver)
      @logger.update line_item(resolver.class.demodulized_name, resolver.current_branch,'TESTING','0','-')
      
      resolver.class.before_filters(:test).each{|p| p.call}
      resolver.test!{|pct|          
        @logger.update line_item(resolver.class.demodulized_name, resolver.current_branch,'TESTING',pct.to_s,'-')
      }
      resolver.class.after_filters(:test).each{|p| p.call}
    end
    
    #Run all resolutions for a resolver
    def run_resolutions(resolver)
      @logger.update line_item(resolver.class.demodulized_name, resolver.current_branch,'RESOLVING','0','-')

       resolver.class.before_filters(:resolution).each{|p| p.call}
       resolver.resolve!{|pct|          
         @logger.update line_item(resolver.class.demodulized_name, resolver.current_branch,'RESOLVING',pct.to_s,'-')
       }
       resolver.class.after_filters(:resolution).each{|p| p.call}
    end
    
    #Determines output that should be displayed on screen
    #
    def generate_results(resolver)
      if !self[:resolve] || resolver.class.resolutions.empty?
        _num_failed = resolver.failed.size
        
        @logger.display line_item(resolver.class.demodulized_name, resolver.current_branch,'TESTING','100',"Failed: #{_num_failed}",(_num_failed > 0 ? :red : :green))
      else #resolve and update interface
        _num_unresolved = resolver.unresolved.size
        
        @logger.display line_item(resolver.class.demodulized_name, resolver.current_branch,'RESOLVING','100',"Unresolved: #{_num_unresolved}",(_num_unresolved > 0 ? :red : :green))
      end
    end
    
    # formats output for a console line
    #
    def line_item(c_resolver, c_branch, c_mode, c_complete, c_results,color=:reset)
      '|' + c_resolver.center(20).send(color)     + 
      '|' + c_branch.to_s.center(10).send(color)  + 
      '|' + c_mode.center(10).send(color)         + 
      '|' + c_complete.center(10).send(color)     + 
      '|' + c_results.center(15).send(color)      + '|'
    end
    
    # Loads configuration files
    #
    # @api protected
    def load_configs
      self[:config_paths].each do |config_path|
        @logger.debug "Parsing config: #{config_path}"
        #Parse the global/running env configs out of the YAML files.
        Dir[config_path].each do |config_file|
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
      #if only one branch is specified in a yaml file it may not come back as an array
      branches  = YAML::load(File.open(file,'r'))

      unless branches.is_a?(Array) || branches.is_a?(Hash)
        raise Exception, "Malformed config file: #{file}"
      end

      #Support for multiple dep branches in one file
      branches = [branches] unless branches.is_a? Array

      branches.each do |branch|
        @logger.debug "Parsing branch (#{branch[:branch]}) into dependency tree"
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
    rescue Exception => ex
      @logger.error ex.message
    end

  end
end