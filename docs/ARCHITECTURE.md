# Vinter Architecture: VimScript Parsing Flow

This document describes how VimScript content is parsed and transformed into an Abstract Syntax Tree (AST) using Vinter's classes.

## Overview

Vinter uses a three-stage pipeline to process VimScript files:

1. **Lexer** - Tokenizes raw VimScript content into tokens
2. **Parser** - Transforms tokens into an Abstract Syntax Tree (AST)
3. **Linter** - Traverses the AST and applies lint rules

## Parsing Flow Diagram

```mermaid
flowchart TD
    subgraph Input
        A[VimScript Content<br/>Raw String]
    end

    subgraph Lexer["Lexer (lexer.rb)"]
        B[Initialize Lexer<br/>@input, @position, @line_num, @column]
        C[tokenize]
        D{Match Token Type}
        E[keyword<br/>if, def, function, var...]
        F[identifier<br/>variable/function names]
        G[operator<br/>+, -, *, /, ==, &&...]
        H[string<br/>single/double quoted]
        I[number<br/>int, float, hex, binary]
        J[comment<br/># or legacy]
        K[scoped variables<br/>s:, g:, b:, w:, a:, l:]
        L[special tokens<br/>braces, parens, etc.]
        M[Token Array<br/>type, value, line, column]
    end

    subgraph Parser["Parser (parser.rb)"]
        N[Initialize Parser<br/>@tokens, @position, @errors]
        O[parse]
        P[parse_program]
        Q{Parse Statement}
        
        subgraph Statements
            R[parse_if_statement]
            S[parse_while_statement]
            T[parse_for_statement]
            U[parse_def_function]
            V[parse_legacy_function]
            W[parse_variable_declaration]
            X[parse_let_statement]
            Y[parse_return_statement]
            Z[parse_import_statement]
            AA[parse_export_statement]
            AB[parse_try_statement]
            AC[parse_autocmd_statement]
            AD[parse_command_definition]
        end
        
        subgraph Expressions
            AE[parse_expression]
            AF[parse_binary_expression]
            AG[parse_unary_expression]
            AH[parse_primary_expression]
            AI[parse_function_call]
            AJ[parse_list_literal]
            AK[parse_dict_literal]
            AL[parse_lambda_expression]
        end
        
        AM[AST Node<br/>type, properties, line, column]
        AN[Program AST<br/>body: statements array]
    end

    subgraph Linter["Linter (linter.rb)"]
        AO[Initialize Linter<br/>@rules, @ignored_rules]
        AP[lint]
        AQ[traverse_ast]
        AR{Apply Rules}
        AS[missing-vim9script-declaration]
        AT[prefer-def-over-function]
        AU[missing-type-annotation]
        AV[missing-return-type]
        AW[missing-param-type]
        AX[Issues Array<br/>type, message, line, column]
    end

    subgraph Output
        AY[Lint Results<br/>errors + warnings + rule issues]
    end

    %% Main Flow
    A --> B
    B --> C
    C --> D
    D --> E & F & G & H & I & J & K & L
    E & F & G & H & I & J & K & L --> M
    
    M --> N
    N --> O
    O --> P
    P --> Q
    Q --> R & S & T & U & V & W & X & Y & Z & AA & AB & AC & AD
    R & S & T & U & V & W & X & Y & Z & AA & AB & AC & AD --> AE
    AE --> AF
    AF --> AG
    AG --> AH
    AH --> AI & AJ & AK & AL
    AI & AJ & AK & AL --> AM
    AM --> AN
    
    AN --> AO
    AO --> AP
    AP --> AQ
    AQ --> AR
    AR --> AS & AT & AU & AV & AW
    AS & AT & AU & AV & AW --> AX
    
    AX --> AY
```

## Detailed Component Flow

