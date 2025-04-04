Gem::Specification.new do |s|
  s.name        = "vinter"
  s.version     = "0.1.0"
  s.summary     = "A linter for Vim9 script"
  s.description = "A linter for the Vim9 script language, helping to identify issues and enforce best practices"
  s.authors     = ["Dan Bradbury"]
  s.email       = "dan.luckydaisy@gmail.com"
  s.files       = Dir["lib/**/*.rb", "bin/*", "README.md", "LICENSE"]
  s.homepage    = "https://github.com/DanBradbury/vinter"
  s.license     = "MIT"
  s.executables << "vinter"
  s.required_ruby_version = ">= 2.5.0"
end
