require "." / "lib" / "resolvers" / "directory_resolver"

describe WarningShot::DirectoryResolver do
  before :all do
    WarningShot::DirectoryResolver.logger = $logger

    @@base_path = File.expand_path("." / "test" / "data" / "resolvers" / "directory")
  end

  after :each do
    FileUtils.rm_rf @@base_path
  end

  it 'should have tests registered' do
    WarningShot::DirectoryResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::DirectoryResolver.resolutions.empty?.should be(false)
  end

  describe 'with resolutions enabled & with resolution instructions' do
    it 'should create the directory if it does not exist given a hash' do
      control_dir = File.expand_path('.')
      test_dir1 = {
        :target => @@base_path / 'test1'
      }

      test_dir2 = {
        :target => @@base_path / 'test2'
      }

      resolver = WarningShot::DirectoryResolver.new WarningShot::Config.create,:directory, control_dir,test_dir1, test_dir2
      resolver.test!
      resolver.passed.length.should be(1)
      resolver.failed.length.should be(2)

      resolver.resolve!
      resolver.resolved.length.should be(2)

      File.directory?(test_dir1[:target]).should be(true)
      File.directory?(test_dir2[:target]).should be(true)

      FileUtils.rm_rf test_dir1[:target]
      FileUtils.rm_rf test_dir2[:target]
    end

    it 'should create the directory if it does not exist given a string' do
      control_dir = File.expand_path('.')
      test_dir1 = @@base_path / 'test1'
      test_dir2 = @@base_path / 'test2'
      resolver = WarningShot::DirectoryResolver.new WarningShot::Config.create,:directory, control_dir,test_dir1, test_dir2
      resolver.test!
      resolver.passed.length.should be(1)
      resolver.failed.length.should be(2)

      resolver.resolve!
      resolver.resolved.length.should be(2)
      File.directory?(test_dir1).should be(true)
      File.directory?(test_dir2).should be(true)

      FileUtils.rm_rf test_dir1
      FileUtils.rm_rf test_dir2
    end
  end # End healing enabled, instructions provided
end