
# Check to see if core lib packages are available
#   Created due to issues with some Apt installs not installing all
#   ruby core classes.  This is irresolvable, but at least gives you
#   a heads up.

class WarningShot::CoreLibResolver
  include WarningShot::Resolver
  
  order 10
  #disable!
  description 'Checks that core ruby lib packages are available'
  branch :core_lib
  @@do_purge = false
  
  CoreLibResource = Struct.new(:lib)
  typecast do |dep|
    CoreLibResource.new(dep)
  end
  
  # optionally purge CoreLIb classes in memory
  # The default behavior is to just remove the
  # reference to loading the class from $".  Classes
  # stay in memory but can be re-required without 
  # returning false
  #
  # @param do_purge [Boolean] (Default: false)
  #   Should classes be purged from memory.
  def self.purge(do_purge=false)
    @@do_purge = do_purge
  end
  
  @@original_requires  = $".clone
  @@original_classes   = Symbol.all_symbols.clone if @@do_purge
  
  register :test do |dep|
    begin
      require dep.lib
      logger.debug " ~ Found core lib: #{dep.lib}"
      WarningShot::CoreLibResolver.unload($" - @@original_requires)
      WarningShot::CoreLibResolver.purge_classes(Symbol.all_symbols - @@original_classes) if @@do_purge
      true
    rescue LoadError => ex
      false
    end
  end
  
  private
 
  class << self
    # removes files from $" so they can be re-required
    #
    # @param files [Array(String)]
    #   files to remove
    #
    # @api private
    def unload(files)
      files.each do |req|
        $".delete(req)
      end
    end
  
    # Undefines classes
    #
    # @param classes [Array(Symbol)]
    #   classes to remove
    #
    # @api private
    def purge_classes(classes)
      classes.each do |klass|
        Object.send(:remove_const, klass) if Object.is_const_defined? klass
      end
    end
  
  end
end