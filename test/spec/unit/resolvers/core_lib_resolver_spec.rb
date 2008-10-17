require File.join(%w(. lib resolvers core_lib_resolver))

describe WarningShot::CoreLibResolver do
  before :all do
    WarningShot::CoreLibResolver.logger = $logger
  end
  
  
  it 'should have tests registered' do
    WarningShot::CoreLibResolver.tests.empty?.should be(false)
  end
  
  it 'should not have resolutions registered' do
    WarningShot::CoreLibResolver.resolutions.empty?.should be(true)
  end
  
  it 'should increment #errors for unloadable core libs' do
    cld = WarningShot::CoreLibResolver.new 'bogus_core_lib_name'
    cld.test!
    
    cld.failed.length.should be(1)
  end
  
  it 'should be able to unload file references from $"' do
    @originals = $".clone
    require 'observer'
    WarningShot::CoreLibResolver.unload(($" - @originals))
    require('observer').should be(true)
  end
  
  it 'should be able to purge classes from memory' do
    @original_classes = Symbol.all_symbols
    WarningShot::CoreLibResolver.purge true
    require 'observer'
    WarningShot::CoreLibResolver.purge_classes((Symbol.all_symbols - @original_classes))
    defined?(Observer).should be(nil)
  end
  
end