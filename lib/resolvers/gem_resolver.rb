class WarningShot::GemResolver
  include WarningShot::Resolver
  add_dependency :core, 'rubygems/dependency_installer'
  
  order  100
  branch :gem
  description 'Installs ruby gems and their dependencies'

  # Matches >, <, >=, <=
  CONDITIONAL_RGX = /[^\d]*/.freeze
  
  # Matches digits in version
  VERSION_RGX     = /[\d\.]+/.freeze
  
  # Default version to install
  DEFAULT_VERSION = ">=0.0.0".freeze
 
  cli("--gempath=PATH", String, "Alternate gem path ':' separated to check.  First in path is where gems will be installed") do |gpath|
    options[:gem_path] = gpath
  end
 
  #cli("-m","--resolver-gems=GEMS", String,"Names of gems containing add'l resolvers (':' seperated)") do |resolver_gems|
  #  options[:resolver_gems] = resolver_gems.split(':')
  #end
    
  #cli("--minigems",String,"Not supported yet.") do |minigems|
  #  options[:minigems] = minigems
  #end
           
  GemResource = Struct.new(:name,:version,:source) do
    def installed?
      self.version ||= DEFAULT_VERSION
      installed_versions = Gem::cache.search self.name
      installed = false

      required_version = Gem::Requirement.new self.version

      installed_versions.each do |i_gem|
        installed = case(required_version <=> Gem::Requirement.new(i_gem.version))
        when 1,0
          true
        else
          false
        end
        
        break if installed
      end
      installed
    end
  end #End GemResource
  
  typecast(String){ |yaml| GemResource.new(yaml,DEFAULT_VERSION) }
  typecast(Hash){ |yaml| GemResource.new yaml[:name], yaml[:version], yaml[:source] }
    
  register :test do |dep|    
    if gem_found = dep.installed?
      logger.debug " ~ [PASSED] gem: #{dep.name}:#{dep.version}"
    else
      logger.warn " ~ [FAILED] gem: #{dep.name}:#{dep.version}"
    end
    gem_found
  end
  
  register :resolution do |dep|
    old_gem_sources = Gem.sources
    begin
      Gem.sources.replace(dep.source.kind_of?(Array) ? dep.source : [dep.source]) if dep.source 
      dep_inst = Gem::DependencyInstaller.new({:install_dir => Gem.path.first})
      dep_inst.install(dep.name,Gem::Requirement.new(dep.version))
    rescue Exception => ex
      logger.error " ~ Could not install gem: #{dep.name}:#{dep.version}%s" % [dep.source ? " from #{dep.source}" : ""]
    ensure
      Gem.sources.replace old_gem_sources # replace our gem sources
    end
    dep.installed?
  end
  

  # loads gem paths from self.config
  def load_paths
    if self.config.key?(:gem_path) && !self.config[:gem_path].nil?
      self.config[:gem_path].split(":").reverse.each do |path|
        Gem.path.unshift File.expand_path(path)
      end
      
      Gem::cache.class.from_gems_in self.config[:gem_path].split(":")
      Gem::cache.refresh!
    end
  end
  
  def initialize(config,*params)
    super
    self.load_paths
  end
end
