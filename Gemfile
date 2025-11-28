source "https://rubygems.org"

gemspec

# Development dependencies
group :development do
  gem "rake", "~> 13.0"
  gem "bundler", "~> 2.3"
end

# Testing dependencies
group :test do
  gem "rspec", "~> 3.12"
  gem "simplecov", "~> 0.21", require: false
  gem "rubocop", "~> 1.50", require: false
  gem "rubocop-rspec", "~> 2.20", require: false
end

# Documentation dependencies
group :docs do
  gem "yard", "~> 0.9"
  gem "redcarpet", "~> 3.6", platforms: :ruby # Markdown parser for YARD
end

# Optional dependencies for development comfort
group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
end
gem "pry"
gem "httparty"
