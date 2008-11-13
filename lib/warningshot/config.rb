# I pretty much goinked this from merb, you love merb, merb loves you.
# http://merbivore.com

require File.dirname(__FILE__) / 'warning_shot' 
require File.dirname(__FILE__) / 'template_generator'
 
module WarningShot
  class Config
    attr_reader :configuration
    DEFAULTS = {
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
    }    
    
    #
    # Initialize a new WarningShot config
    # 
    # @example
    #   Setting config with a hash
    #   conf = WarningShot::Config.new({:environment=>"staging",:chickens=>true})
    #
    #   Setting config with a block
    #   conf = WarningShot::Config.new do |c|
    #     c[:environment] = "production"
    #     c[:cool_feature] = true
    #   end
    #
    #   Just using default config
    #   conf = WarningShot::Config.new
    #
    #   Using a hash and a block, block wins
    #   conf = WarningShot::Config.new({:environment=>"hash",:something=>true}) do |c|
    #     c[:environment] = "blk"
    #     c[:else] = true
    #   end
    #
    def initialize(config={})
      opt_config = config
      if block_given?
        blk_config = {}
        yield(blk_config)
        opt_config = opt_config.merge(blk_config)
      end
      @configuration = WarningShot::Config::DEFAULTS.clone.merge(opt_config)
    end
  
    def [](key)
      configuration[key]
    end

    def []=(key,val)
      configuration[key] = val
    end  

    class << self      
      def parse_args(argv = ARGV)
        options = {}
        options[:environment] = ENV["WARNING_SHOT_ENV"] if ENV["WARNING_SHOT_ENV"]
      
        WarningShot.parser.banner = <<-BANNER
WarningShot v. #{WarningShot::VERSION}
Dependency Resolution Framework

Usage: warningshot [options]
BANNER
        WarningShot.parser.separator '*'*80
        
        WarningShot.parser.on("-e", "--environment=STRING", String, "Environment to test in","Default: #{DEFAULTS[:environment]}") do |env|
          options[:environment] = env
        end
        WarningShot.parser.on("--resolve","Resolve missing dependencies (run as sudo)") do |resolve|
          options[:resolve] = resolve
        end
        WarningShot.parser.on("-a","--app=PATH", String, "Path to application", "Default: #{DEFAULTS[:application]}") do |app|
          options[:application] = app
        end
        WarningShot.parser.on("-c","--configs=PATH", String,"Path to config directories (':' seperated)","Default: #{DEFAULTS[:config_paths].join(':')}") do |config|
          options[:config_paths] = config.split(':')
        end
        WarningShot.parser.on("-r","--resolvers=PATH", String,"Path to add'l resolvers (':' seperated)","Default: #{DEFAULTS[:resolvers].join(':')}") do |config|
          options[:resolvers] = config.split(':')
        end

        WarningShot.parser.on("-m","--resolver-gems=GEMS", String,"Names of gems containing add'l resolvers (':' seperated)") do |config|
          options[:resolver_gems] = config.split(':')
        end

        WarningShot.parser.on("-t","--templates=PATH", String, "Generate template files", "Default: False") do |template_path|
          template_path = options[:config_paths].first if template_path.nil? || template_path.empty?
          WarningShot::TemplateGenerator.create(template_path)
          exit
        end
        WarningShot.parser.on("-l","--log LOG", String, "Path to log file", "Default: #{DEFAULTS[:log_path]}") do |log_path|        
          options[:log_path] = log_path
        end
        WarningShot.parser.on("--loglevel [LEVEL]",[:debug, :info, :warn, :error, :fatal], "Default: #{DEFAULTS[:log_level]}") do |log_level|
          options[:log_level] = log_level
        end
        WarningShot.parser.on("-g", "--growl", "Output results via growl (Requires growlnotify)") do |growl|
          options[:growl] = growl
        end
        WarningShot.parser.on("-v", "--[no-]verbose", "Output verbose information") do |verbose|
          options[:verbose] = verbose
        end
        WarningShot.parser.on("-p", "--[no-]prettycolors", "Colorize output") do |colorize|
          options[:colorize] = colorize
        end
        # NOTE stubs for taking WarningShot.only_load && WarningShot.priority_load from command line, ran into a catch22
        #   with this so its removed for now. Cory ODaniel (11/8/2008)
        #
        #WarningShot.parser.on("--oload=LIST", String, "Only load specified resolvers (Command seperated)") do |oload|
        #  options[:oload] = oload.split(',')
        #  WarningShot.only_load *options[:oload]
        #end
        #WarningShot.parser.on("--pload=LIST", String, "Load specified resolvers only, setting sequential priority (Command seperated)") do |pload|
        #  options[:pload] = pload.split(',')
        #  WarningShot.only_load *options[:pload]
        #end
        WarningShot.parser.on_tail("--version", "Show version"){ 
          WarningShot.parser.parse!(argv)
          conf = WarningShot::Config.new(options)
          
          WarningShot.load_app(conf[:application])
          WarningShot.load_addl_resolvers(conf[:resolvers])
          
          puts "WarningShot v. #{WarningShot::VERSION}"
          puts "Installed resolvers:"
            Resolver.descendants.each { |klass| 
              puts "\n"
              puts klass
              puts "  Tests: #{klass.tests.length}, Resolutions: #{klass.resolutions.length} [#{klass.resolutions.empty? ? 'irresolvable' : 'resolvable'}]"
              puts "  #{klass.description}" 
              puts "  Command Line Options: #{klass.raw_cli_ext.inject([]){|m,c| m << c[:long]}.join(',')}" if klass.raw_cli_ext
            }
          exit
        }
        WarningShot.parser.on_tail("-h", "--help","Show this help message") { puts WarningShot.parser; exit } 
        WarningShot.parser.on_tail("--debugger","Enable debugging") do
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
        
        WarningShot.parser.parse!(argv)
        return WarningShot::Config.new(options)
      rescue OptionParser::InvalidOption, OptionParser::InvalidArgument => op
        puts op
        puts WarningShot.parser; 
        exit;
      end
      
    end #End self
  end #End Config
end#End WarningShot
