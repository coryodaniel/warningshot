require 'pathname'
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'
require 'spec/rake/spectask'
require "rake/testtask"
require "spec"
require "spec/story"
require 'spec/story/extensions/main'
require "spec/rake/spectask"
require "fileutils"

NAME = 'warningshot'
ROOT = Pathname(__FILE__).dirname.expand_path

require 'lib/warningshot'
require 'lib/warningshot/version'

CLEAN.include ["**/.*.sw?", "pkg", "lib/*.bundle", "*.gem", "doc/","doc/", "test/output/*", "coverage", "cache"]
Dir['tasks/*.rb'].each {|r| require r}


##############################################################################
# ADD YOUR CUSTOM TASKS IN ./tasks
# NAME YOUR RAKE FILES file_name.rb
##############################################################################
