Gem::Specification.new do |s|
  s.name        = "vinter"
  s.version     = "0.6.4"
  s.summary     = "A vim9script linter"
  s.description = "A linter for vim9script"
  s.authors     = ["Dan Bradbury"]
  s.email       = "dan.luckydaisy@gmail.com"
  s.files       = Dir["lib/**/*.rb", "bin/*", "README.md", "LICENSE"]
  s.homepage    = "https://github.com/DanBradbury/vinter"
  s.license     = "MIT"
  s.executables << "vinter"
  s.required_ruby_version = ">= 2.5.0"
end
