module Vinter
  class Parser
    def initialize(tokens)
      @tokens = tokens
      @position = 0
      @errors = []
      @warnings = []
    end

    def parse
      result = parse_program
      {
        ast: result,
        errors: @errors,
        warnings: @warnings
      }
    end

    private

    def current_token
      @tokens[@position]
    end

    def peek_token(offset = 1)
      @tokens[@position + offset]
    end

    def advance
      token = current_token
      @position += 1 if @position < @tokens.length
      token
    end

    def expect(type)
      if current_token && current_token[:type] == type
        token = current_token
        advance
        return token
      else
        expected = type
        found = current_token ? current_token[:type] : "end of input"
        line = current_token ? current_token[:line] : 0
        column = current_token ? current_token[:column] : 0
        error = "Expected #{expected} but found #{found}"
        @errors << { message: error, position: @position, line: line, column: column }
        nil
      end
    end

    def parse_program
      statements = []

      # Check for vim9script declaration
      if current_token && current_token[:type] == :keyword && current_token[:value] == 'vim9script'
        statements << { type: :vim9script_declaration }
        advance
      end

      while @position < @tokens.length
        stmt = parse_statement
        statements << stmt if stmt
      end

      { type: :program, body: statements }
    end

    def parse_statement
      if !current_token
        return nil
      end

      if current_token[:type] == :keyword
        case current_token[:value]
        when 'if'
          parse_if_statement
        when 'while'
          parse_while_statement
        when 'for'
          parse_for_statement
        when 'def'
          parse_def_function
        when 'function'
          parse_legacy_function
        when 'return'
          parse_return_statement
        when 'var', 'const', 'final'
          parse_variable_declaration
        when 'import'
          parse_import_statement
        when 'export'
          parse_export_statement
        when 'vim9script'
          token = advance # Skip 'vim9script'
          { type: :vim9script_declaration, line: token[:line], column: token[:column] }
        else
          @warnings << {
            message: "Unexpected keyword: #{current_token[:value]}",
            position: @position,
            line: current_token[:line],
            column: current_token[:column]
          }
          advance
          nil
        end
      elsif current_token[:type] == :identifier
        if current_token[:value] == "echo"
          parse_echo_statement
        else
          parse_expression_statement
        end
      elsif current_token[:type] == :comment
        parse_comment
      else
        @warnings << {
          message: "Unexpected token type: #{current_token[:type]}",
          position: @position,
          line: current_token[:line],
          column: current_token[:column]
        }
        advance
        nil
      end
    end

    def parse_echo_statement
      token = advance #Skip 'echo'
      line = token[:line]
      column = token[:column]

      expression = parse_expression

      {
        type: :echo_statement,
        expression: expression,
        line: line,
        column: column
      }
    end

    def parse_comment
      comment = current_token[:value]
      line = current_token[:line]
      column = current_token[:column]
      advance
      { type: :comment, value: comment, line: line, column: column }
    end

    def parse_if_statement
      token = advance # Skip 'if'
      line = token[:line]
      column = token[:column]
      condition = parse_expression

      then_branch = []
      else_branch = []

      # Parse statements until we hit 'else', 'elseif', or 'endif'
      while @position < @tokens.length
        if current_token[:type] == :keyword &&
           ['else', 'elseif', 'endif'].include?(current_token[:value])
          break
        end

        stmt = parse_statement
        then_branch << stmt if stmt
      end

      # Check for else/elseif
      if current_token && current_token[:type] == :keyword
        if current_token[:value] == 'else'
          advance # Skip 'else'

          # Parse statements until 'endif'
          while @position < @tokens.length
            if current_token[:type] == :keyword && current_token[:value] == 'endif'
              break
            end

            stmt = parse_statement
            else_branch << stmt if stmt
          end
        elsif current_token[:value] == 'elseif'
          # This is a simplified handling - elseif should be treated as a nested if
          else_branch << parse_if_statement
        end
      end

      # Expect endif
      expect(:keyword) # This should be 'endif'

      {
        type: :if_statement,
        condition: condition,
        then_branch: then_branch,
        else_branch: else_branch,
        line: line,
        column: column
      }
    end

    def parse_while_statement
      token = advance # Skip 'while'
      line = token[:line]
      column = token[:column]
      condition = parse_expression

      body = []

      # Parse statements until we hit 'endwhile'
      while @position < @tokens.length
        if current_token[:type] == :keyword && current_token[:value] == 'endwhile'
          break
        end

        stmt = parse_statement
        body << stmt if stmt
      end

      # Expect endwhile
      expect(:keyword) # This should be 'endwhile'

      {
        type: :while_statement,
        condition: condition,
        body: body,
        line: line,
        column: column
      }
    end

    def parse_for_statement
      token = advance # Skip 'for'
      line = token[:line]
      column = token[:column]

      # Parse the loop variable(s)
      if current_token && current_token[:type] == :paren_open
        # Handle tuple assignment: for (key, val) in dict
        advance # Skip '('

        loop_vars = []

        loop do
          if current_token && current_token[:type] == :identifier
            loop_vars << advance[:value]
          else
            @errors << {
              message: "Expected identifier in for loop variables",
              position: @position,
              line: current_token ? current_token[:line] : 0,
              column: current_token ? current_token[:column] : 0
            }
            break
          end

          if current_token && current_token[:type] == :comma
            advance # Skip ','
          else
            break
          end
        end

        expect(:paren_close) # Skip ')'

        if !current_token || (current_token[:type] != :identifier || current_token[:value] != 'in')
          @errors << {
            message: "Expected 'in' after for loop variables",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
        else
          advance # Skip 'in'
        end

        iterable = parse_expression

        # Parse the body until 'endfor'
        body = []
        while @position < @tokens.length
          if current_token[:type] == :keyword && current_token[:value] == 'endfor'
            break
          end

          stmt = parse_statement
          body << stmt if stmt
        end

        # Expect endfor
        expect(:keyword) # This should be 'endfor'

        return {
          type: :for_statement,
          loop_vars: loop_vars,
          iterable: iterable,
          body: body,
          line: line,
          column: column
        }
      else
        # Simple for var in list
        if !current_token || current_token[:type] != :identifier
          @errors << {
            message: "Expected identifier as for loop variable",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
          return nil
        end

        loop_var = advance[:value]

        if !current_token || (current_token[:type] != :identifier || current_token[:value] != 'in')
          @errors << {
            message: "Expected 'in' after for loop variable",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
        else
          advance # Skip 'in'
        end

        iterable = parse_expression

        # Parse the body until 'endfor'
        body = []
        while @position < @tokens.length
          if current_token[:type] == :keyword && current_token[:value] == 'endfor'
            break
          end

          stmt = parse_statement
          body << stmt if stmt
        end

        # Expect endfor
        expect(:keyword) # This should be 'endfor'

        return {
          type: :for_statement,
          loop_var: loop_var,
          iterable: iterable,
          body: body,
          line: line,
          column: column
        }
      end
    end

    def parse_def_function
      token = advance # Skip 'def'
      line = token[:line]
      column = token[:column]

      name = expect(:identifier)

      # Parse parameter list
      expect(:paren_open)
      params = parse_parameter_list
      expect(:paren_close)

      # Parse optional return type
      return_type = nil
      if current_token && current_token[:type] == :colon
        advance # Skip ':'
        return_type = parse_type
      end

      # Parse function body
      body = []
      while @position < @tokens.length
        if current_token[:type] == :keyword && current_token[:value] == 'enddef'
          break
        end

        stmt = parse_statement
        body << stmt if stmt
      end

      # Expect enddef
      expect(:keyword) # This should be 'enddef'

      {
        type: :def_function,
        name: name ? name[:value] : nil,
        params: params,
        return_type: return_type,
        body: body,
        line: line,
        column: column
      }
    end



    def parse_parameter_list
      params = []

      # Empty parameter list
      if current_token && current_token[:type] == :paren_close
        return params
      end

      loop do
        # Check for variable args
        if current_token && current_token[:type] == :ellipsis
          ellipsis_token = advance

          # Parse type for variable args if present
          param_type = nil
          if current_token && current_token[:type] == :colon
            advance # Skip ':'
            param_type = parse_type
          end

          params << {
            type: :var_args,
            param_type: param_type,
            line: ellipsis_token[:line],
            column: ellipsis_token[:column]
          }
          break
        end

        # Get parameter name
        if !current_token || current_token[:type] != :identifier
          @errors << {
            message: "Expected parameter name",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
          break
        end

        param_name = advance

        # Check for type annotation
        param_type = nil
        if current_token && current_token[:type] == :colon
          advance # Skip ':'
          param_type = parse_type
        end

        # Check for default value
        default_value = nil
        if current_token && current_token[:type] == :operator && current_token[:value] == '='
          advance # Skip '='
          default_value = parse_expression
        end

        params << {
          type: :parameter,
          name: param_name[:value],
          param_type: param_type,
          optional: false, # Set this based on default value
          default_value: default_value,
          line: param_name[:line],
          column: param_name[:column]
        }

        if current_token && current_token[:type] == :comma
          advance
        else
          break
        end
      end

      params
    end

    def parse_type
      if current_token && current_token[:type] == :identifier
        type_name = advance

        # Handle generic types like list<string>
        if current_token && current_token[:type] == :operator && current_token[:value] == '<'
          advance # Skip '<'
          inner_type = parse_type
          expect(:operator) # This should be '>'

          return {
            type: :generic_type,
            base_type: type_name[:value],
            inner_type: inner_type,
            line: type_name[:line],
            column: type_name[:column]
          }
        end

        return type_name[:value]
      else
        @errors << {
          message: "Expected type identifier",
          position: @position,
          line: current_token ? current_token[:line] : 0,
          column: current_token ? current_token[:column] : 0
        }
        advance
        return "unknown"
      end
    end

    def parse_variable_declaration
      var_type_token = advance # Skip 'var', 'const', or 'final'
      var_type = var_type_token[:value]
      line = var_type_token[:line]
      column = var_type_token[:column]

      if !current_token || current_token[:type] != :identifier
        @errors << {
          message: "Expected variable name",
          position: @position,
          line: current_token ? current_token[:line] : 0,
          column: current_token ? current_token[:column] : 0
        }
        return nil
      end

      name_token = advance
      name = name_token[:value]

      # Parse optional type annotation
      var_type_annotation = nil
      if current_token && current_token[:type] == :colon
        advance # Skip ':'
        var_type_annotation = parse_type
      end

      # Parse initializer if present
      initializer = nil
      if current_token && current_token[:type] == :operator && current_token[:value] == '='
        advance # Skip '='
        initializer = parse_expression
      end

      {
        type: :variable_declaration,
        var_type: var_type,
        name: name,
        var_type_annotation: var_type_annotation,
        initializer: initializer,
        line: line,
        column: column
      }
    end

    def parse_return_statement
      token = advance # Skip 'return'
      line = token[:line]
      column = token[:column]

      value = nil
      if @position < @tokens.length && current_token[:type] != :semicolon
        value = parse_expression
      end

      {
        type: :return_statement,
        value: value,
        line: line,
        column: column
      }
    end

    def parse_expression_statement
      # Check if this is an assignment using a compound operator
      if current_token && current_token[:type] == :identifier
        variable_name = current_token[:value]
        variable_token = current_token
        advance  # Move past the identifier

        if current_token && current_token[:type] == :compound_operator
          operator = current_token[:value]
          operator_token = current_token
          advance  # Move past the operator

          right = parse_expression

          return {
            type: :compound_assignment,
            operator: operator,
            target: {
              type: :identifier,
              name: variable_name,
              line: variable_token[:line],
              column: variable_token[:column]
            },
            value: right,
            line: operator_token[:line],
            column: operator_token[:column]
          }
        end

        # If it wasn't a compound assignment, backtrack
        @position -= 1
      end

      # Regular expression statement handling
      expr = parse_expression
      {
        type: :expression_statement,
        expression: expr,
        line: expr ? expr[:line] : 0,
        column: expr ? expr[:column] : 0
      }
    end

    def parse_expression
      return parse_binary_expression
    end

    def parse_binary_expression(precedence = 0)
      left = parse_primary_expression

      while current_token && current_token[:type] == :operator &&
            operator_precedence(current_token[:value]) >= precedence
        op_token = advance
        op = op_token[:value]
        op_precedence = operator_precedence(op)

        right = parse_binary_expression(op_precedence + 1)

        left = {
          type: :binary_expression,
          operator: op,
          left: left,
          right: right,
          line: op_token[:line],
          column: op_token[:column]
        }
      end

      return left
    end

    def operator_precedence(op)
      case op
      when '..'  # String concatenation
        1
      when '||'  # Logical OR
        2
      when '&&'  # Logical AND
        3
      when '==', '!=', '>', '<', '>=', '<='  # Comparison
        4
      when '+', '-'  # Addition, subtraction
        5
      when '*', '/', '%'  # Multiplication, division, modulo
        6
      else
        0
      end
    end

    def parse_primary_expression
      return nil unless current_token

      token = current_token
      line = token[:line]
      column = token[:column]

      case token[:type]
      when :number
        advance
        {
          type: :literal,
          value: token[:value],
          token_type: :number,
          line: line,
          column: column
        }
      when :string
        advance
        {
          type: :literal,
          value: token[:value],
          token_type: :string,
          line: line,
          column: column
        }
      when :identifier
        advance

        # Check if this is a function call
        if current_token && current_token[:type] == :paren_open
          return parse_function_call(token[:value], line, column)
        end

        {
          type: :identifier,
          name: token[:value],
          line: line,
          column: column
        }
      when :paren_open
        if is_lambda_expression
          return parse_lambda_expression(line, column)
        else
          advance  # Skip '('
          expr = parse_expression
          expect(:paren_close)  # Expect and skip ')'
          return expr
        end
      when :bracket_open
        return parse_list_literal(line, column)
      when :brace_open
        return parse_dict_literal(line, column)
      else
        @errors << {
          message: "Unexpected token in expression: #{token[:type]}",
          position: @position,
          line: line,
          column: column
        }
        advance
        return nil
      end
    end

    def is_lambda_expression
      # Save the current position
      original_position = @position

      # Skip the opening parenthesis
      advance if current_token && current_token[:type] == :paren_open

      # Check for a parameter list followed by => or ): =>
      has_params = false
      has_arrow = false

      # Skip past parameters
      loop do
        break if !current_token

        if current_token[:type] == :identifier
          has_params = true
          advance

          # Either comma for another parameter, or close paren
          if current_token && current_token[:type] == :comma
            advance
          elsif current_token && current_token[:type] == :paren_close
            advance
            break
          else
            # Not a valid lambda parameter list
            break
          end
        elsif current_token[:type] == :paren_close
          # Empty parameter list is valid
          advance
          break
        else
          # Not a valid lambda parameter list
          break
        end
      end

      # After parameters, check for either => or ): =>
      if current_token
        if current_token[:type] == :operator && current_token[:value] == '=>'
          has_arrow = true
        elsif current_token[:type] == :colon
          # There might be a return type annotation
          advance
          # Skip the type
          advance if current_token && current_token[:type] == :identifier
          # Check for the arrow
          has_arrow = current_token && current_token[:type] == :operator && current_token[:value] == '=>'
        end
      end

      # Reset position to where we started
      @position = original_position

      return has_params && has_arrow
    end

    def parse_lambda_expression(line, column)
      expect(:paren_open)  # Skip '('

      params = []

      # Parse parameters
      unless current_token && current_token[:type] == :paren_close
        loop do
          if current_token && current_token[:type] == :identifier
            param_name = current_token[:value]
            param_token = current_token
            advance

            # Check for type annotation
            param_type = nil
            if current_token && current_token[:type] == :colon
              advance  # Skip ':'
              param_type = parse_type
            end

            params << {
              type: :parameter,
              name: param_name,
              param_type: param_type,
              line: param_token[:line],
              column: param_token[:column]
            }
          else
            @errors << {
              message: "Expected parameter name in lambda expression",
              position: @position,
              line: current_token ? current_token[:line] : 0,
              column: current_token ? current_token[:column] : 0
            }
            break
          end

          if current_token && current_token[:type] == :comma
            advance  # Skip comma
          else
            break
          end
        end
      end

      expect(:paren_close)  # Skip ')'

      # Check for return type annotation
      return_type = nil
      if current_token && current_token[:type] == :colon
        advance  # Skip ':'
        return_type = parse_type
      end

      # Expect the arrow '=>'
      arrow_found = false
      if current_token && current_token[:type] == :operator && current_token[:value] == '=>'
        arrow_found = true
        advance  # Skip '=>'
      else
        @errors << {
          message: "Expected '=>' in lambda expression",
          position: @position,
          line: current_token ? current_token[:line] : 0,
          column: current_token ? current_token[:column] : 0
        }
      end

      # Parse the lambda body
      body = arrow_found ? parse_expression : nil

      return {
        type: :lambda_expression,
        params: params,
        return_type: return_type,
        body: body,
        line: line,
        column: column
      }
    end

    def parse_dict_literal(line, column)
      advance  # Skip '{'
      entries = []

      # Empty dictionary
      if current_token && current_token[:type] == :brace_close
        advance  # Skip '}'
        return {
          type: :dict_literal,
          entries: entries,
          line: line,
          column: column
        }
      end

      # Parse dictionary entries
      loop do
        # Parse key (string or identifier)
        key = nil
        if current_token && (current_token[:type] == :string || current_token[:type] == :identifier)
          key = current_token[:type] == :string ? current_token[:value] : current_token[:value]
          advance  # Skip key
        else
          @errors << {
            message: "Expected string or identifier as dictionary key",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
          break
        end

        # Expect colon
        expect(:colon)

        # Parse value
        value = parse_expression

        entries << {
          key: key,
          value: value
        }

        if current_token && current_token[:type] == :comma
          advance  # Skip comma
          # Allow trailing comma
          break if current_token && current_token[:type] == :brace_close
        else
          break
        end
      end

      expect(:brace_close)  # Expect and skip '}'

      {
        type: :dict_literal,
        entries: entries,
        line: line,
        column: column
      }
    end

    def parse_list_literal(line, column)
      advance  # Skip '['
      elements = []

      # Empty list
      if current_token && current_token[:type] == :bracket_close
        advance  # Skip ']'
        return {
          type: :list_literal,
          elements: elements,
          line: line,
          column: column
        }
      end

      # Parse list elements
      loop do
        element = parse_expression
        elements << element if element

        if current_token && current_token[:type] == :comma
          advance  # Skip comma
          # Allow trailing comma
          break if current_token && current_token[:type] == :bracket_close
        else
          break
        end
      end

      expect(:bracket_close)  # Expect and skip ']'

      {
        type: :list_literal,
        elements: elements,
        line: line,
        column: column
      }
    end

    def parse_function_call(name, line, column)
      expect(:paren_open)

      args = []

      # Parse arguments
      unless current_token && current_token[:type] == :paren_close
        loop do
          # Check if the argument might be a lambda expression
          if current_token && current_token[:type] == :paren_open && is_lambda_expression
            arg = parse_lambda_expression(current_token[:line], current_token[:column])
          else
            arg = parse_expression
          end

          args << arg if arg

          break unless current_token && current_token[:type] == :comma
          advance  # Skip comma
        end
      end

      expect(:paren_close)

      {
        type: :function_call,
        name: name,
        arguments: args,
        line: line,
        column: column
      }
    end

    def parse_import_statement
      token = advance # Skip 'import'
      line = token[:line]
      column = token[:column]

      # Handle 'import autoload'
      is_autoload = false
      module_name = nil
      path = nil

      if current_token && current_token[:type] == :identifier && current_token[:value] == 'autoload'
        is_autoload = true
        module_name = advance[:value]  # Store "autoload" as the module name

        # After "autoload" keyword, expect a string path
        if current_token && current_token[:type] == :string
          path = current_token[:value]
          advance
        else
          @errors << {
            message: "Expected string path after 'autoload'",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
        end
      else
        # Regular import with a string path
        if current_token && current_token[:type] == :string
          path = current_token[:value]

          # Extract module name from the path
          # This is simplified logic - you might need more complex extraction
          module_name = path.gsub(/['"]/, '').split('/').last.split('.').first

          advance
        else
          # Handle other import formats
          module_expr = parse_expression()
          if module_expr && module_expr[:type] == :literal && module_expr[:token_type] == :string
            path = module_expr[:value]
            module_name = path.gsub(/['"]/, '').split('/').last.split('.').first
          end
        end
      end

      # Handle 'as name'
      as_name = nil
      if current_token && current_token[:type] == :identifier && current_token[:value] == 'as'
        advance # Skip 'as'
        if current_token && current_token[:type] == :identifier
          as_name = advance[:value]
        else
          @errors << {
            message: "Expected identifier after 'as'",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
        end
      end

      {
        type: :import_statement,
        module: module_name,
        path: path,
        is_autoload: is_autoload,
        as_name: as_name,
        line: line,
        column: column
      }
    end
    def parse_export_statement
      token = advance # Skip 'export'
      line = token[:line]
      column = token[:column]

      # Export can be followed by var/const/def/function declarations
      if !current_token
        @errors << {
          message: "Expected declaration after export",
          position: @position,
          line: line,
          column: column
        }
        return nil
      end

      exported_item = nil

      if current_token[:type] == :keyword
        case current_token[:value]
        when 'def'
          exported_item = parse_def_function
        when 'function'
          exported_item = parse_legacy_function
        when 'var', 'const', 'final'
          exported_item = parse_variable_declaration
        when 'class'
          # Handle class export when implemented
          @errors << {
            message: "Class export not implemented yet",
            position: @position,
            line: current_token[:line],
            column: current_token[:column]
          }
          advance
          return nil
        else
          @errors << {
            message: "Unexpected keyword after export: #{current_token[:value]}",
            position: @position,
            line: current_token[:line],
            column: current_token[:column]
          }
          advance
          return nil
        end
      else
        @errors << {
          message: "Expected declaration after export",
          position: @position,
          line: current_token[:line],
          column: current_token[:column]
        }
        advance
        return nil
      end

      {
        type: :export_statement,
        export: exported_item,
        line: line,
        column: column
      }
    end

    def parse_legacy_function
      token = advance # Skip 'function'
      line = token[:line]
      column = token[:column]

      # Check for bang (!) in function definition
      has_bang = false
      if current_token && current_token[:type] == :operator && current_token[:value] == '!'
        has_bang = true
        advance # Skip '!'
      end

      name = expect(:identifier)

      # Parse parameter list
      expect(:paren_open)
      params = parse_parameter_list_legacy
      expect(:paren_close)

      # Check for optional attributes (range, dict, abort, closure)
      attributes = []
      while current_token && current_token[:type] == :identifier
        if ['range', 'dict', 'abort', 'closure'].include?(current_token[:value])
          attributes << advance[:value]
        else
          break
        end
      end

      # Parse function body
      body = []
      while @position < @tokens.length
        if current_token && current_token[:type] == :keyword &&
           ['endfunction', 'endfunc'].include?(current_token[:value])
          break
        end

        stmt = parse_statement
        body << stmt if stmt
      end

      # Expect endfunction/endfunc
      end_token = advance # This should be 'endfunction' or 'endfunc'
      if end_token && end_token[:type] != :keyword &&
         !['endfunction', 'endfunc'].include?(end_token[:value])
        @errors << {
          message: "Expected 'endfunction' or 'endfunc'",
          position: @position,
          line: end_token ? end_token[:line] : 0,
          column: end_token ? end_token[:column] : 0
        }
      end

      {
        type: :legacy_function,
        name: name ? name[:value] : nil,
        params: params,
        has_bang: has_bang,
        attributes: attributes,
        body: body,
        line: line,
        column: column
      }
    end

    # Legacy function parameters are different - they use a:name syntax
    def parse_parameter_list_legacy
      params = []

      # Empty parameter list
      if current_token && current_token[:type] == :paren_close
        return params
      end

      loop do
        # Check for ... (varargs) in legacy function
        if current_token && current_token[:type] == :ellipsis
          advance
          params << { type: :var_args_legacy, name: '...' }
          break
        end

        if !current_token || current_token[:type] != :identifier
          @errors << {
            message: "Expected parameter name",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
          break
        end

        param_name = advance

        params << {
          type: :parameter,
          name: param_name[:value],
          line: param_name[:line],
          column: param_name[:column]
        }

        if current_token && current_token[:type] == :comma
          advance
        else
          break
        end
      end

      params
    end

  end
end
