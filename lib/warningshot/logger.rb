require File.dirname(__FILE__) / 'warning_shot' 
require 'logger'

# This is a ghetto simple interface ontop of ruby stnd logger
# The goal is to provide an updateable console interface and log things
# to screen & a log file.
#
# You  may or may not agree that one class should be used to manage the interface
# and the log, feel free to change that ;) 
#
#
module WarningShot
  class Logger
    def initialize(dev,shift_age=0,shift_size=1048576)
      FileUtils.mkdir_p(File.dirname(File.expand_path(dev))) if dev.is_a? String

      @logger = ::Logger.new(dev,shift_age,shift_size)

      # A queue for information to go while verbose mode is on
      # this will end up containing SUCCESS|FAILURES messages from resolvers
      @stdout_queue = []
    end
    
    # fmt <Logger::Formatter>
    def formatter=(fmt)
      @logger.formatter = fmt
    end
        
    # lvl <String> Log level
    def level=(lvl)
      @logger.level = Object.class_eval("Logger::#{lvl}")
    end
    
    #Update stdout
    #Takes *params as printf()
    def update(*params)
      if is_verbose?
        $stdout.flush
        params[0] = "\r#{params[0]}"
        $stdout.printf(*params)
      end
    end
    
    #Takes *params as printf()
    def display(*params)
      if is_verbose?
        $stdout.flush
        params[0] = "\r#{params[0]}\n"
        $stdout.printf(*params)
      end
    end
    
    # Set $stdout verbosity
    #
    #  :none          -> will output nothing to STDOUT
    #  :verbose       -> #display & #info will be output to STDOUT
    #  :very_verbose  -> #all log levels output to screen
    #
    def verbosity=(lvl)
      @verbosity = lvl
    end
    
    def is_verbose?
      !!(@verbosity == :verbose)
    end
    
    def is_very_verbose?
      !!(@verbosity == :very_verbose)
    end
    
    def is_not_verbose?
      !!(@verbosity == :none)
    end
    
    def display_stdout_queue
      if is_verbose?
        output = @stdout_queue.join("\n")
        puts(output) 
        @stdout_queue = []
      end
    end
    
    def info(msg)
      if is_very_verbose?
        $stdout.puts("INFO:\t~ #{msg}")
      elsif is_verbose?
        @stdout_queue << msg
      end
      @logger.info(msg)
    end
    
    def debug(msg)
      if is_very_verbose?
        $stdout.puts("DEBUG".blue + ":\t~ #{msg}")
      end
      @logger.debug(msg)
    end
    
    def warn(msg)
      if is_very_verbose?
        $stdout.puts("WARN".yellow + ":\t~ #{msg}".yellow)
      end
      @logger.warn msg
    end
    
    def fatal(msg)
      if is_very_verbose?
        $stdout.puts("FATAL".red + ":\t~ #{msg}".red)
      end
      @logger.fatal msg
    end
    
    def error(msg)
      if is_very_verbose?
        $stdout.puts("ERROR".red + ":\t~ #{msg}".red)
      end
      @logger.error msg
    end
    
  end
  
  class LoggerFormatter < ::Logger::Formatter
    
    def call(severity, timestamp, progname, msg)
      "#{msg}\n"
    end
    
    def time_format=(fmt)
      @time_format = fmt
    end
            
  end

end

