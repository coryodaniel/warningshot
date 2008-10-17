module WarningShot
  class LoggerFormatter < Logger::Formatter

    ESCAPE_SEQ = {
      "INFO"      => "\e[37m%s\e[0m",
      "WARN"      => "\e[33m%s\e[0m",
      "DEBUG"     => "\e[34m%s\e[0m",
      "ERROR"     => "\e[31m%s\e[0m",
      "FATAL"     => "\e[1m%s\e[0m"
    }
    
    def call(severity, timestamp, progname, msg)
      sprintf(ESCAPE_SEQ[severity],"#{msg}\n")
    end
    
    def time_format=(fmt)
      @time_format = fmt
    end
        
  end

end

