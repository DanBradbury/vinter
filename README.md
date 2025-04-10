# Vinter

A Ruby gem that provides linting capabilities for Vim9 script files. This linter helps identify syntax errors and enforce best practices for for Vim9 script.

## Features

- Lexical analysis of Vim9 script syntax
- Parsing of Vim9 script constructs
- Detection of common errors and code smells
- Command-line interface for easy integration with editors

## Installation

Install the gem:

```bash
gem install vinter
```

## Usage

### Command Line

Lint a Vim9 script file:

```bash
vinter path/to/your/script.vim
```

### Ruby API

```ruby
require 'vinter'

content = File.read('path/to/your/script.vim')
linter = Vinter::Linter.new
issues = linter.lint(content)

issues.each do |issue|
  puts "#{issue[:type]}: #{issue[:message]} at line #{issue[:line]}, column #{issue[:column]}"
end
```

## Supported Rules

The linter includes several built-in rules:

1. **missing-vim9script-declaration**: Checks if Vim9 script files start with the required `vim9script` declaration
2. **prefer-def-over-function**: Encourages using `def` instead of `function` in Vim9 scripts
3. **missing-type-annotation**: Identifies variable declarations without type annotations
4. **missing-return-type**: Identifies functions without return type annotations

## Adding Custom Rules

You can extend the linter with your own custom rules:

```ruby
linter = Vinter::Linter.new

# Define a custom rule
custom_rule = Vinter::Rule.new(
  "my-custom-rule",
  "Description of what the rule checks"
) do |ast|
  issues = []

  # Analyze the AST and identify issues
  # ...

  issues
end

# Register the custom rule
linter.register_rule(custom_rule)

# Run the linter with your custom rule
issues = linter.lint(content)
```

## Vim9 Script Resources

- [Vim9 Script Documentation](https://vimhelp.org/vim9.txt.html)
- [Upgrading to Vim9 Script](https://www.baeldung.com/linux/vim-script-upgrade)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request