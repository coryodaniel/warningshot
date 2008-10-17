spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = WarningShot::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Cory ODaniel"]
  s.date = %q{2008-10-15}
  s.default_executable = %q{warningshot}
  s.description = %q{WarningShot Dependency Resolution Framework.}
  s.email = %q{warningshot@coryodaniel.com.com}
  s.executables = ["warningshot"]
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = %w(LICENSE README Rakefile TODO CHANGELOG CONTRIBUTORS)
  s.files += Dir["{doc,bin,test,lib,tasks,test,templates}/**/*"]
  s.has_rdoc = true
  s.homepage = %q{http://warningshot.lighthouseapp.com}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
  s.rubygems_version = %q{1.2.0}
  s.summary = s.description

  #if s.respond_to? :specification_version then
  #  current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
  #  s.specification_version = 2

  #  if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
  #    #s.add_runtime_dependency(%q<gem>, [">= version"])
  #  else
  #    #s.add_runtime_dependency(%q<gem>, [">= version"])
  #  end
  #else
  #  #s.add_runtime_dependency(%q<gem>, [">= version"])
  #end
end

Rake::GemPackageTask.new(spec) do |package|
  package.gem_spec = spec
end

desc "Run :package and install the resulting .gem"
task :install => :package do
  sh %{sudo gem install --local pkg/#{NAME}-#{WarningShot::VERSION}.gem --no-rdoc --no-ri}
end

desc "Run :clean and uninstall the .gem"
task :uninstall => :clean do
  sh %{sudo gem uninstall #{NAME}}
end
