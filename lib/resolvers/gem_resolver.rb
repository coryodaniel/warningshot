class WarningShot::GemResolver
  include WarningShot::Resolver
  add_dependency :core, 'rubygems'
  add_dependency :core, 'rubygems/dependency_installer'
  add_dependency :core, 'rubygems/uninstaller'
  add_dependency :core, 'rubygems/dependency'

  order  100
  branch :gem
  description 'Installs ruby gems and their dependencies'
    
  # Default version to install
  DEFAULT_VERSION = ">= 0.0.0".freeze
 
  cli("--gempath=PATH", String, "Alternate gem path ':' separated to check.  First in path is where gems will be installed") do |gpath|
    options[:gem_path] = gpath
  end
  
  cli("--update-sources","Update gem sources before installing") do |no_up_src|
    options[:update_sources] = no_up_src
  end
 
  #cli("-m","--resolver-gems=GEMS", String,"Names of gems containing add'l resolvers (':' seperated)") do |resolver_gems|
  #  options[:resolver_gems] = resolver_gems.split(':')
  #end
           
  GemResource = Struct.new(:name,:version,:source) do
    def installed?   
      return !!(Gem.source_index.find_name(self.name, self.version).first)
    end
    
    def install!
      orig_gem_sources = Gem.sources.clone

      installer = Gem::DependencyInstaller.new({
        :user_install => false,
        :install_dir => Gem.dir
      })

      begin
        Gem.sources.replace(self.source.kind_of?(Array) ? self.source : [self.source]) if self.source 
        installer.install(self.name,self.version)
      rescue Gem::InstallError => ex
        WarningShot::GemResolver.logger.error " ~ Could not install gem: #{self.name}:#{self.version}%s" % [self.source ? " from #{self.source}" : ""]
      rescue Gem::GemNotFoundException => ex
        WarningShot::GemResolver.logger.error " ~ Gem (#{self.name}:#{self.version}) was not found%s" % [self.source ? " from #{self.source}" : ""]
      ensure
        Gem.sources.replace orig_gem_sources # replace our gem sources
      end

      !installer.installed_gems.empty?
    end
    
    def uninstall!
      opts = {
        :user_install => false,
        :install_dir => Gem.dir,
        :version  => self.version
      }
      WarningShot::GemResolver.update_source_index(opts[:install_dir])
      Gem::Uninstaller.new(self.name, opts).uninstall rescue false
    end
  end #End GemResource
  
  typecast(String){ |yaml| 
    _ver = Gem::Requirement.new [DEFAULT_VERSION]
    GemResource.new yaml, _ver 
  }
  
  typecast(Hash){ |yaml| 
    _ver = (yaml[:version].nil? || yaml[:version].empty?) ? DEFAULT_VERSION : yaml[:version]
    _ver = Gem::Requirement.new [_ver]
    GemResource.new yaml[:name], _ver, yaml[:source] 
  }
    
  register :test do |dep|    
    if gem_found = dep.installed?
      logger.debug "[PASSED] Gem found: #{dep.name}:#{dep.version}"
    else
      logger.warn "[FAILED] Gem not found: #{dep.name}:#{dep.version}"
    end
    gem_found
  end
  
  register :resolution do |dep|
    if _installed = dep.install!
      logger.debug "[RESOLVED] Gem installed: #{dep.name}:#{dep.version}"
    else
      logger.error "[UNRESOLVED] Gem not installed: #{dep.name}:#{dep.version}"
    end
    _installed
  end
  
  class << self
    def update_source_index(*dirs)
      spec_dirs = dirs.inject([]){|memo,dir| 
        memo << File.join(File.expand_path(dir), 'specifications')
      }
            
      Gem.send :class_variable_set, "@@source_index", Gem::SourceIndex.from_gems_in(*spec_dirs)
      Gem::cache.refresh!
    end
  end
  
  def initialize(config,branch_name,*params)
    super
    
    Gem.configuration.update_sources = !!(self.config[:update_sources])
    
    if self.config.key?(:gem_path) && !self.config[:gem_path].nil?
      #make sure user paths are expanded
      tmp_paths = self.config[:gem_path].split(":").collect! do |gp|
        File.expand_path(gp)
      end.join(":")

      Gem.send :set_paths, tmp_paths + ":" + Gem.path.join(":")
      Gem.send :set_home, Gem.path.first

      WarningShot::GemResolver.update_source_index *Gem.path
    end
  end
    
end