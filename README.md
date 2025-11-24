# Vinter

A Ruby gem that provides linting capabilities for Vim9 script files. This linter helps identify syntax errors and enforce best practices for Vim9 script. **Note: This linter only supports vim9script. Files must start with `vim9script` declaration.**

## Installation

Install the gem:

```bash
gem install vinter
```

## Configure
Vinter will read config files on the following priority order
- User config (`~/.vinter`)
- Project config (`path/to/proj/.vinter`)

```yaml
ignore_rules:
  - missing-type-annotation
  - missing-param-type
```

## Usage

### Command Line

Vim9script linter - checks vim9script files for syntax errors and best practices.

```bash
vinter path/to/your/script.vim
```

**Important:** All files must start with `vim9script` declaration. Legacy VimScript is not supported.

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

1. **missing-type-annotation**: Identifies variable declarations without type annotations
2. **missing-return-type**: Identifies functions without return type annotations
3. **missing-param-type**: Identifies function parameters without type annotations
4. **no-legacy-function**: Rejects legacy `function` syntax (use `def` instead)

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
