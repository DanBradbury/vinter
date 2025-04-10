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
        when 'autocmd'
          parse_autocmd_statement
        when 'execute'
          parse_execute_statement
        when 'let'
          parse_let_statement  
        when 'echohl', 'echomsg'
          parse_echo_statement
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

    def parse_execute_statement
      token = advance # Skip 'execute'
      line = token[:line]
      column = token[:column]

      # Parse arguments - typically string expressions with concatenation
      # Just accept any tokens until we hit a statement terminator or another command
      expressions = []
      expr = parse_expression
      expressions << expr if expr

      # Return the execute statement
      {
        type: :execute_statement,
        expressions: expressions,
        line: line,
        column: column
      }
    end

    def parse_let_statement
      token = advance # Skip 'let'
      line = token[:line]
      column = token[:column]

      # Parse the target variable
      target = nil
      if current_token
        case current_token[:type]
        when :identifier, :global_variable, :script_local, :arg_variable, :option_variable, :special_variable
          target = {
            type: current_token[:type],
            name: current_token[:value],
            line: current_token[:line],
            column: current_token[:column]
          }
          advance
        else
          @errors << {
            message: "Expected variable name after let",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
        end
      end

      # Skip the '=' or other assignment operator
      operator = nil
      if current_token && (
          (current_token[:type] == :operator && current_token[:value] == '=') ||
          current_token[:type] == :compound_operator)
        operator = current_token[:value]
        advance
      else
        @errors << {
          message: "Expected assignment operator after variable in let statement",
          position: @position,
          line: current_token ? current_token[:line] : 0,
          column: current_token ? current_token[:column] : 0
        }
      end

      # Parse the value expression
      value = parse_expression

      {
        type: :let_statement,
        target: target,
        operator: operator,
        value: value,
        line: line,
        column: column
      }
    end

    def parse_autocmd_statement
      token = advance # Skip 'autocmd'
      line = token[:line]
      column = token[:column]

      # Parse event name (like BufNewFile)
      event = nil
      if current_token && current_token[:type] == :identifier
        event = advance[:value]
      else
        @errors << {
          message: "Expected event name after 'autocmd'",
          position: @position,
          line: current_token ? current_token[:line] : 0,
          column: current_token ? current_token[:column] : 0
        }
      end

      # Parse pattern (like *.match)
      pattern = nil
      if current_token
        pattern = current_token[:value]
        advance
      end

      # Parse command (can be complex, including if statements)
      commands = []

      # Handle pipe-separated commands
      in_command = true
      while in_command && @position < @tokens.length
        if current_token && current_token[:value] == '|'
          advance # Skip '|'
        end

        # Parse the command
        if current_token && current_token[:type] == :keyword
          case current_token[:value]
          when 'if'
            commands << parse_if_statement
          when 'echo'
            commands << parse_echo_statement
          # Add other command types as needed
          else
            # Generic command handling
            cmd = parse_expression_statement
            commands << cmd if cmd
          end
        elsif current_token && current_token[:type] == :identifier
          cmd = parse_expression_statement
          commands << cmd if cmd
        else
          in_command = false
        end

        # Check if we've reached the end of the autocmd command
        if !current_token || current_token[:type] == :comment || current_token[:value] == "\n"
          in_command = false
        end
      end

      return {
        type: :autocmd_statement,
        event: event,
        pattern: pattern,
        commands: commands,
        line: line,
        column: column
      }
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

      # Parse parameters until we find a closing parenthesis
      while @position < @tokens.length && current_token && current_token[:type] != :paren_close
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

          # After varargs, we expect closing paren
          if current_token && current_token[:type] != :paren_close
            @errors << {
              message: "Expected closing parenthesis after varargs",
              position: @position,
              line: current_token[:line],
              column: current_token[:column]
            }
          end

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
          optional: default_value != nil,
          default_value: default_value,
          line: param_name[:line],
          column: param_name[:column]
        }

        # If we have a comma, advance past it and continue
        if current_token && current_token[:type] == :comma
          advance
        # If we don't have a comma, we should have a closing paren
        elsif current_token && current_token[:type] != :paren_close
          @errors << {
            message: "Expected comma or closing parenthesis after parameter",
            position: @position,
            line: current_token[:line],
            column: current_token[:column]
          }
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
      left = parse_unary_expression

      # Handle multi-line expressions where operators may appear at line beginnings
      while current_token &&
            (current_token[:type] == :operator ||
             (peek_token && peek_token[:type] == :operator && current_token[:type] == :whitespace))

        # Skip any whitespace before the operator if it's at the beginning of a line
        if current_token[:type] == :whitespace
          advance
        end

        # Now we should be at the operator
        if current_token && current_token[:type] == :operator &&
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
        else
          break
        end
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
      when '.'
        7
      when '!'
        8
      else
        0
      end
    end

    def parse_primary_expression
      return nil unless current_token

      token = current_token
      line = token[:line]
      column = token[:column]

      # First parse the basic expression
      expr = nil

      case token[:type]
      when :number
        advance
        expr = {
          type: :literal,
          value: token[:value],
          token_type: :number,
          line: line,
          column: column
        }
      when :string
        advance
        expr = {
          type: :literal,
          value: token[:value],
          token_type: :string,
          line: line,
          column: column
        }
      when :option_variable
        # Handle Vim option variables (like &compatible)
        advance
        expr = {
          type: :option_variable,
          name: token[:value],
          line: line,
          column: column
        }
      when :special_variable
        # Handle Vim special variables (like v:version)
        advance
        expr = {
          type: :special_variable,
          name: token[:value],
          line: line,
          column: column
        }
      when :script_local
        # Handle script-local variables/functions (like s:var)
        advance

        # Check if this is a function call
        if current_token && current_token[:type] == :paren_open
          return parse_function_call(token[:value], line, column)
        end

        expr = {
          type: :script_local,
          name: token[:value],
          line: line,
          column: column
        }
      when :global_variable
        # Handle global variables (like g:var)
        advance
        expr = {
          type: :global_variable,
          name: token[:value],
          line: line,
          column: column
        }
      when :arg_variable
        # Handle function argument variables (like a:var)
        advance
        expr = {
          type: :arg_variable,
          name: token[:value],
          line: line,
          column: column
        }
      when :identifier
        advance

        # Check if this is a function call
        if current_token && current_token[:type] == :paren_open
          return parse_function_call(token[:value], line, column)
        end
        
        # Special handling for execute command
        if token[:value] == 'execute'
          # Parse the string expressions for execute
          # For now we'll just treat it as a normal identifier
          expr = {
            type: :identifier,
            name: token[:value],
            line: line,
            column: column
          }
        else
          expr = {
            type: :identifier,
            name: token[:value],
            line: line,
            column: column
          }
        end
      when :paren_open
        if is_lambda_expression
          return parse_lambda_expression(line, column)
        else
          advance  # Skip '('
          expr = parse_expression
          expect(:paren_close)  # Expect and skip ')'
        end
      when :bracket_open
        expr = parse_list_literal(line, column)
      when :brace_open
        expr = parse_dict_literal(line, column)
      when :backslash
        # Handle line continuation with backslash
        advance
        expr = parse_expression
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

      # Now handle any chained property access or method calls
      while current_token
        # Check for property access with dot
        if current_token[:type] == :operator && current_token[:value] == '.'
          dot_token = advance # Skip '.'

          # Next token should be an identifier (property name)
          if !current_token || current_token[:type] != :identifier
            @errors << {
              message: "Expected property name after '.'",
              position: @position,
              line: current_token ? current_token[:line] : 0,
              column: current_token ? current_token[:column] : 0
            }
            break
          end

          property_token = advance # Get property name

          expr = {
            type: :property_access,
            object: expr,
            property: property_token[:value],
            line: dot_token[:line],
            column: dot_token[:column]
          }
        # Check for method call with arrow ->
        elsif current_token[:type] == :operator && current_token[:value] == '->'
          arrow_token = advance # Skip '->'

          # Next token should be an identifier (method name)
          if !current_token || current_token[:type] != :identifier
            @errors << {
              message: "Expected method name after '->'",
              position: @position,
              line: current_token ? current_token[:line] : 0,
              column: current_token ? current_token[:column] : 0
            }
            break
          end

          method_name = advance[:value] # Get method name

          # Check for arguments
          args = []
          if current_token && current_token[:type] == :paren_open
            expect(:paren_open) # Skip '('

            # Parse arguments if any
            unless current_token && current_token[:type] == :paren_close
              loop do
                arg = parse_expression
                args << arg if arg

                if current_token && current_token[:type] == :comma
                  advance # Skip comma
                else
                  break
                end
              end
            end

            expect(:paren_close) # Skip ')'
          end

          expr = {
            type: :method_call,
            object: expr,
            method: method_name,
            arguments: args,
            line: arrow_token[:line],
            column: arrow_token[:column]
          }
        # Check for indexing with brackets
        elsif current_token[:type] == :bracket_open
          bracket_token = advance # Skip '['

          index_expr = parse_expression

          expect(:bracket_close) # Skip ']'

          expr = {
            type: :indexed_access,
            object: expr,
            index: index_expr,
            line: bracket_token[:line],
            column: bracket_token[:column]
          }
        # Check for function call directly on an expression
        elsif current_token[:type] == :paren_open
          paren_token = advance # Skip '('

          args = []

          # Parse arguments if any
          unless current_token && current_token[:type] == :paren_close
            loop do
              arg = parse_expression
              args << arg if arg

              if current_token && current_token[:type] == :comma
                advance # Skip comma
              else
                break
              end
            end
          end

          expect(:paren_close) # Skip ')'

          expr = {
            type: :call_expression,
            callee: expr,
            arguments: args,
            line: paren_token[:line],
            column: paren_token[:column]
          }
        else
          # No more chaining
          break
        end
      end

      return expr
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

      # Parse the lambda body - check if it's a block or an expression
      if arrow_found
        if current_token && current_token[:type] == :brace_open
          # Parse block body
          advance  # Skip '{'

          block_body = []
          brace_count = 1  # Track nested braces

          while @position < @tokens.length && brace_count > 0
            if current_token[:type] == :brace_open
              brace_count += 1
            elsif current_token[:type] == :brace_close
              brace_count -= 1

              # Skip the final closing brace, but don't process it as a statement
              if brace_count == 0
                advance
                break
              end
            end

            stmt = parse_statement
            block_body << stmt if stmt

            # Break if we've reached the end or found the matching closing brace
            if brace_count == 0 || @position >= @tokens.length
              break
            end
          end

          body = {
            type: :block_expression,
            statements: block_body,
            line: line,
            column: column
          }
        else
          # Simple expression body
          body = parse_expression
        end
      else
        body = nil
      end

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
      while @position < @tokens.length
        # Check if we've reached the end of the list
        if current_token && current_token[:type] == :bracket_close
          advance  # Skip ']'
          break
        end

        element = parse_expression
        elements << element if element

        # Continue if there's a comma
        if current_token && current_token[:type] == :comma
          advance  # Skip comma
        else
          # If no comma and not a closing bracket, then it's an error
          if current_token && current_token[:type] != :bracket_close
            @errors << {
              message: "Expected comma or closing bracket after list element",
              position: @position,
              line: current_token[:line],
              column: current_token[:column]
            }
          end

          # We still want to skip the closing bracket if it's there
          if current_token && current_token[:type] == :bracket_close
            advance
          end

          break
        end
      end

      # Check if we have a second list immediately following this one (Vim's special syntax)
      if current_token && current_token[:type] == :bracket_open
        next_list = parse_list_literal(current_token[:line], current_token[:column])

        return {
          type: :list_concat_expression,
          left: {
            type: :list_literal,
            elements: elements,
            line: line,
            column: column
          },
          right: next_list,
          line: line,
          column: column
        }
      end

      return {
        type: :list_literal,
        elements: elements,
        line: line,
        column: column
      }
    end

    def parse_unary_expression
      # Check for unary operators (!, -, +)
      if current_token && current_token[:type] == :operator &&
         ['!', '-', '+'].include?(current_token[:value])

        op_token = advance # Skip the operator
        operand = parse_unary_expression  # Recursively parse the operand

        return {
          type: :unary_expression,
          operator: op_token[:value],
          operand: operand,
          line: op_token[:line],
          column: op_token[:column]
        }
      end

      # If no unary operator, parse a primary expression
      return parse_primary_expression
    end

    def parse_function_call(name, line, column)
      expect(:paren_open)

      args = []

      # Parse arguments until we find a closing parenthesis
      while @position < @tokens.length && current_token && current_token[:type] != :paren_close
        # Skip comments inside parameter lists
        if current_token && current_token[:type] == :comment
          advance
          next
        end

        # Check if the argument might be a lambda expression
        if current_token && current_token[:type] == :paren_open && is_lambda_expression
          arg = parse_lambda_expression(current_token[:line], current_token[:column])
        else
          arg = parse_expression
        end

        args << arg if arg

        # Break if we hit the closing paren
        if current_token && current_token[:type] == :paren_close
          break
        end

        # If we have a comma, advance past it and continue
        if current_token && current_token[:type] == :comma
          advance
        # If we don't have a comma and we're not at the end, it's an error
        elsif current_token && current_token[:type] != :paren_close && current_token[:type] != :comment
          @errors << {
            message: "Expected comma or closing parenthesis after argument",
            position: @position,
            line: current_token[:line],
            column: current_token[:column]
          }
          break
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

      # For script-local functions or other scoped functions
      is_script_local = false
      function_scope = nil
      
      # Check if we have a script-local function (s:)
      if current_token && current_token[:type] == :script_local
        is_script_local = true
        function_scope = current_token[:value]
        advance # Skip s: prefix
      elsif current_token && current_token[:type] == :identifier && current_token[:value].include?(':')
        # Handle other scoped functions like g: or b:
        parts = current_token[:value].split(':')
        if parts.length == 2
          function_scope = parts[0] + ':'
          advance
        end
      end
      
      # Now handle the function name, which might be separate from the scope
      name = nil
      if !is_script_local && function_scope.nil? && current_token && current_token[:type] == :identifier
        name = current_token
        advance
      elsif is_script_local || !function_scope.nil?
        if current_token && current_token[:type] == :identifier
          name = current_token
          advance
        end
      else
        name = expect(:identifier)
      end

      # Parse parameter list
      expect(:paren_open)
      params = parse_parameter_list_legacy
      expect(:paren_close)

      # Check for optional attributes (range, dict, abort, closure)
      attributes = []
      while current_token
        if current_token[:type] == :keyword && current_token[:value] == 'abort'
          attributes << advance[:value]
        elsif current_token[:type] == :identifier && 
              ['range', 'dict', 'closure'].include?(current_token[:value])
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

      function_name = name ? name[:value] : nil
      if function_scope
        function_name = function_scope + function_name if function_name
      end
      
      {
        type: :legacy_function,
        name: function_name,
        is_script_local: is_script_local,
        scope: function_scope,
        params: params,
        has_bang: has_bang,
        attributes: attributes,
        body: body,
        line: line,
        column: column
      }
    end

    # Legacy function parameters are different - they can use a:name syntax
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

        if current_token && current_token[:type] == :identifier
          # Regular parameter
          param_name = advance
          params << {
            type: :parameter,
            name: param_name[:value],
            line: param_name[:line],
            column: param_name[:column]
          }
        elsif current_token && current_token[:type] == :arg_variable
          # Parameter with a: prefix
          param_name = advance
          # Extract name without 'a:' prefix
          name_without_prefix = param_name[:value].sub(/^a:/, '')
          params << {
            type: :parameter,
            name: name_without_prefix,
            line: param_name[:line],
            column: param_name[:column],
            is_arg_prefixed: true
          }
        else
          @errors << {
            message: "Expected parameter name",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
          break
        end

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
