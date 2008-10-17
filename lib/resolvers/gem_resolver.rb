# Auto-generated ruby debug require       
require "ruby-debug"
Debugger.start
Debugger.settings[:autoeval] = true if Debugger.respond_to?(:settings)

require 'rubygems/dependency_installer'
class WarningShot::GemResolver
  include WarningShot::Resolver
  
  order  100
  branch :gem
  description 'Installs ruby gems and their dependencies'

  # Matches >, <, >=, <=
  CONDITIONAL_RGX = /[^\d]*/.freeze
  
  # Matches digits in version
  VERSION_RGX     = /[\d\.]+/.freeze
  
  # Default version to install
  DEFAULT_VERSION = ">=0.0.0".freeze
     
  cli(
    :long         => "--gempath",
    :description  => "Alternate gem path ':' separated to check.  First in path is where gems will be installed",
    :name         => "gem_path",
    :default      => nil
  )
    
  cli(
    :long         => "--minigems",
    :description  => "Not supported yet.",
    :name         => "minigems",
    :default      => false
  )
         
  GemResource = Struct.new(:name,:version) do
    # TODO replace this with Gem::Requirement
    def installed?
      self.version ||= DEFAULT_VERSION
      installed_versions = Gem::cache.search self.name
      installed = false

      conditionals      = self.version.match(CONDITIONAL_RGX)[0]          
      required_version  = Gem::Version.create self.version.match(VERSION_RGX)[0] 

      installed_versions.each do |i_gem|
        installed = case (required_version <=> i_gem.version)
        when 0
          (conditionals =~ /=/ || conditionals.empty?)
        when 1
          (conditionals =~ /</)
        when -1
          (conditionals =~ />/)
        end

        break if installed
      end
      installed
    end
  end #End GemResource
  
  cast(String){ |yaml| GemResource.new(yaml,DEFAULT_VERSION) }
  cast(Hash){ |yaml| GemResource.new yaml[:name], yaml[:version] }
    
  register :test do |dep|    
    if gem_found = dep.installed?
      logger.debug " ~ [PASSED] gem: #{dep.name}:#{dep.version}"
    else
      logger.warn " ~ [FAILED] gem: #{dep.name}:#{dep.version}"
    end
    gem_found
  end
  
  register :resolution do |dep|
    begin
      dep_inst = Gem::DependencyInstaller.new({:install_dir => Gem.path.first})
      dep_inst.install(dep.name,Gem::Requirement.new(dep.version))
    rescue Exception => ex
      logger.error " ~ Could not install gem: #{dep.name}:#{dep.version}"
    end
    dep.installed?
  end
  
  class << self
    # loads gem paths from WarningShot::Config
    def load_paths
      if WarningShot::Config.configuration.key?(:gem_path)
        WarningShot::Config.configuration[:gem_path].split(":").reverse.each do |path|
          Gem.path.unshift path
        end
        
        Gem::cache.class.from_gems_in WarningShot::Config.configuration[:gem_path].split(":")
        Gem::cache.refresh!
      end
    end
  end
  
  def initialize(*params)
    super
    WarningShot::GemResolver.load_paths
  end
end