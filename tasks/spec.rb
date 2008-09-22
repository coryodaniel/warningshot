desc "Run specs, run a specific spec with TASK=spec/path_to_spec.rb"
task :spec => [ "spec:default" ]

namespace :spec do
  OPTS_FILENAME = "./spec/spec.opts"
  ENV["WARNING_SHOT_ENV"] = 'test'
  
  if File.exist?(OPTS_FILENAME)
    SPEC_OPTS = ["--options", OPTS_FILENAME]
  else
    SPEC_OPTS = ["--color", "--format", "specdoc"]
  end
  
  Spec::Rake::SpecTask.new('default') do |t|
      t.spec_opts = SPEC_OPTS
    if(ENV['CLASS'])
      t.spec_files = ['test/spec/spec_helper.rb',"test/spec/**/#{ENV['CLASS']}_spec.rb"]
    else
      t.spec_files = ['test/spec/spec_helper.rb','test/spec/**/*_spec.rb']
    end
  end

  desc "Run unit specs, run a spec for a specific class with CLASS=klass"
  Spec::Rake::SpecTask.new('unit') do |t|
    t.spec_opts = SPEC_OPTS
    if(ENV['CLASS'])
      t.spec_files = ['test/spec/spec_helper.rb',"test/spec/unit/#{ENV['CLASS']}_spec.rb"]
    else
      t.spec_files = ['test/spec/spec_helper.rb','test/spec/unit/**/*_spec.rb']
    end
  end
  
  desc "Run integration specs, run a spec for a specific class with CLASS=klass"
  Spec::Rake::SpecTask.new('integration') do |t|
    t.spec_opts = SPEC_OPTS
    if(ENV['CLASS'])
      t.spec_files = ['test/spec/spec_helper.rb',"test/spec/integration/#{ENV['CLASS']}_spec.rb"]
    else
      t.spec_files = ['test/spec/spec_helper.rb','test/spec/integration/**/*_spec.rb']
    end
  end

  desc "Run all specs and output the result in html"
  Spec::Rake::SpecTask.new('html') do |t|
    t.spec_opts = ["--format", "html"]
    t.libs = ['lib']
    t.spec_files = ['test/spec/spec_helper.rb','test/spec/**/*_spec.rb']
  end

  desc "Run specs and check coverage with rcov"
  Spec::Rake::SpecTask.new('coverage') do |t|
    t.spec_opts = SPEC_OPTS
    t.spec_files = ['test/spec/spec_helper.rb','test/spec/**/*_spec.rb']
    t.libs = ['lib']
    t.rcov = true
    t.rcov_opts = ["--exclude 'config,spec'"]    
  end
end