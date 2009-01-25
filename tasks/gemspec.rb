spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = WarningShot::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Cory ODaniel"]
  s.date = %q{2008-10-15}
  s.default_executable = %q{warningshot}
  s.description = "WarningShot provides a simple YAML configurable interface to define dependencies that an application or machine depends on, then it builds them for you."
  s.email = %q{warningshot@coryodaniel.com.com}
  s.executables = ["warningshot"]
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = %w(LICENSE README Rakefile TODO CHANGELOG CONTRIBUTORS)
  s.files += Dir["{doc,bin,test,lib,tasks,test,templates,images}/**/*"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/coryodaniel/warningshot}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
  s.rubygems_version = %q{1.3.0}
  s.summary = s.description
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
