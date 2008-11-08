require 'rubygems'
require 'fileutils'
require 'yaml'
require 'optparse'
require 'logger'
require 'set'
require 'rbconfig'

# Load core extensions
Dir.glob(File.join(File.dirname(__FILE__), 'core_ext', '**', '*.rb')).each {|f| require f}

# Load WarningShot
require File.dirname(__FILE__) / 'warningshot' / 'warning_shot'
require File.dirname(__FILE__) / 'warningshot' / 'version'
require File.dirname(__FILE__) / 'warningshot' / 'config'
require File.dirname(__FILE__) / 'warningshot' / 'logger'
require File.dirname(__FILE__) / 'warningshot' / 'resolver' 
require File.dirname(__FILE__) / 'warningshot' / 'dependency_resolver'
require File.dirname(__FILE__) / 'warningshot' / 'growl'
require File.dirname(__FILE__) / 'warningshot' / 'template_generator'
