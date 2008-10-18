module Kernel
  unless Kernel.respond_to?(:debugger)
    #Provide a debugger method if the debugger is turned off, stops NoMethodError
    def debugger
      puts "=-=-=-=-=Debugger was request, but debugging is not enabled (warningshot --debugger)=-=-=-=-="
    end
  end
end