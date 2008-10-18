describe WarningShot::TemplateGenerator do

  before :all do
    @test_path = $test_data / 'yaml_configs'
  end

  after :all do
    FileUtils.rm_rf @test_path
  end
  
  it "should be able to generate templates" do
    WarningShot::TemplateGenerator.respond_to?(:create).should be(true)
    WarningShot::TemplateGenerator.create(@test_path)
  end
  
  it "should have generate YAML config files" do
    yaml_files = Dir[@test_path / WarningShot::ConfigExt]
    yaml_files.empty?.should be(false)
  end
  
end