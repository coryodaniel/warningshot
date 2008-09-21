puts require File.join(%w(. lib dependencies core_lib_dependency))

describe WarningShot::CoreLibDependency do
  before :all do
    @@logger = Logger.new STDOUT
    @@logger.level = Logger::FATAL
  end
  
  it 'should respond to CoreLibDependency#test' do
    WarningShot::CoreLibDependency.new.respond_to?(:test).should be(true)
  end
  
  it 'should not respond to CoreLibDependency#heal' do
    WarningShot::CoreLibDependency.new.respond_to?(:heal).should be(false)
  end
  
  it 'should increment #errors for unloadable core libs' do
    cld = WarningShot::CoreLibDependency.new
    cld.init ['bogus_core_lib_name']
    cld.logger = @@logger
    cld.test
    
    cld.errors.should be(1)
  end
  
  it 'should be able to unload file references from $"' do
    @originals = $".clone
    require 'observer'
    WarningShot::CoreLibDependency.unload(($" - @originals))
    require('observer').should be(true)
  end
  
  it 'should be able to purge classes from memory' do
    @original_classes = Symbol.all_symbols
    WarningShot::CoreLibDependency.purge true
    require 'observer'
    WarningShot::CoreLibDependency.purge_classes((Symbol.all_symbols - @original_classes))
    defined?(Observer).should be(nil)
  end
  
end