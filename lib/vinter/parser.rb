module Vinter
  class Parser
    def initialize(tokens, source_text = nil)
      @tokens = tokens
      @position = 0
      @errors = []
      @warnings = []
      @source_text = source_text
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

        # Get the full line content from the input if available
        line_content = nil
        if line > 0 && @tokens.length > 0
          # Find tokens on the same line
          same_line_tokens = @tokens.select { |t| t[:line] == line }
          if !same_line_tokens.empty?
            # Create a representation of the line with a marker at the error position
            line_representation = same_line_tokens.map { |t| t[:value] }.join('')
            line_content = "Line content: #{line_representation}"
          end
        end

        error = "Expected #{expected} but found #{found}"
        error += ", at line #{line}, column #{column}"
        error += "\n#{line_content}" if line_content

        @errors << {
          message: error,
          position: @position,
          line: line,
          column: column,
          line_content: line_content
        }
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

    def parse_mapping_statement
      token = current_token
      advance # Skip the mapping command
      line = token[:line]
      column = token[:column]
      mapping_command = token[:value]

      # Parse options (like <silent>, <buffer>, etc.)
      options = []
      while current_token &&
            (current_token[:type] == :identifier || current_token[:type] == :special_key) &&
            current_token[:value].start_with?('<') &&
            current_token[:value].end_with?('>')
        options << current_token[:value]
        advance
      end

      # Parse the key sequence
      key_sequence = nil
      if current_token
        if current_token[:type] == :special_key ||
           (current_token[:value].start_with?('<') && current_token[:value].end_with?('>'))
          key_sequence = current_token[:value]
          advance
        else
          key_sequence = current_token[:value]
          advance
        end
      end

      # Collect everything else until end of line as the mapping target
      # This is raw text and shouldn't be parsed as an expression
      target_tokens = []

      # Continue collecting tokens until we hit a newline or comment
      while current_token &&
            current_token[:type] != :comment &&
            (current_token[:type] != :whitespace || current_token[:value].strip != '')

        # If we hit a newline not preceded by a continuation character, we're done
        if current_token[:value] == "\n" &&
           (target_tokens.empty? || target_tokens.last[:value][-1] != '\\')
          break
        end

        target_tokens << current_token
        advance
      end

      # Join the target tokens to form the raw mapping target
      target = target_tokens.map { |t| t[:value] }.join('')

      {
        type: :mapping_statement,
        command: mapping_command,
        options: options,
        key_sequence: key_sequence,
        target: target,
        line: line,
        column: column
      }
    end

    def parse_statement
      if !current_token
        return nil
      end
      start_token = current_token

      # Handle pipe as command separator
      if current_token[:type] == :operator && current_token[:value] == '|'
        advance # Skip the pipe
        return parse_statement
      end

      # Handle endif keyword outside normal if structure (likely from one-line if)
      if current_token[:type] == :keyword && current_token[:value] == 'endif'
        token = advance # Skip the endif
        return {
          type: :endif_marker,
          line: token[:line],
          column: token[:column]
        }
      end

      # Add special cases for other ending keywords too to be thorough
      if current_token[:type] == :keyword &&
         ['endwhile', 'endfor', 'endfunction', 'endfunc', 'enddef'].include?(current_token[:value])
        token = advance # Skip the keyword
        return {
          type: :"#{token[:value]}_marker",
          line: token[:line],
          column: token[:column]
        }
      end

      # Now, add specific handling for continue and break
      if current_token[:type] == :keyword && current_token[:value] == 'continue'
        token = advance # Skip 'continue'
        return {
          type: :continue_statement,
          line: token[:line],
          column: token[:column]
        }
      end

      if current_token[:type] == :keyword && current_token[:value] == 'break'
        token = advance # Skip 'break'
        return {
          type: :break_statement,
          line: token[:line],
          column: token[:column]
        }
      end

      # Handle try-catch
      if current_token[:type] == :keyword && current_token[:value] == 'try'
        return parse_try_statement
      end

      # Handle throw
      if current_token[:type] == :keyword && current_token[:value] == 'throw'
        return parse_throw_statement
      end

      # Skip standalone catch, finally, endtry keywords outside of try blocks
      if current_token[:type] == :keyword &&
         ['catch', 'finally', 'endtry'].include?(current_token[:value])
        token = advance # Skip these keywords
        return nil
      end

      # Add case for mapping commands
      if current_token[:type] == :keyword &&
         ['nnoremap', 'nmap', 'inoremap', 'imap', 'vnoremap', 'vmap',
          'xnoremap', 'xmap', 'cnoremap', 'cmap', 'noremap', 'map'].include?(current_token[:value])
        parse_mapping_statement
      elsif current_token[:type] == :runtime_command
        parse_runtime_statement
      elsif current_token[:type] == :keyword && current_token[:value] == 'runtime'
        parse_runtime_statement
      elsif current_token[:type] == :keyword
        case current_token[:value]
        when 'if'
          parse_if_statement
        when 'command'
          parse_command_definition
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
        when 'echohl', 'echomsg', 'echoerr', 'echom'
          parse_echo_statement
        when 'augroup'
          parse_augroup_statement
        when 'silent'
          parse_silent_command
        when 'call'
          parse_call_statement
        when 'delete'
          parse_delete_statement
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
        elsif current_token[:value] == "augroup"
          parse_augroup_statement
        elsif current_token[:value] == "au" || current_token[:value] == "autocmd"
          parse_autocmd_statement
        elsif current_token[:value] == "filter" || current_token[:value] == "filt"
          parse_filter_command
        elsif current_token[:value] == "command"
          parse_command_definition
        else
          parse_expression_statement
        end
      elsif current_token[:type] == :comment
        parse_comment
      elsif current_token[:type] == :string && current_token[:value].start_with?('"')
        parse_comment
        # token = current_token
        # line = token[:line]
        # column = token[:column]
        # value = token[:value]
        # advance
        # { type: :comment, value: value, line: line, column: column }
      elsif current_token[:type] == :silent_bang
        parse_silent_command
      elsif current_token[:type] == :identifier && current_token[:value] == 'delete'
        parse_delete_command
      elsif current_token[:type] == :percentage
        parse_range_command
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

    def parse_range_command
      token = advance # Skip '%'
      line = token[:line]
      column = token[:column]

      # Parse the command that follows the range
      command = parse_statement

      {
        type: :range_command,
        range: '%',
        command: command,
        line: line,
        column: column
      }
    end

    def parse_runtime_statement
      token = advance # Skip 'runtime' or 'runtime!'
      line = token[:line]
      column = token[:column]

      is_bang = token[:type] == :runtime_command ||
               (token[:value] == 'runtime' && current_token && current_token[:type] == :operator && current_token[:value] == '!')

      # Skip the '!' if it's separate token
      if token[:type] != :runtime_command && is_bang
        advance # Skip '!'
      end

      # Collect the pattern argument
      pattern_parts = []
      while @position < @tokens.length &&
            !(current_token[:type] == :keyword || current_token[:value] == "\n")
        pattern_parts << current_token[:value]
        advance
      end

      pattern = pattern_parts.join('').strip

      {
        type: :runtime_statement,
        bang: is_bang,
        pattern: pattern,
        line: line,
        column: column
      }
    end

    def parse_filter_command
      token = advance # Skip 'filter' or 'filt'
      line = token[:line]
      column = token[:column]

      # Check for bang (!)
      has_bang = false
      if current_token && current_token[:type] == :operator && current_token[:value] == '!'
        has_bang = true
        advance # Skip '!'
      end

      # Parse the pattern
      pattern = nil
      pattern_delimiter = nil

      if current_token && current_token[:type] == :operator && current_token[:value] == '/'
        # Handle /pattern/ form
        pattern_delimiter = '/'
        advance # Skip opening delimiter

        # Collect all tokens until closing delimiter
        pattern_parts = []
        while @position < @tokens.length &&
              !(current_token[:type] == :operator && current_token[:value] == pattern_delimiter)
          pattern_parts << current_token[:value]
          advance
        end

        pattern = pattern_parts.join('')

        # Skip closing delimiter
        if current_token && current_token[:type] == :operator && current_token[:value] == pattern_delimiter
          advance
        else
          @errors << {
            message: "Expected closing pattern delimiter: #{pattern_delimiter}",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
        end
      else
        # Handle direct pattern form (without delimiters)
        # Parse until we see what appears to be the command
        pattern_parts = []
        while @position < @tokens.length
          # Don't consume tokens that likely belong to the command part
          if current_token[:type] == :keyword ||
             (current_token[:type] == :identifier &&
              ['echo', 'let', 'execute', 'autocmd', 'au', 'oldfiles', 'clist', 'command',
               'files', 'highlight', 'jumps', 'list', 'llist', 'marks', 'registers', 'set'].include?(current_token[:value]))
            break
          end

          pattern_parts << current_token[:value]
          advance
        end

        pattern = pattern_parts.join('').strip
      end

      # Parse the command to be filtered
      command = parse_statement

      {
        type: :filter_command,
        pattern: pattern,
        has_bang: has_bang,
        command: command,
        line: line,
        column: column
      }
    end

    def parse_augroup_statement
      token = advance # Skip 'augroup'
      line = token[:line]
      column = token[:column]

      # Get the augroup name
      name = nil
      if current_token && current_token[:type] == :identifier
        name = current_token[:value]
        advance
      else
        @errors << {
          message: "Expected augroup name",
          position: @position,
          line: current_token ? current_token[:line] : 0,
          column: current_token ? current_token[:column] : 0
        }
      end

      # Check for augroup END
      is_end_marker = false
      if name && (name.upcase == "END" || name == "END")
        is_end_marker = true
        return {
          type: :augroup_end,
          line: line,
          column: column
        }
      end

      # Parse statements within the augroup until we find 'augroup END'
      body = []
      while @position < @tokens.length
        # Check for 'augroup END'
        if (current_token[:type] == :keyword && current_token[:value] == 'augroup') ||
           (current_token[:type] == :identifier && current_token[:value] == 'augroup')
          # Look ahead for END
          if peek_token &&
             ((peek_token[:type] == :identifier &&
               (peek_token[:value].upcase == 'END' || peek_token[:value] == 'END')) ||
              (peek_token[:type] == :keyword && peek_token[:value].upcase == 'END'))
            advance # Skip 'augroup'
            advance # Skip 'END'
            break
          end
        end

        stmt = parse_statement
        body << stmt if stmt
      end

      {
        type: :augroup_statement,
        name: name,
        body: body,
        line: line,
        column: column
      }
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
      # binding.pry
      token = advance # Skip 'let'
      line = token[:line]
      column = token[:column]

      # Parse the target variable
      target = nil
      if current_token
        case current_token[:type]
        when :identifier, :global_variable, :script_local, :buffer_local, :window_local, :tab_local, :arg_variable, :option_variable, :special_variable, :local_variable
          target = {
            type: current_token[:type],
            name: current_token[:value],
            line: current_token[:line],
            column: current_token[:column]
          }
          advance

          # Check for property access with dot notation (e.g., person.job)
          if current_token && current_token[:type] == :operator && current_token[:value] == '.'
            dot_token = advance # Skip '.'

            # Next token should be an identifier (property name)
            if current_token && current_token[:type] == :identifier
              property_token = advance # Get the property name

              # Update the target to be a property access
              target = {
                type: :property_access,
                object: target,
                property: property_token[:value],
                line: dot_token[:line],
                column: dot_token[:column]
              }
            else
              @errors << {
                message: "Expected property name after '.'",
                position: @position,
                line: current_token ? current_token[:line] : 0,
                column: current_token ? current_token[:column] : 0
              }
            end
          end

          # Check if this is an indexed access (dictionary key lookup)
          if current_token && current_token[:type] == :bracket_open
            bracket_token = advance # Skip '['
            index_expr = parse_expression
            expect(:bracket_close) # Skip ']'

            # Update target to be an indexed access
            target = {
              type: :indexed_access,
              object: target,
              index: index_expr,
              line: bracket_token[:line],
              column: bracket_token[:column]
            }
          end
        when :register_access
          target = {
            type: :register_access,
            register: current_token[:value],
            line: current_token[:line],
            column: current_token[:column]
          }
          advance
        when :bracket_open
          # Handle array destructuring like: let [key, value] = split(header, ': ')
          bracket_token = advance # Skip '['

          # Parse the variable names inside the brackets
          destructuring_targets = []

          # Parse comma-separated list of variables
          while current_token && current_token[:type] != :bracket_close
            # Skip commas between variables
            if current_token[:type] == :comma
              advance
              next
            end

            # Parse the variable name
            if current_token && (
              current_token[:type] == :identifier ||
              current_token[:type] == :global_variable ||
              current_token[:type] == :script_local ||
              current_token[:type] == :arg_variable ||
              current_token[:type] == :option_variable ||
              current_token[:type] == :special_variable ||
              current_token[:type] == :local_variable
            )
              destructuring_targets << {
                type: current_token[:type],
                name: current_token[:value],
                line: current_token[:line],
                column: current_token[:column]
              }
              advance
            else
              @errors << {
                message: "Expected variable name in destructuring assignment",
                position: @position,
                line: current_token ? current_token[:line] : 0,
                column: current_token ? current_token[:column] : 0
              }
              # Try to recover by advancing to next comma or closing bracket
              while current_token && current_token[:type] != :comma && current_token[:type] != :bracket_close
                advance
              end
            end
          end

          expect(:bracket_close) # Skip ']'

          target = {
            type: :destructuring_assignment,
            targets: destructuring_targets,
            line: bracket_token[:line],
            column: bracket_token[:column]
          }
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
      value = nil

      # Special handling for function() references in let statements
      if current_token && current_token[:type] == :keyword && current_token[:value] == 'function'
        advance # Skip 'function'

        # Expect opening parenthesis
        if current_token && current_token[:type] == :paren_open
          paren_token = advance # Skip '('

          # Parse the function name as a string
          func_name = nil
          if current_token && current_token[:type] == :string
            func_name = current_token[:value]
            advance
          else
            @errors << {
              message: "Expected string with function name in function() call",
              position: @position,
              line: current_token ? current_token[:line] : 0,
              column: current_token ? current_token[:column] : 0
            }
          end

          # Expect closing parenthesis
          expect(:paren_close) # Skip ')'

          value = {
            type: :function_reference,
            function_name: func_name,
            line: line,
            column: column
          }
        else
          # If not followed by parenthesis, parse as a normal expression
          @position -= 1 # Go back to the 'function' keyword
          value = parse_expression
        end
      else
        # Normal expression parsing
        value = parse_expression
      end
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

      # Parse event name (like BufNewFile or VimEnter)
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

      # Parse pattern (like *.match or *)
      pattern = nil
      if current_token
        pattern = current_token[:value]
        advance
      end

      # Parse everything after as the command - collect as raw tokens
      command_parts = []
      while @position < @tokens.length
        if !current_token || current_token[:type] == :comment ||
           (current_token[:value] == "\n" && !current_token[:value].start_with?("\\"))
          break
        end

        command_parts << current_token
        advance
      end

      return {
        type: :autocmd_statement,
        event: event,
        pattern: pattern,
        command_parts: command_parts,
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
      original_token = current_token
      line = original_token[:line]
      column = original_token[:column]
      comment = original_token[:value]

      # puts "INSIDE PARSE COMMENT"
      # puts "Current token: #{current_token.inspect}"
      # puts "Peek token: #{peek_token.inspect}"

      # Check if the comment contains a newline
      if comment.include?("\n")
        # Split the comment at the newline
        parts = comment.split("\n", 2)
        comment = parts[0] # Only use the part before newline

        # Create a new token for the content after the newline
        remainder = parts[1].strip

        if !remainder.empty?
          # Position correctly - we'll advance past the current token
          # But should process the remainder separately later

          # For debugging only, you can print what's being processed
          # puts "Found comment with newline. Using: '#{comment}', Remainder: '#{remainder}'"

          # Don't call advance() - we'll modify the current token instead
          @tokens[@position] = {
            type: :string,  # Keep original type
            value: comment, # Use only the part before newline
            line: line,
            column: column
          }

          # Insert the remainder as a new token after the current one
          @tokens.insert(@position + 1, {
            type: :comment,  # Same type for consistency
            value: remainder, # Preserve as a string token
            line: line + 1, # Increment line number for the part after newline
            column: 0 # Approximate column based on indentation
          })
        end
      end

      # Now advance past the (potentially modified) current token
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

      # Check if this might be a one-line if (look ahead for pipe character)
      one_line_if = false

      if current_token && current_token[:type] == :operator && current_token[:value] == '|'
        one_line_if = true
        advance # Skip the pipe

        # Parse the then statement
        stmt = parse_statement
        then_branch << stmt if stmt

        # Check for the closing pipe and endif
        if current_token && current_token[:type] == :operator && current_token[:value] == '|'
          advance # Skip the pipe

          # Expect endif
          if current_token && current_token[:type] == :keyword && current_token[:value] == 'endif'
            advance # Skip 'endif'
          else
            @errors << {
              message: "Expected 'endif' after '|' in one-line if statement",
              position: @position,
              line: current_token ? current_token[:line] : 0,
              column: current_token ? current_token[:column] : 0
            }
          end
        end
      else
        # This is a regular multi-line if statement
        # Continue with your existing logic for parsing normal if statements

        # Parse statements until we hit 'else', 'elseif', or 'endif'
        while @position < @tokens.length
          # Check for the tokens that would terminate this block
          if current_token && current_token[:type] == :keyword &&
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
            elseif_stmt = parse_if_statement
            else_branch << elseif_stmt if elseif_stmt

            return {
              type: :if_statement,
              condition: condition,
              then_branch: then_branch,
              else_branch: else_branch,
              line: line,
              column: column
            }
          end
        end

        # Expect endif
        if current_token && current_token[:type] == :keyword && current_token[:value] == 'endif'
          advance # Skip 'endif'
        else
          # Don't add an error if we've already reached the end of the file
          if @position < @tokens.length
            @errors << {
              message: "Expected 'endif' to close if statement",
              position: @position,
              line: current_token ? current_token[:line] : 0,
              column: current_token ? current_token[:column] : 0
            }
          end
        end
      end

      {
        type: :if_statement,
        condition: condition,
        then_branch: then_branch,
        else_branch: else_branch,
        one_line: one_line_if,
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

      # Two main patterns:
      # 1. for [key, val] in dict - destructuring with bracket_open
      # 2. for var in list - simple variable with identifier

      if current_token && current_token[:type] == :bracket_open
        # Handle destructuring assignment: for [key, val] in dict
        advance # Skip '['

        loop_vars = []

        loop do
          if current_token && (current_token[:type] == :identifier ||
                              current_token[:type] == :local_variable ||
                              current_token[:type] == :global_variable ||
                              current_token[:type] == :script_local)
            loop_vars << advance
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

        expect(:bracket_close) # Skip ']'

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
          if current_token && current_token[:type] == :keyword && current_token[:value] == 'endfor'
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
      elsif current_token && current_token[:type] == :paren_open
        # Handle multiple variables in parentheses: for (var1, var2) in list
        advance # Skip '('

        loop_vars = []

        loop do
          if current_token && (current_token[:type] == :identifier ||
                              current_token[:type] == :local_variable ||
                              current_token[:type] == :global_variable ||
                              current_token[:type] == :script_local)
            loop_vars << advance
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
          if current_token && current_token[:type] == :keyword && current_token[:value] == 'endfor'
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
        # Handle single variable: for var in list
        if current_token && (current_token[:type] == :identifier ||
                            current_token[:type] == :local_variable ||
                            current_token[:type] == :global_variable ||
                            current_token[:type] == :script_local)
          loop_var = advance
        else
          @errors << {
            message: "Expected identifier as for loop variable",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
          loop_var = nil
        end

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
          if current_token && current_token[:type] == :keyword && current_token[:value] == 'endfor'
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
      # Check if we've reached the end of the file, end of line, or a semicolon
      if @position < @tokens.length &&
         current_token &&
         current_token[:type] != :semicolon &&
         !(current_token[:type] == :keyword &&
           ['endif', 'endwhile', 'endfor', 'endfunction', 'endfunc'].include?(current_token[:value]))
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
      # binding.pry
      # Special case for empty return statements or standalone keywords that shouldn't be expressions
      if current_token && current_token[:type] == :keyword &&
         ['return', 'endif', 'endwhile', 'endfor', 'endfunction', 'endfunc'].include?(current_token[:value])
        return nil
      end

      if current_token[:type] == :string
        string_value = current_token[:value]
        while current_token && peek_token && [:line_continuation, :identifier].include?(peek_token[:type])
          # Handle strings with line continuation
          if ["'", '"'].include? current_token[:value][-1]
            return {
              type: :literal,
              value: string_value,
              token_type: :string,
              line: current_token[:line],
              column: current_token[:column]
            }
          else
            advance
            string_value += current_token[:value]
          end
        end
      end

      # Parse the condition expression
      expr = parse_binary_expression

      # Check if this is a ternary expression
      if current_token && (current_token[:type] == :question_mark || (current_token[:type] == :operator && current_token[:value] == '?'))
        question_token = advance # Skip '?'

        # Parse the "then" expression
        then_expr = parse_expression

        # Expect the colon
        if current_token && current_token[:type] == :colon
          colon_token = advance # Skip ':'

          # Parse the "else" expression
          else_expr = parse_expression

          # Return the ternary expression
          return {
            type: :ternary_expression,
            condition: expr,
            then_expr: then_expr,
            else_expr: else_expr,
            line: question_token[:line],
            column: question_token[:column]
          }
        else
          @errors << {
            message: "Expected ':' in ternary expression",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
        end
      end

      return expr
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

        if current_token && current_token[:type] == :operator && current_token[:value] == '.' &&
          operator_precedence(current_token[:value]) >= precedence
         op_token = advance # Skip the operator

         # Check if we're dealing with a command placeholder on either side
         if (left && left[:type] == :command_arg_placeholder) ||
            (peek_token && peek_token[:type] == :command_arg_placeholder)
           # Handle command-specific concatenation
           right = parse_binary_expression(operator_precedence('.') + 1)

           left = {
             type: :command_concat_expression,  # Special type for command concatenation
             operator: '.',
             left: left,
             right: right,
             line: op_token[:line],
             column: op_token[:column]
           }
         else
           # Normal expression concatenation
           right = parse_binary_expression(operator_precedence('.') + 1)

           left = {
             type: :binary_expression,
             operator: '.',
             left: left,
             right: right,
             line: op_token[:line],
             column: op_token[:column]
           }
         end
        elsif current_token && current_token[:type] == :operator &&
          ['<', '>', '=', '!'].include?(current_token[:value]) &&
          peek_token && peek_token[:type] == :operator && peek_token[:value] == '='

          # Combine the two operators into one token
          op_token = current_token
          op = current_token[:value] + peek_token[:value]
          advance # Skip the first operator
          advance # Skip the second operator

          # Now process the combined operator
          op_precedence = operator_precedence(op)

          if op_precedence >= precedence
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
        # Now we should be at the operator
        elsif current_token && current_token[:type] == :operator &&
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
      # Add handling for command arg placeholders
      when :command_arg_placeholder
        advance
        expr = {
          type: :command_arg_placeholder,
          value: token[:value],
          line: line,
          column: column
        }
      # Add special handling for keywords that might appear in expressions
      when :keyword
        # Special handling for map-related keywords when they appear in expressions
        if ['map', 'nmap', 'imap', 'vmap', 'xmap', 'noremap', 'nnoremap', 'inoremap', 'vnoremap', 'xnoremap', 'cnoremap', 'cmap'].include?(token[:value])
          if peek_token[:type] == :paren_open
            parse_builtin_function_call(token[:value], line, column)
          else
            # Treat map commands as identifiers when inside expressions
            advance
            return {
              type: :identifier,
              name: token[:value],
              line: line,
              column: column
            }
          end
        elsif token[:value] == 'type' && current_token && (current_token[:type] == :paren_open || peek_token && peek_token[:type] == :paren_open)
          # This is the type() function call
          return parse_builtin_function_call(token[:value], line, column)
        elsif token[:value] == 'function'
          advance # Skip 'function'
          # Expect opening parenthesis
          if current_token && current_token[:type] == :paren_open
            # This is a function reference call
            paren_token = advance # Skip '('

            # Parse the function name as a string or arrow function
            if current_token && current_token[:type] == :string
              func_name = current_token[:value]
              advance

              # Expect closing parenthesis
              expect(:paren_close) # Skip ')'

              return {
                type: :function_reference,
                function_name: func_name,
                line: line,
                column: column
              }
            elsif current_token && current_token[:type] == :brace_open
              # This is an arrow function inside function()
              arrow_function = parse_vim_lambda(line, column)

              # Expect closing parenthesis
              expect(:paren_close) # Skip ')'

              return {
                type: :function_reference,
                function_body: arrow_function,
                line: line,
                column: column
              }
            else
              @errors << {
                message: "Expected string or arrow function definition in function() call",
                position: @position,
                line: current_token ? current_token[:line] : 0,
                column: current_token ? current_token[:column] : 0
              }
            end
          else
            # If not followed by parenthesis, it's likely a function declaration
            @errors << {
              message: "Unexpected keyword in expression: #{token[:value]}",
              position: @position,
              line: line,
              column: column
            }
            advance
            return nil
          end
        # Legacy Vim allows certain keywords as identifiers in expressions
        elsif ['return', 'type'].include?(token[:value])
          # Handle 'return' keyword specially when it appears in an expression context
          advance
          @warnings << {
            message: "Keyword '#{token[:value]}' used in an expression context",
            position: @position,
            line: line,
            column: column
          }
          # Check if this is a function call for 'type'
          if token[:value] == 'type' && current_token && current_token[:type] == :paren_open
            return parse_function_call(token[:value], line, column)
          end

          expr = {
            type: :identifier,
            name: token[:value],
            line: line,
            column: column
          }
        else
          @errors << {
            message: "Unexpected keyword in expression: #{token[:value]}",
            position: @position,
            line: line,
            column: column
          }
          advance
          return nil
        end
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
        # parse_string
        if token[:value].start_with?('"')
          advance
          return {
            type: :comment,
            value: token[:value],
            line: line,
            column: column
          }
        else
          string_value = token[:value]
          advance
          expr = {
            type: :literal,
            value: string_value,
            raw_value: string_value, # Store the raw string to preserve escapes
            token_type: :string,
            line: line,
            column: column
          }
        end
      when :option_variable
        # Handle Vim option variables (like &compatible)
        advance
        expr = {
          type: :option_variable,
          name: token[:value],
          line: line,
          column: column
        }
      when :scoped_option_variable
        advance
        expr = {
          type: :scoped_option_variable,
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
      when :buffer_local
        # Handle script-local variables/functions (like s:var)
        advance

        # Check if this is a function call
        if current_token && current_token[:type] == :paren_open
          return parse_function_call(token[:value], line, column)
        end

        expr = {
          type: :buffer_local,
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
      when :local_variable
        # Handle local variables (like l:var)
        advance
        expr = {
          type: :local_variable,
          name: token[:value],
          line: line,
          column: column
        }
      when :identifier
        # Special handling for Vim built-in functions
        if ['has', 'exists', 'empty', 'filter', 'get', 'type', 'map', 'copy'].include?(token[:value])
          return parse_builtin_function_call(token[:value], line, column)
        end

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
      when :namespace_prefix
        advance
        expr = {
          type: :namespace_prefix,
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
        end
      when :bracket_open
        expr = parse_list_literal(line, column)
      when :brace_open
        expr = parse_dict_literal(line, column)
      when :backslash
        # Handle line continuation with backslash
        advance
        expr = parse_expression
      when :register_access
        advance
        expr = {
          type: :register_access,
          register: token[:value][1..-1], # Remove the @ symbol
          line: line,
          column: column
        }
      when :line_continuation
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
          # Check if this is a property access (only when left side is an identifier or object)
          if expr[:type] == :identifier || expr[:type] == :global_variable ||
            expr[:type] == :script_local || expr[:type] == :namespace_prefix

            dot_token = advance # Skip '.'
            # Next token should be an identifier (property name)
            if !current_token || (current_token[:type] != :identifier &&
              current_token[:type] != :arg_variable &&
              current_token[:type] != :string)
                @errors << {
                  message: "Expected property name after '.'",
                  position: @position,
                  line: current_token ? current_token[:line] : 0,
                  column: current_token ? current_token[:column] : 0
                }
                break
            end
            property_token = advance

            expr = {
              type: :property_access,
              object: expr,
              property: property_token[:value],
              line: dot_token[:line],
              column: dot_token[:column]
            }
          else
            break
          end

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

          # Add support for list slicing with colon
          end_index = nil
          if current_token && current_token[:type] == :colon
            advance # Skip ':'
            # handle omitted end index case like [6:]
            if current_token && current_token[:type] == :bracket_close
              end_index = {
                type: :implicit_end_index,
                value: nil,
                line: current_token[:line],
                column: current_token[:column]
              }
            else
              end_index = parse_expression
            end
          end

          expect(:bracket_close) # Skip ']'

          if end_index
            # This is a slice operation
            expr = {
              type: :slice_access,
              object: expr,
              start_index: index_expr,
              end_index: end_index,
              line: bracket_token[:line],
              column: bracket_token[:column]
            }
          else
            # Regular indexed access
            expr = {
              type: :indexed_access,
              object: expr,
              index: index_expr,
              line: bracket_token[:line],
              column: bracket_token[:column]
            }
          end
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

    def parse_builtin_function_call(name, line, column)
      # Skip the function name (already consumed)
      advance if current_token[:value] == name

      # Check if there's an opening parenthesis
      if current_token && current_token[:type] == :paren_open
        advance # Skip '('

        # Parse arguments
        args = []

        # Functions that take string expressions as code
        special_functions = ['map', 'filter', 'reduce', 'sort', 'call', 'eval', 'execute']
        is_special_function = special_functions.include?(name)

        # Parse until closing parenthesis
        while @position < @tokens.length && current_token && current_token[:type] != :paren_close
          # Skip whitespace or comments
          if current_token[:type] == :whitespace || current_token[:type] == :comment
            advance
            next
          end

          # Special handling for string arguments that contain code
          if is_special_function &&
             current_token && current_token[:type] == :string
            string_token = parse_expression
            args << {
              type: :literal,
              value: string_token[:value],
              token_type: :string,
              line: string_token[:line],
              column: string_token[:column]
            }
          else
            arg = parse_expression
            args << arg if arg
          end

          if current_token && current_token[:type] == :comma
            advance
          elsif current_token && current_token[:type] != :paren_close
            @errors << {
              message: "Expected comma or closing parenthesis in #{name} function",
              position: @position,
              line: current_token[:line],
              column: current_token[:column]
            }
            break
          end
        end

        # Check for closing parenthesis
        if current_token && current_token[:type] == :paren_close
          advance # Skip ')'
        else
          @errors << {
            message: "Expected ')' to close #{name} function call",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
        end
      else
        # Handle legacy Vim script where parentheses might be omitted
        # Just parse one expression as the argument
        args = [parse_expression]
      end

      # Return function call node
      {
        type: :builtin_function_call,
        name: name,
        arguments: args,
        line: line,
        column: column
      }
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

    def parse_vim_lambda(line, column)
      advance # Skip opening brace

      # Parse parameters
      params = []

      # Parse parameter(s)
      if current_token && (current_token[:type] == :identifier ||
                          current_token[:type] == :local_variable ||
                          current_token[:type] == :global_variable)
        param_name = current_token[:value]
        param_line = current_token[:line]
        param_column = current_token[:column]
        advance

        params << {
          type: :parameter,
          name: param_name,
          line: param_line,
          column: param_column
        }

        # Handle multiple parameters (comma-separated)
        while current_token && current_token[:type] == :comma
          advance # Skip comma

          if current_token && (current_token[:type] == :identifier ||
                              current_token[:type] == :local_variable ||
                              current_token[:type] == :global_variable)
            param_name = current_token[:value]
            param_line = current_token[:line]
            param_column = current_token[:column]
            advance

            params << {
              type: :parameter,
              name: param_name,
              line: param_line,
              column: param_column
            }
          else
            @errors << {
              message: "Expected parameter name after comma in lambda function",
              position: @position,
              line: current_token ? current_token[:line] : 0,
              column: current_token ? current_token[:column] : 0
            }
            break
          end
        end
      else
        @errors << {
          message: "Expected parameter name in lambda function",
          position: @position,
          line: current_token ? current_token[:line] : 0,
          column: current_token ? current_token[:column] : 0
        }
      end

      # Expect the arrow token
      if current_token && current_token[:type] == :operator && current_token[:value] == '->'
        advance # Skip ->
      else
        @errors << {
          message: "Expected '->' in lambda function",
          position: @position,
          line: current_token ? current_token[:line] : 0,
          column: current_token ? current_token[:column] : 0
        }
      end

      # Parse the lambda body expression (everything until the closing brace)
      body = parse_expression

      # Expect closing brace
      if current_token && current_token[:type] == :brace_close
        advance # Skip }
      else
        @errors << {
          message: "Expected closing brace for lambda function",
          position: @position,
          line: current_token ? current_token[:line] : 0,
          column: current_token ? current_token[:column] : 0
        }
      end

      return {
        type: :vim_lambda,
        params: params,
        body: body,
        line: line,
        column: column
      }
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

      # Handle whitespace after opening brace
      while current_token && current_token[:type] == :whitespace
        advance
      end

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
      while current_token && current_token[:type] != :brace_close
        # Skip any backslash line continuation markers and whitespace
        while current_token && (current_token[:type] == :backslash || current_token[:type] == :whitespace || current_token[:type] == :line_continuation)
          advance
        end

        # Break if we reached the end or found closing brace
        if !current_token || current_token[:type] == :brace_close
          break
        end

        # Parse key (string or identifier)
        key = nil
        if current_token && (current_token[:type] == :string || current_token[:type] == :identifier)
          key = current_token[:value]
          advance  # Skip key
        else
          @errors << {
            message: "Expected string or identifier as dictionary key",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
          # Try to recover by advancing until we find a colon or closing brace
          while current_token && current_token[:type] != :colon && current_token[:type] != :brace_close
            advance
          end
          if !current_token || current_token[:type] == :brace_close
            break
          end
        end

        # Skip whitespace after key
        while current_token && current_token[:type] == :whitespace
          advance
        end

        # Expect colon
        if current_token && current_token[:type] == :colon
          advance  # Skip colon
        else
          @errors << {
            message: "Expected colon after dictionary key",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
        end

        # Skip whitespace after colon
        while current_token && current_token[:type] == :whitespace
          advance
        end

        # Parse value
        if current_token && current_token[:type] == :brace_open
          lambda_or_dict = parse_vim_lambda_or_dict(line, column)
          value = lambda_or_dict
        else
          value = parse_expression
        end

        entries << {
          key: key,
          value: value
        }

        # Skip any whitespace, backslash line continuation markers, and commas
        found_comma = false
        while current_token && (current_token[:type] == :whitespace ||
                               current_token[:type] == :backslash ||
                               current_token[:type] == :line_continuation ||
                               current_token[:type] == :comma)
          found_comma = true if current_token[:type] == :comma
          advance
        end

        # If no comma was found and we haven't reached the end, that's an error
        # unless we've reached the closing brace
        if !found_comma && current_token && current_token[:type] != :brace_close
          @errors << {
            message: "Expected comma or closing brace after dictionary entry",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
        end
      end

      # Make sure we have a closing brace
      if current_token && current_token[:type] == :brace_close
        advance  # Skip '}'
      else
        @errors << {
          message: "Expected closing brace for dictionary",
          position: @position,
          line: current_token ? current_token[:line] : 0,
          column: current_token ? current_token[:column] : 0
        }
      end

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
        # Handle line continuation characters (backslash)
        if current_token && [:backslash, :line_continuation].include?(current_token[:type])
          # Skip the backslash token
          advance

          # Skip any whitespace that might follow the backslash
          while current_token && current_token[:type] == :whitespace
            advance
          end

          # Don't add a comma - just continue to parse the next element
          next
        end

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
        # Or if the next token is a backslash (line continuation)
        else
          # binding.pry
          # If no comma and not a closing bracket or backslash, then it's an error
          # if current_token && current_token[:type] != :bracket_close
          #   @errors << {
          #     message: "Expected comma, backslash, or closing bracket after list element",
          #     position: @position,
          #     line: current_token[:line],
          #     column: current_token[:column]
          #   }
          # end

          # We still want to skip the closing bracket if it's there
          if current_token && current_token[:type] == :bracket_close
            advance
            break
          end
          advance
          #next
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

      # Special handling for Vim functions that take code strings as arguments
      special_functions = ['map', 'filter', 'reduce', 'sort', 'call', 'eval', 'execute']
      is_special_function = special_functions.include?(name)

      # Parse arguments until we find a closing parenthesis
      while @position < @tokens.length && current_token && current_token[:type] != :paren_close
        # Skip comments inside parameter lists
        if current_token && current_token[:type] == :comment
          advance
          next
        end
        if is_special_function && current_token && current_token[:type] == :string
          # For functions like map(), filter(), directly add the string as an argument
          string_token = parse_string
          args << {
            type: :literal,
            value: string_token[:value],
            token_type: :string,
            line: string_token[:line],
            column: string_token[:column]
          }
        else
          # Parse the argument
          arg = parse_expression
          args << arg if arg
        end

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

    def parse_vim_lambda_or_dict(line, column)
      # Save current position to peek ahead
      start_position = @position

      advance # Skip opening brace

      # Check if this is a lambda by looking for parameter names followed by arrow
      is_lambda = false
      param_names = []

      # Parse until closing brace or arrow
      while @position < @tokens.length && current_token[:type] != :brace_close
        if current_token[:type] == :identifier
          param_names << current_token[:value]
          advance

          # Skip comma between parameters
          if current_token && current_token[:type] == :comma
            advance
            next
          end
        elsif current_token[:type] == :operator && current_token[:value] == '->'
          is_lambda = true
          break
        else
          # If we see a colon, this is likely a nested dictionary
          if current_token && current_token[:type] == :colon
            break
          end
          advance
        end
      end

      # Reset position
      @position = start_position

      if is_lambda
        return parse_vim_lambda(line, column)
      else
        return parse_dict_literal(line, column)
      end
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

    def parse_command_definition
      token = advance # Skip 'command' or 'command!'
      line = token[:line]
      column = token[:column]

      # Check if the command has a bang (!)
      has_bang = false
      if current_token && current_token[:type] == :operator && current_token[:value] == '!'
        has_bang = true
        advance # Skip '!'
      end

      # Parse command options/attributes (starting with hyphen)
      attributes = []
      while current_token && (
        (current_token[:type] == :operator && current_token[:value] == '-') ||
        (current_token[:type] == :identifier && current_token[:value].start_with?('-'))
      )
        # Handle option as a single attribute if it's already combined
        if current_token[:type] == :identifier && current_token[:value].start_with?('-')
          attributes << current_token[:value]
          advance
        else
          # Otherwise combine the hyphen with the following identifier
          advance # Skip the hyphen
          if current_token && current_token[:type] == :identifier
            attributes << "-#{current_token[:value]}"
            advance
          end
        end

        # If there's an = followed by a value, include it in the attribute
        if current_token && current_token[:type] == :operator && current_token[:value] == '='
          attribute = attributes.pop # Take the last attribute we added
          advance # Skip the '='

          # Get the value (number or identifier)
          if current_token && (current_token[:type] == :number || current_token[:type] == :identifier)
            attribute += "=#{current_token[:value]}"
            attributes << attribute
            advance
          end
        end
      end

      # Parse the command name
      command_name = nil
      if current_token && current_token[:type] == :identifier
        command_name = current_token[:value]
        advance
      else
        @errors << {
          message: "Expected command name",
          position: @position,
          line: current_token ? current_token[:line] : 0,
          column: current_token ? current_token[:column] : 0
        }
      end

      # Parse the command implementation - collect all remaining tokens as raw parts
      implementation_parts = []
      while @position < @tokens.length
        # Break on end of line or comment
        if !current_token || current_token[:type] == :comment ||
           (current_token[:value] == "\n" && !current_token[:value].start_with?("\\"))
          break
        end

        implementation_parts << current_token
        advance
      end

      {
        type: :command_definition,
        name: command_name,
        has_bang: has_bang,
        attributes: attributes,
        implementation: implementation_parts,
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

      # Handle special case: varargs at the start of the parameter list
      if current_token && (
        (current_token[:type] == :ellipsis) ||
        (current_token[:type] == :operator && current_token[:value] == '.')
      )
        if current_token[:type] == :ellipsis
          token = advance
          params << {
            type: :var_args_legacy,
            name: '...',
            line: token[:line],
            column: token[:column]
          }
          return params
        else
          # Count consecutive dots
          dot_count = 0
          first_dot_token = current_token

          # Store the line and column before we advance
          dot_line = first_dot_token[:line]
          dot_column = first_dot_token[:column]

          while current_token && current_token[:type] == :operator && current_token[:value] == '.'
            dot_count += 1
            advance
          end

          if dot_count == 3
            params << {
              type: :var_args_legacy,
              name: '...',
              line: dot_line,
              column: dot_column
            }
            return params
          end
        end
      end

      # Regular parameter parsing (existing logic)
      loop do
        if current_token && current_token[:type] == :identifier
          param_name = advance

          # Check for default value
          default_value = nil
          if current_token && current_token[:type] == :operator && current_token[:value] == '='
            advance # Skip '='
            default_value = parse_expression
          end

          params << {
            type: :parameter,
            name: param_name[:value],
            default_value: default_value,
            optional: default_value != nil,
            line: param_name[:line],
            column: param_name[:column]
          }
        elsif current_token && current_token[:type] == :arg_variable
          param_name = advance
          name_without_prefix = param_name[:value].sub(/^a:/, '')

          # Check for default value
          default_value = nil
          if current_token && current_token[:type] == :operator && current_token[:value] == '='
            advance # Skip '='
            default_value = parse_expression
          end

          params << {
            type: :parameter,
            name: name_without_prefix,
            default_value: default_value,
            optional: default_value != nil,
            line: param_name[:line],
            column: param_name[:column],
            is_arg_prefixed: true
          }
        else
          # We might be at varargs after other parameters
          if current_token && (
            (current_token[:type] == :ellipsis) ||
            (current_token[:type] == :operator && current_token[:value] == '.')
          )
            # Add debug
            #puts "Found potential varargs token: #{current_token[:type]} #{current_token[:value]}"

            if current_token[:type] == :ellipsis
              token = current_token  # STORE the token before advancing
              advance
              params << {
                type: :var_args_legacy,
                name: '...',
                line: token[:line],   # Use stored token
                column: token[:column]
              }
            else
              dot_count = 0
              first_dot_token = current_token

              # Store line/column BEFORE advancing
              dot_line = first_dot_token[:line]
              dot_column = first_dot_token[:column]

              #puts "Starting dot sequence at line #{dot_line}, column #{dot_column}"

              while current_token && current_token[:type] == :operator && current_token[:value] == '.'
                dot_count += 1
                #puts "Found dot #{dot_count}"
                advance
              end

              if dot_count == 3
                #puts "Complete varargs found (3 dots)"
                params << {
                  type: :var_args_legacy,
                  name: '...',
                  line: dot_line,     # Use stored values
                  column: dot_column
                }
              else
                #puts "Incomplete varargs: only #{dot_count} dots found"
              end
            end
            break
          else
            # Add debug to see what unexpected token we're encountering
            #puts "Unexpected token in parameter list: #{current_token ? current_token[:type] : 'nil'} #{current_token ? current_token[:value] : ''}"

            # Not a valid parameter or varargs
            @errors << {
              message: "Expected parameter name",
              position: @position,
              line: current_token ? current_token[:line] : 0,
              column: current_token ? current_token[:column] : 0
            }
            break
          end
        end
        if current_token && current_token[:type] == :comma
          advance
        else
          break
        end
      end

      params
    end

    def parse_try_statement
      token = advance # Skip 'try'
      line = token[:line]
      column = token[:column]

      # Parse the try body
      body = []
      catch_clauses = []
      finally_clause = nil

      # Parse statements in the try block
      while @position < @tokens.length
        if current_token && current_token[:type] == :keyword &&
           ['catch', 'finally', 'endtry'].include?(current_token[:value])
          break
        end

        stmt = parse_statement
        body << stmt if stmt
      end

      # Parse catch clauses
      while @position < @tokens.length &&
            current_token && current_token[:type] == :keyword &&
            current_token[:value] == 'catch'
        catch_token = advance # Skip 'catch'
        catch_line = catch_token[:line]
        catch_column = catch_token[:column]

        # Parse the pattern (anything until the next statement)
        pattern = ''
        pattern_tokens = []

        # Collect all tokens until we hit a newline or a statement
        while @position < @tokens.length
          if !current_token ||
             (current_token[:type] == :whitespace && current_token[:value].include?("\n")) ||
             current_token[:type] == :comment
            break
          end

          pattern_tokens << current_token
          pattern += current_token[:value]
          advance
        end

        # Parse the catch body
        catch_body = []
        while @position < @tokens.length
          if current_token && current_token[:type] == :keyword &&
             ['catch', 'finally', 'endtry'].include?(current_token[:value])
            break
          end

          stmt = parse_statement
          catch_body << stmt if stmt
        end

        catch_clauses << {
          type: :catch_clause,
          pattern: pattern.strip,
          body: catch_body,
          line: catch_line,
          column: catch_column
        }
      end

      # Parse finally clause if present
      if @position < @tokens.length &&
         current_token && current_token[:type] == :keyword &&
         current_token[:value] == 'finally'
        finally_token = advance # Skip 'finally'
        finally_line = finally_token[:line]
        finally_column = finally_token[:column]

        # Parse the finally body
        finally_body = []
        while @position < @tokens.length
          if current_token && current_token[:type] == :keyword && current_token[:value] == 'endtry'
            break
          end

          stmt = parse_statement
          finally_body << stmt if stmt
        end

        finally_clause = {
          type: :finally_clause,
          body: finally_body,
          line: finally_line,
          column: finally_column
        }
      end

      # Expect endtry
      if current_token && current_token[:type] == :keyword && current_token[:value] == 'endtry'
        advance # Skip 'endtry'
      else
        # Only add an error if we haven't reached the end of the file
        if @position < @tokens.length
          @errors << {
            message: "Expected 'endtry' to close try statement",
            position: @position,
            line: current_token ? current_token[:line] : 0,
            column: current_token ? current_token[:column] : 0
          }
        end
      end

      return {
        type: :try_statement,
        body: body,
        catch_clauses: catch_clauses,
        finally_clause: finally_clause,
        line: line,
        column: column
      }
    end

    # Also add a method to parse throw statements:

    def parse_throw_statement
      token = advance # Skip 'throw'
      line = token[:line]
      column = token[:column]

      # Parse the expression to throw
      expression = parse_expression

      return {
        type: :throw_statement,
        expression: expression,
        line: line,
        column: column
      }
    end

    def parse_call_statement
      token = advance # Skip 'call'
      line = token[:line]
      column = token[:column]

      # Parse the function call expression that follows 'call'
      func_expr = nil

      if current_token && current_token[:type] == :script_local
        # Handle script-local function call (s:func_name)
        func_name = current_token[:value]
        func_line = current_token[:line]
        func_column = current_token[:column]
        advance

        # Parse arguments
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

        func_expr = {
          type: :script_local_call,
          name: func_name,
          arguments: args,
          line: func_line,
          column: func_column
        }
      else
        # For other function calls
        func_expr = parse_expression
      end

      {
        type: :call_statement,
        expression: func_expr,
        line: line,
        column: column
      }
    end

    def parse_string
      # Start with the first string or expression
      left = parse_primary_term

      # Continue as long as we see the '.' or '..' string concatenation operator
      while current_token && current_token[:type] == :operator &&
            (current_token[:value] == '.' || current_token[:value] == '..')

        # Store the operator token
        op_token = advance # Skip the operator
        op = op_token[:value]

        # If this is the dot operator, check if it's actually part of '..'
        if op == '.' && peek_token && peek_token[:type] == :operator && peek_token[:value] == '.'
          advance # Skip the second dot
          op = '..'
        end

        # Parse the right side of the concatenation
        right = parse_primary_term

        # Create a string concatenation expression
        left = {
          type: :string_concatenation,
          operator: op,
          left: left,
          right: right,
          line: op_token[:line],
          column: op_token[:column]
        }
      end

      return left
    end

    # Helper function to parse a primary term in string expressions
    def parse_primary_term
      if !current_token
        return nil
      end

      token = current_token
      line = token[:line]
      column = token[:column]

      case token[:type]
      when :string
        # Handle string literal
        advance
        return {
          type: :literal,
          value: token[:value],
          token_type: :string,
          line: line,
          column: column
        }
      when :identifier, :global_variable, :script_local, :arg_variable,
           :local_variable, :buffer_local, :window_local, :tab_local
        # Handle variable references
        advance
        return {
          type: token[:type],
          name: token[:value],
          line: line,
          column: column
        }
      when :paren_open
        # Handle parenthesized expressions
        advance # Skip '('
        expr = parse_expression
        expect(:paren_close) # Skip ')'
        return expr
      when :function
        # Handle function calls
        return parse_function_call(token[:value], line, column)
      else
        # For anything else, use the standard expression parser
        return parse_expression
      end
    end

    def parse_silent_command
      token = advance # Skip 'silent'
      line = token[:line]
      column = token[:column]

      # Check for ! after silent
      has_bang = false
      if current_token && current_token[:type] == :operator && current_token[:value] == '!'
        has_bang = true
        advance # Skip '!'
      end

      # Now parse the command that follows silent
      # It could be a standard command or a command with a range
      command = nil

      # Check if the next token is a range operator (% in this case)
      if current_token && current_token[:type] == :operator && current_token[:value] == '%'
        range_token = advance # Skip '%'

        # Now we expect a command (like 'delete')
        if current_token &&
           (current_token[:type] == :keyword || current_token[:type] == :identifier)
          cmd_token = advance # Skip the command name
          cmd_name = cmd_token[:value]

          # Parse any arguments to the command
          args = []
          while current_token &&
                current_token[:type] != :comment &&
                (current_token[:value] != "\n" ||
                 (current_token[:value] == "\n" &&
                  !current_token[:value].start_with?("\\")))

            # Add the token as an argument
            args << current_token
            advance
          end

          command = {
            type: :range_command,
            range: '%',
            command: {
              type: :command,
              name: cmd_name,
              args: args,
              line: cmd_token[:line],
              column: cmd_token[:column]
            },
            line: range_token[:line],
            column: range_token[:column]
          }
        else
          @errors << {
            message: "Expected command after range operator '%'",
            position: @position,
            line: current_token ? current_token[:line] : range_token[:line],
            column: current_token ? current_token[:column] : range_token[:column] + 1
          }
        end
      else
        # Parse a regular command
        command = parse_statement
      end

      return {
        type: :silent_command,
        has_bang: has_bang,
        command: command,
        line: line,
        column: column
      }
    end

    def parse_delete_command
      token = advance # Skip 'delete'
      line = token[:line]
      column = token[:column]

      # Check for register argument (could be an underscore '_')
      register = nil
      if current_token
        if current_token[:type] == :identifier && current_token[:value] == '_'
          register = current_token[:value]
          advance
        elsif current_token[:type] == :operator && current_token[:value] == '_'
          # Handle underscore as an operator (some lexers might classify it this way)
          register = current_token[:value]
          advance
        end
      end

      return {
        type: :delete_command,
        register: register,
        line: line,
        column: column
      }
    end
  end
end
