# I pretty much goinked this from merb, you love merb, merb loves you.
# http://merbivore.com

module WarningShot
  class Config
  
    class << self
      def defaults
        @defaults ||= {
          :environment  => 'development',
          :resolve      => false,
          :config_paths => [File.join('.','config','warningshot'),File.join('~','.warningshot')],
          :application  => '.',
          :log_path     => File.join('.','log','warningshot.log'),
          :log_level    => :info,
          :growl        => false,
          :verbose      => true,
          :colorize     => true
        }
      end
    
      def use
        @configuration ||= {}
        yield @configuration
        @configuration = defaults.merge(@configuration)
      end
    
      def [](key)
        (@configuration||={})[key]
      end

      def []=(key,val)
        (@configuration||={})[key] = val
        #@configuration[key] = val
      end
    
      def setup(settings = {})
        @configuration = defaults.merge(settings)
      end
    
      attr_accessor :configuration
    
      def parse_args(argv = ARGV)
        @configuration ||= {}
        options = {}
        options[:environment] = ENV["WARNING_SHOT_ENV"] if ENV["WARNING_SHOT_ENV"]
      
        WarningShot.parser.banner = <<-BANNER
WarningShot v. #{WarningShot::VERSION}
Dependency Resolution Framework

Usage: warningshot [options]
BANNER
        WarningShot.parser.separator '*'*80
        
        WarningShot.parser.on("-e", "--environment=STRING", String, "Environment to test in","Default: #{defaults[:environment]}") do |env|
          options[:environment] = env
        end
        WarningShot.parser.on("--resolve","Resolve missing dependencies (run as sudo)") do |resolve|
          options[:resolve] = resolve
        end
        WarningShot.parser.on("-a","--app=PATH", String, "Path to application", "Default: #{defaults[:application]}") do |app|
          options[:application] = app
        end
        WarningShot.parser.on("-c","--configs=PATH", String,"Path to config directories (':' seperated)","Default: #{defaults[:config_paths].join(':')}") do |config|
          options[:config_paths] = config.split(':')
        end
        WarningShot.parser.on("-c","--resolvers=PATH", String,"Path to add'l resolvers (':' seperated)","Not supported yet.") do |config|
          options[:resolvers] = config.split(':')
        end
        WarningShot.parser.on("-t","--templates=PATH", String, "Generate template files", "Default: False") do |template_path|
          template_path = options[:config_paths].first if template_path.nil? || template_path.empty?
          WarningShot::TemplateGenerator.create(template_path)
          exit
        end
        WarningShot.parser.on("-l","--log LOG", String, "Path to log file", "Default: #{defaults[:log_path]}") do |log_path|        
          options[:log_path] = log_path
        end
        WarningShot.parser.on("--loglevel [LEVEL]",[:debug, :info, :warn, :error, :fatal], "Default: #{defaults[:log_level]}") do |log_level|
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
        WarningShot.parser.on_tail("--version", "Show version"){ 
          puts "WarningShot v. #{WarningShot::VERSION}"
          puts "Installed resolvers:"
            Resolver.descendents.each { |klass| 
              puts "\n"
              puts klass
              puts "  Tests: #{klass.tests.length}, Resolutions: #{klass.resolutions.length} [#{klass.resolutions.empty? ? 'unresolvable' : 'resolvable'}]"
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
        WarningShot::Config.setup(options)
      rescue OptionParser::InvalidOption, OptionParser::InvalidArgument => op
        puts op
        puts WarningShot.parser #; exit;
      end
      
    end #End self
  end #End Config
end#End WarningShot