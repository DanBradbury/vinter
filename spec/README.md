# Test Suite Documentation

This directory contains the test suite for Vinter, a Vim9 script linter.

## Structure

### Unit Tests (`spec/lib/vinter/`)

#### `lexer_spec.rb`
Tests for the lexer (tokenizer) that converts VimScript source code into tokens.

**Test Categories:**
- Keywords: VimScript language keywords (if, while, def, etc.)
- Identifiers: Variable and function names
- Operators: Arithmetic, comparison, and lambda operators
- String literals: Single and double-quoted strings
- Comments: Vim9 script comment syntax
- Complete statements: Full VimScript constructs

#### `parser_spec.rb`
Tests for the parser that builds an Abstract Syntax Tree (AST) from tokens.

**Test Categories:**
- **Legacy VimScript syntax**
  - Variable assignments (let statements)
  - Function definitions (function! syntax)
  - Comments (legacy string-style comments)
  - Output statements (echo, echoerr)
  
- **Vim9 script syntax**
  - Declarations (vim9script keyword)
  - Variable declarations (var, const with type annotations)
  - Function definitions (def with type annotations)
  - Import/export statements
  
- **Control flow structures**
  - Conditionals (if/else statements)
  - Loops (while statements)
  
- **Data structures**
  - Lists (array literals)
  - Lambda expressions
  - Filter commands
  
- **Error handling**
  - Syntax error detection

#### `linter_spec.rb`
Tests for the linter that validates VimScript code against style rules.

**Test Categories:**
- Rule validation
  - missing-vim9script-declaration
  - prefer-def-over-function
  - missing-type-annotation
  - missing-return-type
- Well-formed code validation
- Multiple issue detection
- Custom rule registration and execution

### Integration Tests (`spec/integration/`)

#### `integration_spec.rb`
End-to-end tests using real VimScript fixture files.

**Test Categories:**
- **Vim9 script linting**
  - Valid Vim9 scripts (no issues expected)
  - Invalid Vim9 scripts (multiple violations expected)
  
- **Legacy VimScript linting**
  - Legacy script compatibility
  - Backslash line continuations
  
- **Complex real-world files**
  - Copilot chat scripts
  - Vim features files

### Test Fixtures (`spec/fixtures/`)

Real VimScript files used for integration testing:
- `valid_vim9.vim` - Well-formed Vim9 script
- `invalid_vim9.vim` - Vim9 script with intentional violations
- `legacy.vim` - Legacy VimScript
- `isolated.vim` - Script with backslash continuations
- `copilot_chat.vim` - Real-world copilot integration
- `features.vim` - Complex feature demonstration

### Configuration

#### `spec_helper.rb`
RSpec configuration and shared test utilities.

**Configuration:**
- Expect syntax with chain clauses
- Mock verification
- Random test ordering
- Example status persistence
- Monkey patching disabled

**Helper Methods:**
- `print_ast` (commented) - For debugging AST structure

## Running Tests

### All tests
```bash
bundle exec rspec spec/
```

### Specific test file
```bash
bundle exec rspec spec/lib/vinter/parser_spec.rb
```

### With documentation format
```bash
bundle exec rspec spec/ --format documentation
```

### Single test
```bash
bundle exec rspec spec/lib/vinter/parser_spec.rb:5
```

## Test Conventions

1. **Descriptive test names**: Test descriptions clearly indicate what functionality is being tested
2. **Context organization**: Related tests grouped in logical contexts
3. **Helper lambdas**: DRY principle using `let` blocks for common operations
4. **Pending tests**: Known issues marked with `xit` and TODO comments
5. **Clear expectations**: Test assertions are explicit and well-documented

## Adding New Tests

When adding new tests:

1. Place unit tests in the appropriate `spec/lib/vinter/` file
2. Add integration tests to `spec/integration/integration_spec.rb`
3. Create new fixtures in `spec/fixtures/` if needed
4. Follow existing naming conventions and context structure
5. Ensure tests are focused and test one thing
6. Use descriptive test names that explain the expected behavior

## Known Issues

- Some legacy VimScript parsing features are not fully implemented (marked as pending)
- Syntax error detection for incomplete def functions needs enhancement