```mermaid
sequenceDiagram
    participant C as Client Code
    participant L as Linter
    participant Lex as Lexer
    participant P as Parser
    participant R as Rules
    
    C->>L: lint(content)
    L->>Lex: new(content)
    L->>Lex: tokenize()
    
    Note over Lex: Iterate through input
    loop For each character
        Lex->>Lex: Match token pattern
        Lex->>Lex: Create token hash
        Lex->>Lex: Update position
    end
    Lex-->>L: tokens[]
    
    L->>P: new(tokens, content)
    L->>P: parse()
    P->>P: parse_program()
    
    Note over P: Build AST
    loop For each token
        P->>P: parse_statement()
        P->>P: parse_expression()
        P->>P: Create AST node
    end
    P-->>L: {ast, errors, warnings}
    
    Note over L: Apply lint rules
    loop For each rule
        L->>R: apply(ast)
        R->>L: traverse_ast()
        R-->>L: issues[]
    end
    
    L-->>C: all_issues[]
```

## Token Structure

```mermaid
classDiagram
    class Token {
        +Symbol type
        +String value
        +Integer line
        +Integer column
    }
    
    class TokenTypes {
        <<enumeration>>
        keyword
        identifier
        operator
        number
        string
        comment
        script_local
        global_variable
        buffer_local
        window_local
        tab_local
        arg_variable
        local_variable
        option_variable
        special_variable
        brace_open
        brace_close
        paren_open
        paren_close
        bracket_open
        bracket_close
        colon
        comma
        ellipsis
    }
    
    Token --> TokenTypes : type
```

## AST Node Structure

```mermaid
classDiagram
    class ASTNode {
        +Symbol type
        +Integer line
        +Integer column
    }
    
    class Program {
        +Array~ASTNode~ body
    }
    
    class DefFunction {
        +String name
        +Array~Parameter~ params
        +String return_type
        +Array~ASTNode~ body
    }
    
    class LegacyFunction {
        +String name
        +Array~Parameter~ params
        +Boolean has_bang
        +Array~String~ attributes
        +Array~ASTNode~ body
    }
    
    class VariableDeclaration {
        +String var_type
        +String name
        +String var_type_annotation
        +ASTNode initializer
    }
    
    class IfStatement {
        +ASTNode condition
        +Array~ASTNode~ then_branch
        +Array~ASTNode~ else_branch
    }
    
    class WhileStatement {
        +ASTNode condition
        +Array~ASTNode~ body
    }
    
    class ForStatement {
        +Token loop_var
        +ASTNode iterable
        +Array~ASTNode~ body
    }
    
    class FunctionCall {
        +String name
        +Array~ASTNode~ arguments
    }
    
    class BinaryExpression {
        +String operator
        +ASTNode left
        +ASTNode right
    }
    
    class Literal {
        +Any value
        +Symbol token_type
    }
    
    ASTNode <|-- Program
    ASTNode <|-- DefFunction
    ASTNode <|-- LegacyFunction
    ASTNode <|-- VariableDeclaration
    ASTNode <|-- IfStatement
    ASTNode <|-- WhileStatement
    ASTNode <|-- ForStatement
    ASTNode <|-- FunctionCall
    ASTNode <|-- BinaryExpression
    ASTNode <|-- Literal
```

## Example: Parsing a Simple Function

Given this VimScript:

```vim
vim9script
def Greet(name: string): string
    return "Hello, " .. name
enddef
```

### Step 1: Lexer Output

The following shows a simplified representation of the key tokens. The actual tokenization also includes whitespace tracking for line/column positions:

```mermaid
flowchart LR
    subgraph Tokens
        T1["keyword: vim9script"]
        T2["keyword: def"]
        T3["identifier: Greet"]
        T4["paren_open: ("]
        T5["identifier: name"]
        T6["colon: :"]
        T7["identifier: string"]
        T8["paren_close: )"]
        T9["colon: :"]
        T10["identifier: string"]
        T11["keyword: return"]
        T12["string: 'Hello, '"]
        T13["operator: .."]
        T14["identifier: name"]
        T15["keyword: enddef"]
    end
    
    T1 --> T2 --> T3 --> T4 --> T5 --> T6 --> T7 --> T8 --> T9 --> T10 --> T11 --> T12 --> T13 --> T14 --> T15
```

