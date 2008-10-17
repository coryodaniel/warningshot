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
      attr_reader :raw_cli_ext
      
      # extends command line interface
      # 
      # @param opts [Hash]
      #     Keys and example values
      #       :short => "-s",
      #       :long => "--longflag",
      #       :default => "my_value",
      #       :description => "Command line description",
      #       :name => "keyname", #required
      #       :type => String #[:list, :of, :available, :values]
      #       :default_desc => "Default: my_value"
      # @api public
      def cli(opts)
        @raw_cli_ext ||= []
        #Do not extend the interface if the class is being 
        return if self.disabled?
        
        ##A keyname for the option is required
        return if opts[:name].nil?
        @raw_cli_ext << opts
        
        clean_opts = [
          opts[:short],
          opts[:long],
          opts[:type],
          opts[:description],
          opts[:default_desc]
        ]
        clean_opts.delete(nil)
        
        #Set the default value if it was given
        opt_name = opts[:name].intern
        WarningShot::Config[opt_name] = opts[:default]
        
        WarningShot.parser.on_tail(*clean_opts) do |val|
          WarningShot::Config[opt_name] = val
        end

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
      #   end
      #
      # @api public
      def branch(b=nil)
        @branch = b unless b.nil?
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
        @order
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
      def cast(klass=nil,&block)
        if klass.nil?
          klass = :default
        else
          klass = klass.name.to_sym
        end
        (@yaml_to_object_methods||={})[klass] = block
      end
      
      # calls the block defined by Resolver#cast to convert
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
      #     # this would only resolve in production
      #     WarningShot.environment == 'production'
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
        @before_filters[type]
      end
      
      # gets after filters for type
      #
      # @param type [Symbol]
      #   Type of filters to get
      # @return [Array[Proc]] 
      #   after filters
      # @api private
      def after_filters(type)
        @after_filters[type]
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
      
      # Loops through each dependency and runs applicable tests until one passes
      # 
      # @api private
      def test!
        dependencies.each do |dep|   
          self.class.tests.each{ |test_meta|  
            dep.met = process_block :test, dep, test_meta
            break if dep.met
          }
        end
      end
      
      # Loops through dependencies and runs applicable resolutions until one passes
      #
      # @api private
      def resolve!
        dependencies.each do |dep|
          self.class.resolutions.each{ |resolution_meta|     
            dep.resolved = process_block :resolution, dep, resolution_meta
            break if dep.resolved
          }
        end
      end
      
      # list of unresolved dependencies
      #
      # @return [Array<Objects>]
      #   dependencies that weren't resolved
      #
      # @api private
      def unresolved
        dependencies.inject([]){ |list,dep| 
          if !dep.met && !dep.resolved
            list << dep 
          else
            list
          end
        }
      end
      
      # list of failed dependencies
      #
      # @return [Array<Objects>]
      #   failed dependencies
      # 
      # @api private
      def failed
        dependencies.inject([]){ |list,dep|
          unless dep.met
            list << dep
          else
            list
          end
        }
      end
      
      # list of successful dependencies
      #
      # @return [Array<Objects>]
      # @api private
      def passed
        dependencies.inject([]){ |list,dep| 
          if dep.met
            list << dep
          else
            list
          end
        }
      end
      
      # list of resolved dependencies
      #
      # @return [Array<Objects>]
      #   resolved dependencies
      #
      # @api private
      def resolved        
        dependencies.inject([]){ |list,dep| 
          if(!dep.met && dep.resolved)
            list << dep 
          else
            list
          end
        }
      end
      
      # loads up instance variables for new test
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
      def initialize(*deps)
        @dependencies = Set.new
        deps.each do |dep|
          # Cast YAML data as described in resolver.
          dep = self.class.yaml_to_object(dep)

          dep.instance_eval { self.class.send(:attr_accessor, :met, :resolved) }
          @dependencies.add dep
        end
      end
   
      attr_accessor :logger
      attr_accessor :dependencies
      
      protected
       # processes a test or resolution block
       # 
       # @param type <Symbol>
       #   The type of block being processed :test | :resolution
       # 
       # @param dep <Hash>
       #    Dependency parsed from yaml configs (Currently Hash)
       #    TODO; once Dependencies are an object besides Hash, this may need to be changed
       #
       # @param block_info <Hash>
       #   The block details and proc
       #
       # @return <Boolean>
       #   Was the block successful; meaning conditions passed and block returned true
       #
       # @api private
       def process_block(type, dep, block_info)
         if !block_info[:if] && !block_info[:unless]
           # no condition, run block
           return block_info[type].call(dep)
         elsif block_info[:if] && block_info[:if].call(dep)
           #if Condition given and it applies, run block          
           return block_info[type].call(dep)
         elsif block_info[:unless] && !block_info[:unless].call(dep)
           #unless Condition given and it applies, run block
           return block_info[type].call(dep)
         end

         return false
       end
    end
    
    @@descendents = []
    def self.descendents
      #Filter out descendents that are disabled
      temp_descendents = []
      @@descendents.each do |klass|
        temp_descendents.push(klass) unless klass.disabled?
      end

      #Sort by order
      temp_descendents.sort_by{|desc| desc.order}
    end

    
    private
    def self.included(subclass)
      subclass.extend ClassMethods
      subclass.send :include, InstanceMethods
      subclass.send :include, WarningShot::Utilities
      @@descendents.push subclass
    end
  end
end