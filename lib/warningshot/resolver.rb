require File.dirname(__FILE__) / 'warning_shot' 

# API access for resolvers
#
# @example
#   require 'warningshot'
#   class MyCustomResolver
#     include WarningShot::Resolver
#   end
#
# @api private
module WarningShot
  module Resolver
    module ClassMethods
      def demodulized_name
        self.name.split("::").last
      end
      
      # creates a list of gems that the resolver is dependent on for different features
      #   The goal of this is that WarningShot will not need a bunch of libraries installed unless
      #   the end users needs that specific functionality.  If a corelib/gem is missing the logger will
      #   receive warnings if a particular functionality that needs that library is enabled and its missing
      #   The missing GEMS can be installed with: warningshot --build-deps
      #   All resolvers' dependencies can be viewed with: warningshot --list-deps
      #
      #   Note: add_dependency is essentially a replacement for 'require' when writing Resolvers
      #
      # @param type [Symbol[:core|:gem]]
      #   the type of library it depends on, core lib or gem
      #
      # @param req_name [String]
      #   What would normally go in 'require'
      #
      # @param dep_opts [Hash]
      #   :disable [Boolean] Default: true  
      #       Should the resolver be disabled if the gem is missing
      #   :unregister [Array[Symbol]]       
      #       Test / Resolutions to unregister
      #   :name [String]                
      #       Alternate name to use to install missing gem with warningshot --build-deps
      #       Example: require 'net/scp' would need gem install net-scp
      #   :version [String]
      #       The version to install
      #   :source [String]
      #       Alternate gem source
      #
      def add_dependency(type,req_name,dep_opts={})
        require req_name
        dep_opts[:installed] = true
      rescue LoadError => ex
        self.disable! unless dep_opts[:disable] === false
        dep_opts[:installed] = false        
      ensure
        @dependent_libs ||= {:core => [], :gem => []}

        #if an alternate name isn't specified refer to it by the req_name
        dep_opts[:name] ||= req_name
        @dependent_libs[type].push dep_opts
      end
      
      # list the gems the resolver relies on
      #
      # @return [Hash]
      def depends_on
        @dependent_libs ||= {:core => [], :gem => []}
      end
      
      # provides shortcut to WarningShot::Config.cli_options
      #
      # @see WarningShot::Config
      #
      # @return [Hash]
      #   
      def options
        WarningShot::Config.cli_options
      end

      # provides shortcut to WarningShot::Config.cli
      #
      # @see OptionParser
      # @see WarningShot::Config
      # 
      # @param *opts [Array]
      #
      # @param &block [Proc]
      #
      # @api public
      def cli(*opts,&block)
        return if self.disabled?
        
        WarningShot::Config.cli(*opts, &block)
      end
      
      # Setter/Getter for resolver branch, 
      # used in outputting info and for determine which yaml to apply
      #
      # @param b [~to_s] 
      #   branch in dependency tree to use
      #
      # @return [String]
      #   Resolver's branch
      #
      # @example
      #   class MyResolver
      #     include WarningShot::Resolver
      #     branch :mock
      #     # Alternatively pass a set of branches you want to pull from (see PermissionResolver)
      #     # branch :mock, :faux, :test
      #   end
      #
      # @api public
      def branch(*b)
        @branch = b unless b.empty?
        @branch
      end
      
      # Setter/Getter for resolver description, 
      #
      # @param d [~to_s] 
      # Resolver's description
      #
      # @return [String]
      #   Resolver's description
      #
      # @example
      #   class MyResolver
      #     include WarningShot::Resolver
      #     description 'Mock resolver for rspec testing'
      #   end
      #
      # @api public
      def description(d=nil)
        @description = d unless d.nil?
        @description
      end
        
      # Setter/Getter for resolver order, 
      # determines order in which resolver is checked
      #
      # @param p [Fixnum] (optional; default 100)
      #   Resolver's order, lower the earlier it is run
      #
      # @return [Fixnum]
      #   Resolver's order
      #
      # @example
      #   class MyResolver
      #     include WarningShot::Resolver
      #     order 1 # Would attempt to run this resolver check first
      #     #order 1000
      #   end
      #
      # @api public
      def order(p=nil)
        @order = p unless p.nil?
        @order || 100
      end
      
      # Sets a resolver to disabled mode, won't be processed
      #
      # @example
      #   class MyResolver
      #     include WarningShot::Resolver
      #     disable!
      #   end
      #
      # @api public
      def disable!
        @disabled = true
      end
      
      # enables a resolver (enabled by default)
      #
      # @example
      #   class MyResolver
      #     include WarningShot::Resolver
      #     disable!
      #   end
      #
      #   # Maybe you only want to enable it under some conditions
      #   MyResolver.enabled! if my_merb_or_rails_env == 'production'
      #   MyResolver.enabled! if @pickles.count == @chickens.count
      #
      # @api public
      def enable!
        @disabled = false
      end
      
      # Determines if resolver is disabled
      #
      # @return [Boolean]
      #   is it disabled
      #
      # @api public
      def disabled?
        @disabled ||=false
      end
      
      # Provides resolver access to logger
      #
      # @return [~Logger]
      #   WarningShots logger
      #
      # @api public
      def logger
        @logger || Logger.new(STDOUT)
      end
      
      # Sets
      def logger=(log)
        @logger = log
      end
            
      # Defines how to cast YAML parsed data to an object
      #   the resolver can work with
      #
      # @param klass [Class]
      #   Type of class to perform casting against,
      #     if nil, the method is used on all types not matched
      #
      # @param block [lambda]
      #   How to cast the data to an object
      # 
      # @api public
      def typecast(klass=nil,&block)
        if klass.nil?
          klass = :default
        else
          klass = klass.name.to_sym
        end
        (@yaml_to_object_methods||={})[klass] = block
      end
            
      # calls the block defined by Resolver#typecast to convert
      #   the yaml data to an object
      #
      # @param data [~YAML::load]
      #   The data parsed from YAML::load
      #
      # @return [Object]
      #   The casted objects   
      #
      # @notes
      #   if Resolver#cast was not called, it will just return
      #     the YAML parsed data
      #
      # @api private
      def yaml_to_object(data)       
        @yaml_to_object_methods||={} 
        klass = data.class.name.to_sym

        # if klass has a registered casting method, do it
        if @yaml_to_object_methods.key? klass
          return @yaml_to_object_methods[klass].call(data)
        # elsif there is a regsitered default method, do it.
        elsif @yaml_to_object_methods.key? :default
          return @yaml_to_object_methods[:default].call(data)
        else
        # else return original data
          return data
        end
      end
            
      # Registers a test or resolution block
      #
      # @param type [Symbol]
      #   The type of block being registered :test | :resolution
      #
      # @param meta [Hash]
      #   :name [String] (Optional) 
      #       Name of the test
      #   :desc [String] (Optional) 
      #       Description of the test
      #   :if|:unless [lambda] (Optional)
      #       Block that returns ~boolean determining if the test applies
      #       The block will be passed the current item from config file
      #
      # @param block [lambda]
      #   block should return ~boolean result of resolution attempt
      #   The block will be passed the current item from config file
      #
      # @example
      #   register :test, :name => :awesome_test, :desc => "this is my awesome test" do |dependency|
      #     your_logic_that_tests dependency
      #   end
      #
      #   register :test, :if => lambda { |dependency|
      #     #This condition would determine if test should be run
      #     logic_that_determines_if_test_applies dependency
      #   } do |dependency|
      #     your_logic_that_tests dependency
      #   end
      
      #   register :resolution do |dependency|
      #     #Access to current dependency via dependency
      #     my_method_that_would_resolve dependency
      #   end
      #
      #   register :resolution, :if => lambda{|dependency| 
      #     #This will determin if resolution should be attempted
      #     my_special_instance == true
      #   } do |dependency|
      #       my_method_that_would_resolve dependency
      #   end
      #
      # @api public
      def register(type, meta={}, &block)
        if meta[:if] && meta[:unless]
          raise Exception, ":if and :unless cannot be specified on the same resolution"
        end
        
        @registered_blocks  ||= {:test => [], :resolution => []}
        meta[type] = block

        # If a condition is given add to begining of array, if no condition
        #   add it to end.  This makes it so we dont have to sort later on :if|:unless
        #   to get non-condition resolutions to run last
        
        if meta[:if] || meta[:unless]
          @registered_blocks[type].unshift meta
        else
          @registered_blocks[type] << meta
        end
      end
      
      # Lists current resolver tests
      #
      # @param test_name [Symbol]
      #   find a test by name (if a name was given)
      #
      # @return [Hash|Array]
      #   When name given, returns test Hash
      #   When name not give, returns all test Hashes in an array
      #
      # @api private
      def tests(test_name=nil)
        unless test_name
          @registered_blocks[:test] ||= []
        else
          return @registered_blocks[:test].find do |registered_test|
            registered_test[:name] == test_name
          end
        end
      end
      
      # Lists current resolver resolutions
      #
      # @param resolution_name [Symbol]
      #   find a test by name (if a name was given)
      #
      # @api private
      def resolutions(resolution_name=nil)
        unless resolution_name
          @registered_blocks[:resolution] ||= []
        else
          return @registered_blocks[:resolution].find do |registered_resolution|
            registered_resolution[:name] == resolution_name
          end
        end
      end
      
      # removes all test/resolutions from a resolver
      #
      # @api public
      def flush!
        flush_tests!
        flush_resolutions!
      end
      
      # Removes all tests from a resolver
      #
      # @api public
      def flush_tests!
        @registered_blocks[:test] = []
      end
      
      # Removes all resolutions from a resolver
      #
      # @api public
      def flush_resolutions!
        @registered_blocks[:resolution] = []
      end
      
      # add before filters to test/resolution blocks
      #
      # @param type Symbol
      #   run before :test | :resolution
      # @param block [lambda]
      #   block to run before tests or resolutions
      #
      # @api public
      def before(type,&block)
        @before_filters ||= {:test=>[],:resolution=>[]}
        @before_filters[type] << block
      end
      
      # gets before filters for type
      #
      # @param type [Symbol]
      #   Type of filters to get
      # @return [Array[Proc]] 
      #   Before filters
      # @api private
      def before_filters(type)
        @before_filters ? @before_filters[type] : []
      end
      
      # gets after filters for type
      #
      # @param type [Symbol]
      #   Type of filters to get
      # @return [Array[Proc]] 
      #   after filters
      # @api private
      def after_filters(type)
        @after_filters ? @after_filters[type] : []
      end

      # add after filters to test/resolution blocks
      #
      # @param type Symbol
      #   run after :test | :resolution
      # @param block [lambda]
      #   block to run after tests or resolutions
      #      
      # @api public
      def after(type,&block)
        @after_filters ||= {:test=>[],:resolution=>[]}
        @after_filters[type] << block
      end
      
      # Outputs class static details
      #
      # @return [Array(Object)]
      # @api private
      def details
        [self.name,self.description,self.order,self.disabled?]
      end
    end
    
    module InstanceMethods
      # get the currently processed branch
      def current_branch
        return @current_branch
      end
      
      # Loops through each dependency and runs applicable tests until one passes
      # 
      # @api private
      def test!
        dependencies.each_with_index do |dep,idx|  
          self.class.tests.each{ |test_meta|  
            dep.met = process_block :test, dep, test_meta
            break if dep.met
          }
          yield(((idx / dependencies.length.to_f) * 100).floor) if block_given?
        end
      end
      
      # Loops through dependencies and runs applicable resolutions until one passes
      #
      # @api private
      def resolve!
        dependencies.each_with_index do |dep,idx|  
          unless dep.met
            self.class.resolutions.each{ |resolution_meta|     
              dep.resolved = process_block :resolution, dep, resolution_meta
              break if dep.resolved
            }
            yield(((idx / dependencies.length.to_f) * 100).floor) if block_given?
          end
        end
      end
      
      # list of unresolved dependencies
      #
      # @return [Array<Objects>]
      #   dependencies that weren't resolved
      #
      # @api public
      def unresolved
        dependencies.inject([]){ |list,dep| 
          (!dep.met && !dep.resolved) ? (list << dep) : (list)
        }
      end
      
      # list of failed dependencies
      #
      # @return [Array<Objects>]
      #   failed dependencies
      # 
      # @api public
      def failed
        dependencies.inject([]){ |list,dep|
          dep.met ? (list) : (list << dep)
        }
      end
      
      # list of successful dependencies
      #
      # @return [Array<Objects>]
      #
      # @api public
      def passed
        dependencies.inject([]){ |list,dep| 
          dep.met ? (list << dep) : (list)
        }
      end
      
      # list of resolved dependencies
      #
      # @return [Array<Objects>]
      #   resolved dependencies
      #
      # @api public
      def resolved        
        dependencies.inject([]){ |list,dep| 
          (!dep.met && dep.resolved) ? (list << dep) : (list)
        }
      end
      
      # setups up a resolver with config and dependencies
      #
      # @param config [WarningShot::Config]
      #   Configuration to use
      #
      # @param branch_name [Symbol]
      #   Name of the branch being processed
      #
      # @param *deps [Array]
      #   Dependencies from YAML file
      #
      # @notes
      #   instance_eval is because I didnt want another class just to track
      #     met/resolved, if you hate it, feel free to change it :)
      #       met [Boolean] Was the dependency met
      #       resolved [Boolean] Was teh dependency resolved
      #
      # @api semi-public
      def initialize(config,branch_name,*deps)
        @config           = config
        @current_branch   = branch_name
        @dependencies     = Set.new
        
        deps.each do |dep|
          # Cast YAML data as described in resolver.
          dep = self.class.yaml_to_object(dep)

          dep.instance_eval { self.class.send(:attr_accessor, :met, :resolved) }
          @dependencies.add dep
        end
      end
         
      protected
       # processes a test or resolution block
       # 
       # @param type <Symbol>
       #   The type of block being processed :test | :resolution
       # 
       # @param dep <Hash>
       #    Dependency parsed from yaml configs (Currently Hash)
       #
       # @param block_info <Hash>
       #   The block details and proc
       #
       # @return <Boolean>
       #   Was the block successful; meaning conditions passed and block returned true
       #
       # @note
       #    If anyone knows a better way then doing the arity check go for it.  I'd
       #      like the register api to 'just work' and not have the writer worry about
       #      a dependency or a configuration unless they need it.  I know that a Proc 
       #      works no matter how many arguments are passed to it, but a lambda checks
       #      to make sure its the correct number, and apparently "do;end;" and "{ }"
       #      check for the number of arguments.
       # 
       #      Also note for this, :unless, :if and the block all need a different set of
       #        params because someone may have registered a :if condition that has a different
       #        signature than the test/resolution block
       #
       #        register(:test,:if=>lambda{WarningShot.hostname=="boogertron"}) do |dep,config|
       #          puts "A test that needs dep & config"
       #        end
       #
       # @api private
       def process_block(type, dep, block_info)
         block_params = case block_info[type].arity
         when 1
           dep
         when 2
           [dep,self.config]
         end
         
         if_params = case
         when 1
           dep
         when 2
           [dep,self.config]
         end if block_info[:if]
         
         unless_params = case
         when 1
           dep
         when 2
           [dep,self.config]
         end if block_info[:unless]
    
         if !block_info[:if] && !block_info[:unless]
           #if no conditions, run block
           return block_info[type].call(block_params)
         elsif block_info[:if] && block_info[:if].call(if_params)
           #elsif 'if' Condition given and it applies, run block          
           return block_info[type].call(block_params)
         elsif block_info[:unless] && !block_info[:unless].call(unless_params)
           #elsif 'unless' Condition given and it applies, run block
           return block_info[type].call(block_params)
         end

         return false
       end
    end
    
    @@descendants = []
    def self.descendants(filter_disabled=true)
      #Filter out descendants that are disabled
      temp_descendants = []
      

      @@descendants.each{ |klass|
        temp_descendants.push(klass) unless filter_disabled && klass.disabled?
      }

      #Sort by order
      temp_descendants.sort_by{|desc| desc.order}
    end

    
    private
    def self.included(subclass)
      subclass.extend ClassMethods
      subclass.send :include, InstanceMethods
      subclass.send :attr_reader, :config
      subclass.send :attr_accessor, :dependencies
      @@descendants.push subclass
    end
  end
end