### Step 2: Parser Output (AST)

```mermaid
flowchart TD
    P[Program] --> V[vim9script_declaration]
    P --> D[def_function]
    D --> N["name: Greet"]
    D --> Params["params[]"]
    Params --> Param1["parameter<br/>name: 'name'<br/>param_type: 'string'"]
    D --> RT["return_type: string"]
    D --> Body["body[]"]
    Body --> Ret[return_statement]
    Ret --> BE[binary_expression]
    BE --> Op["operator: .."]
    BE --> Left["literal<br/>value: 'Hello, '"]
    BE --> Right["identifier<br/>name: name"]
```

## Linter Rule Traversal

```mermaid
flowchart TD
    A[AST Root] --> B{traverse_ast}
    B --> C[Visit Node]
    C --> D{Node Type?}
    
    D -->|program| E[Check vim9script declaration]
    D -->|legacy_function| F[Report prefer-def-over-function]
    D -->|variable_declaration| G[Check type annotation]
    D -->|def_function| H[Check return type]
    D -->|parameter| I[Check param type]
    
    E --> J{Has Children?}
    F --> J
    G --> J
    H --> J
    I --> J
    
    J -->|Yes| K[Recurse into children]
    K --> B
    J -->|No| L[Continue to next sibling]
    L --> B
```

## Class Relationships

```mermaid
classDiagram
    class Vinter {
        +VERSION: String
    }
    
    class Lexer {
        -String @input
        -Array @tokens
        -Integer @position
        -Integer @line_num
        -Integer @column
        +initialize(input)
        +tokenize() Array
        -should_parse_as_regex() Boolean
        -find_unescaped_newline(chunk) Integer
    }
    
    class Parser {
        -Array @tokens
        -Integer @position
        -Array @errors
        -Array @warnings
        -String @source_text
        +initialize(tokens, source_text)
        +parse() Hash
        -parse_program() Hash
        -parse_statement() Hash
        -parse_expression() Hash
    }
    
    class Linter {
        -Array @rules
        -Array @ignored_rules
        -String @config_path
        +initialize(config_path)
        +register_rule(rule)
        +lint(content) Array
        -traverse_ast(node, block)
        -find_config_path() String
        -load_config()
    }
    
    class Rule {
        +String id
        +String description
        -Block @check
        +initialize(id, description, block)
        +apply(ast) Array
    }
    
    class CLI {
        -Linter @linter
        +initialize()
        +run(args) Integer
        -find_vim_files(directory) Array
    }
    
    Vinter --> Lexer
    Vinter --> Parser
    Vinter --> Linter
    Vinter --> CLI
    Linter --> Rule
    Linter --> Lexer : uses
    Linter --> Parser : uses
    CLI --> Linter : uses
```

## Usage Example

```ruby
require 'vinter'

# Method 1: Using CLI
cli = Vinter::CLI.new
exit_code = cli.run(['path/to/script.vim'])

# Method 2: Using Linter directly
content = File.read('script.vim')
linter = Vinter::Linter.new
issues = linter.lint(content)

# Method 3: Using individual components
lexer = Vinter::Lexer.new(content)
tokens = lexer.tokenize

parser = Vinter::Parser.new(tokens, content)
result = parser.parse
# result = { ast: {...}, errors: [...], warnings: [...] }
```

## Summary

The Vinter parsing pipeline follows a classic compiler frontend architecture:

1. **Lexical Analysis (Lexer)**: Converts raw source code into a stream of tokens, handling VimScript-specific syntax like scoped variables (`s:`, `g:`), string literals, and operators.

2. **Syntactic Analysis (Parser)**: Builds a hierarchical AST from tokens using recursive descent parsing. Handles both legacy VimScript and Vim9 script syntax.

3. **Static Analysis (Linter)**: Traverses the AST to check for style violations and potential issues, using configurable rules.

This architecture allows for:
- **Extensibility**: New rules can be added without modifying the parser
- **Configurability**: Rules can be ignored via config files
- **Detailed Error Reporting**: Line and column information preserved through all stages
