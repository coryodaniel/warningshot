require 'rubygems'
require 'fileutils'
require 'yaml'
require 'optparse'
require 'logger'
require 'set'


# Load core extensions
Dir.glob(File.join(File.dirname(__FILE__), "core_ext","**","*.rb")).each {|f| require f}

# Load WarningShot
Dir.glob(File.join(File.dirname(__FILE__), "warning_shot","**","*.rb")).each {|f| require f}

# Load resolvers
Dir.glob(File.join(File.dirname(__FILE__), "resolvers","**","*.rb")).each {|f| require f}