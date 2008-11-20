require File.dirname(__FILE__) / 'warning_shot' 
require File.dirname(__FILE__) / 'template_generator'
 
# This is a factory class for creating WarningShot hash configurations.
#   Configurations can be created by passing a hash or block to
#     WarningShot::Config.create
#   OR
#     By calling WarningShot::Config.parse_args (for command line, uses ARGV)
#
#   It also provies an interface for plugins to extend the CLI
#     Config.cli => Provides access to add stuff to command line
#     Config.cli_options => Provides a hash to store values into from within the OptionParser block
#
#   The resolver class also provides functions of the same name that shortcut to WarningShot::Config
#
# @example
#   class WarningShot::MyResolver
#     cli("-s", "--someflag=VALUE", String, "Add some feature") do |value|
#       options[:some_value] = value
#     end
#
module WarningShot
  class Config
    attr_reader :configuration
    PARSER    = OptionParser.new

    DEFAULTS  = {
      :pload        => [],
      :oload        => [],
      :environment  => 'development',
      :resolve      => false,
      :config_paths => ['.'  / 'config' / 'warningshot', '~' / '.warningshot'],
      :application  => '.',
      :log_path     => '.' / 'log' / 'warningshot.log',
      :log_level    => :info,
      :growl        => false,
      :verbose      => false,
      :colorize     => true,
      :resolvers    => ['~' / '.warningshot' / '*.rb']
    }.freeze
  
    class << self      
      
      # Add command line flags to tail of CLI
      # shortcut to WarningSHot::Config::PARSER.on_tail
      #
      # @see OptionParser
      # 
      # @param *opts [Array]
      #
      # @param &block [Proc]
      #
      # @api public
      def cli(*opts,&block)
        PARSER.on_tail(*opts,&block)
      end
      
      # access to a hash for command line options use for Plugin to extend interface
      #
      # @return [Hash]
      def cli_options
        @@cli_options ||={}
        @@cli_options
      end

      #
      # Initialize a new WarningShot config
      # 
      # @example
      #   Setting config with a hash
      #   conf = WarningShot::Config.create({:environment=>"staging",:chickens=>true})
      #
      #   Setting config with a block
      #   conf = WarningShot::Config.create do |c|
      #     c[:environment] = "production"
      #     c[:cool_feature] = true
      #   end
      #
      #   Just using default config
      #   conf = WarningShot::Config.create
      #
      #   Using a hash and a block, block wins
      #   conf = WarningShot::Config.create({:environment=>"hash",:something=>true}) do |c|
      #     c[:environment] = "blk"
      #     c[:else] = true
      #   end
      #
      def create(config={})
        opt_config = config
        if block_given?
          blk_config = {}
          yield(blk_config)
          opt_config = opt_config.merge(blk_config)
        end
        WarningShot::Config::DEFAULTS.clone.merge(opt_config)
      end
      
      def parse_args(argv = ARGV)
        @@cli_options = {}
        @@cli_options[:environment] = ENV["WARNING_SHOT_ENV"] if ENV["WARNING_SHOT_ENV"]
      
        WarningShot::Config::PARSER.banner   = "WarningShot v. #{WarningShot::VERSION}\n"
        WarningShot::Config::PARSER.banner += "Dependency Resolution Framework\n\n"
        WarningShot::Config::PARSER.banner += "Usage: warningshot [options]"
        WarningShot::Config::PARSER.separator '*'*80

        WarningShot::Config::PARSER.on("-e", "--environment=STRING", String, "Environment to test in","Default: #{DEFAULTS[:environment]}") do |env|
          @@cli_options[:environment] = env
        end
        WarningShot::Config::PARSER.on("--resolve","Resolve missing dependencies (run as sudo)") do |resolve|
          @@cli_options[:resolve] = resolve
        end
        WarningShot::Config::PARSER.on("-a","--app=PATH", String, "Path to application", "Default: #{DEFAULTS[:application]}") do |app|
          @@cli_options[:application] = app
        end
        WarningShot::Config::PARSER.on("-c","--configs=PATH", String,"Path to config directories (':' seperated)","Default: #{DEFAULTS[:config_paths].join(':')}") do |config|
          @@cli_options[:config_paths] = config.split(':')
        end
        WarningShot::Config::PARSER.on("-r","--resolvers=PATH", String,"Path to add'l resolvers (':' seperated)","Default: #{DEFAULTS[:resolvers].join(':')}") do |config|
          @@cli_options[:resolvers] = config.split(':')
        end
        WarningShot::Config::PARSER.on("-t","--templates=PATH", String, "Generate template files", "Default: False") do |template_path|
          template_path = @@cli_options[:config_paths].first if template_path.nil? || template_path.empty?
          WarningShot::TemplateGenerator.create(template_path)
          exit
        end
        WarningShot::Config::PARSER.on("-l","--log=LOG", String, "Path to log file", "Default: #{DEFAULTS[:log_path]}") do |log_path|        
          @@cli_options[:log_path] = log_path
        end
        WarningShot::Config::PARSER.on("--loglevel=LEVEL",[:debug, :info, :warn, :error, :fatal], "Default: #{DEFAULTS[:log_level]}") do |log_level|
          @@cli_options[:log_level] = log_level
        end
        WarningShot::Config::PARSER.on("-g", "--growl", "Output results via growl (Requires growlnotify)") do |growl|
          @@cli_options[:growl] = growl
        end
        WarningShot::Config::PARSER.on("-v", "--[no-]verbose", "Output verbose information") do |verbose|
          @@cli_options[:verbose] = verbose
        end
        WarningShot::Config::PARSER.on("-p", "--[no-]prettycolors", "Colorize output") do |colorize|
          @@cli_options[:colorize] = colorize
        end
        WarningShot::Config::PARSER.on("--oload=LIST", String, "Only load specified resolvers (Command seperated)") do |oload|
          @@cli_options[:oload] = oload.split(',')
          WarningShot.only_load *@@cli_options[:oload]
        end
        WarningShot::Config::PARSER.on("--pload=LIST", String, "Load specified resolvers only, setting sequential priority (Command seperated)") do |pload|
          @@cli_options[:pload] = pload.split(',')
          WarningShot.only_load *@@cli_options[:pload]
        end
        WarningShot::Config::PARSER.on_tail("--version", "Show version"){ 
          WarningShot::Config::PARSER.parse!(argv)
          conf = WarningShot::Config.create(@@cli_options)
          
          WarningShot.load_app(conf[:application])
          WarningShot.load_addl_resolvers(conf[:resolvers])
          
          puts "WarningShot v. #{WarningShot::VERSION}"
          puts "Installed resolvers:"
            Resolver.descendants.each { |klass| 
              puts "\n"
              puts klass
              puts "  Tests: #{klass.tests.length}, Resolutions: #{klass.resolutions.length} [#{klass.resolutions.empty? ? 'irresolvable' : 'resolvable'}]"
              puts "  #{klass.description}" 
            }
          exit
        }
        WarningShot::Config::PARSER.on_tail("-h", "--help","Show this help message") { puts WarningShot::Config::PARSER; exit } 
        WarningShot::Config::PARSER.on_tail("--debugger","Enable debugging") do
          begin
            require "ruby-debug"
            Debugger.start
            Debugger.settings[:autoeval] = true if Debugger.respond_to?(:settings)
            puts "Debugger enabled"
          rescue LoadError => ex
            puts "You need to install ruby-debug to run the server in debugging mode. With gems, use 'gem install ruby-debug'"
            exit
          end
        end
        
        WarningShot::Config::PARSER.parse!(argv)
        
        @curr_config  = @@cli_options.clone
        @@cli_options = {}
        return WarningShot::Config.create(@curr_config)
      rescue OptionParser::InvalidOption, OptionParser::InvalidArgument,OptionParser::NeedlessArgument => op
        puts op
        puts WarningShot::Config::PARSER; 
        exit;
      end
      
    end #End self
  end #End Config
end#End WarningShot
