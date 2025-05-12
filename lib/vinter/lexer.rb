module Vinter
  class Lexer
    TOKEN_TYPES = {
      # Vim9 specific keywords
      keyword: /\b(if|else|elseif|endif|while|endwhile|for|endfor|def|enddef|function|endfunction|endfunc|return|const|var|final|import|export|class|extends|static|enum|type|vim9script|abort|autocmd|echom|echoerr|echohl|echomsg|let|execute|continue|break|try|catch|finally|endtry|throw|runtime|silent|delete|command|nnoremap|nmap|inoremap|imap|vnoremap|vmap|xnoremap|xmap|cnoremap|cmap|noremap|map)\b/,
      # Identifiers can include # and special characters
      identifier: /\b[a-zA-Z_][a-zA-Z0-9_#]*\b/,
      # Single-character operators
      operator: /[\+\-\*\/=<>!&\|\.]/,
      # Multi-character operators handled separately
      number: /\b(0[xX][0-9A-Fa-f]+|0[oO][0-7]+|0[bB][01]+|\d+(\.\d+)?([eE][+-]?\d+)?)\b/,
      # Handle both single and double quoted strings
      # string: /"(\\"|[^"])*"|'(\\'|[^'])*'/,
      register_access: /@[a-zA-Z0-9":.%#=*+~_\/\-]/,
      # Vim9 comments use #
      comment: /(#|").*/,
      whitespace: /\s+/,
      brace_open: /\{/,
      brace_close: /\}/,
      paren_open: /\(/,
      paren_close: /\)/,
      bracket_open: /\[/,
      bracket_close: /\]/,
      colon: /:/,
      semicolon: /;/,
      comma: /,/,
      backslash: /\\/,
    }

    CONTINUATION_OPERATORS = %w(. .. + - * / = == ==# ==? != > < >= <= && || ? : -> =>)
    def initialize(input)
      @input = input
      @tokens = []
      @position = 0
      @line_num = 1
      @column = 1
    end

    def tokenize
      until @position >= @input.length
        chunk = @input[@position..-1]

        # First check if the line starts with a quote (comment in Vim)
        current_line_start = @input.rindex("\n", @position) || 0
        current_line_start += 1 if @input[current_line_start] == "\n"
        # If we're at the start of a line and it begins with a quote
        if @position == current_line_start && chunk.start_with?('"')
          # Find the end of the line
          line_end = chunk.index("\n") || chunk.length
          comment_text = chunk[0...line_end]

          @tokens << {
            type: :comment,
            value: comment_text,
            line: @line_num,
            column: @column
          }

          @position += comment_text.length
          @column += comment_text.length
          next
        end
        # Handle string literals manually
        if chunk.start_with?("'") || chunk.start_with?('"')
          quote = chunk[0]
          i = 1
          escaped = false
          string_value = quote

          # Keep going until we find an unescaped closing quote
          while i < chunk.length
            char = chunk[i]
            string_value += char

            if char == '\\' && !escaped
              escaped = true
            elsif (char == "\n" or char == quote) && !escaped
              # Found closing quote
              break
            elsif escaped
              escaped = false
            end

            i += 1
          end

          # Add the string token if we found a closing quote
          if i < chunk.length || (i == chunk.length && chunk[-1] == quote)
            @tokens << {
              type: :string,
              value: string_value,
              line: @line_num,
              column: @column
            }

            @column += string_value.length
            @position += string_value.length
            @line_num += 1 if string_value.include?("\n")
            next
          end
        end

        # Add special handling for command options in the tokenize method
        if chunk.start_with?('<q-args>', '<f-args>', '<args>')
          arg_token = chunk.match(/\A(<q-args>|<f-args>|<args>)/)[0]
          @tokens << {
            type: :command_arg_placeholder,
            value: arg_token,
            line: @line_num,
            column: @column
          }
          @column += arg_token.length
          @position += arg_token.length
          next
        end

        # Also add special handling for 'silent!' keyword
        # Add this after the keyword check in tokenize method
        if chunk.start_with?('silent!')
          @tokens << {
            type: :silent_bang,
            value: 'silent!',
            line: @line_num,
            column: @column
          }
          @column += 7
          @position += 7
          next
        end

        # Check for keywords first, before other token types
        if match = chunk.match(/\A\b(if|else|elseif|endif|while|endwhile|for|endfor|def|enddef|function|endfunction|endfunc|return|const|var|final|import|export|class|extends|static|enum|type|vim9script|abort|autocmd|echoerr|echohl|echomsg|let|execute)\b/)
          @tokens << {
            type: :keyword,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle Vim option variables with & prefix
        if match = chunk.match(/\A&[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :option_variable,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle Vim special variables with v: prefix
        if match = chunk.match(/\Av:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :special_variable,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle script-local identifiers with s: prefix
        if match = chunk.match(/\As:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :script_local,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle buffer-local identifiers with b: prefix
        if match = chunk.match(/\Ab:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :buffer_local,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle window-local identifiers with w: prefix
        if match = chunk.match(/\Aw:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :window_local,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle tab-local identifiers with t: prefix
        if match = chunk.match(/\At:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :tab_local,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end


        # Handle global variables with g: prefix
        if match = chunk.match(/\Ag:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :global_variable,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle argument variables with a: prefix
        if match = chunk.match(/\Aa:[a-zA-Z_][a-zA-Z0-9_]*/) || match = chunk.match(/\Aa:[A-Z0-9]/)
          @tokens << {
            type: :arg_variable,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle argument variables with a: prefix
        if match = chunk.match(/\Al:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :local_variable,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Add support for standalone namespace prefixes (like g:)
        if match = chunk.match(/\A([sgbwtal]):/)
          @tokens << {
            type: :namespace_prefix,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle compound assignment operators
        if match = chunk.match(/\A(\+=|-=|\*=|\/=|\.\.=|\.=)/)
          @tokens << {
            type: :compound_operator,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle ellipsis for variable args
        if chunk.start_with?('...')
          @tokens << {
            type: :ellipsis,
            value: '...',
            line: @line_num,
            column: @column
          }
          @column += 3
          @position += 3
          next
        end

        # Handle multi-character operators explicitly
        if match = chunk.match(/\A(=~#|=~\?|=~|!~#|!~\?|!~|==#|==\?|==|!=#|!=\?|!=|=>\?|=>|>=#|>=\?|>=|<=#|<=\?|<=|->#|->\?|->|\.\.|\|\||&&)/)
          @tokens << {
            type: :operator,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle register access (@a, @", etc.)
        if chunk =~ /\A@[a-zA-Z0-9":.%#=*+~_\/\-]/
          register_token = chunk.match(/\A@[a-zA-Z0-9":.%#=*+~_\/\-]/)[0]
          @tokens << {
            type: :register_access,
            value: register_token,
            line: @line_num,
            column: @column
          }
          @column += register_token.length
          @position += register_token.length
          next
        end

        # In the tokenize method, add special handling for common mapping components
        if chunk.start_with?('<CR>', '<Esc>', '<Tab>', '<Space>', '<C-') ||
           (chunk =~ /\A<[A-Za-z0-9\-_]+>/)
          # Extract the special key notation
          match = chunk.match(/\A(<[^>]+>)/)
          if match
            special_key = match[1]
            @tokens << {
              type: :special_key,
              value: special_key,
              line: @line_num,
              column: @column
            }
            @position += special_key.length
            @column += special_key.length
            next
          end
        end

        # Skip whitespace but track position
        if match = chunk.match(/\A(\s+)/)
          whitespace = match[0]
          whitespace.each_char do |c|
            if c == "\n"
              @line_num += 1
              @column = 1
            else
              @column += 1
            end
          end
          @position += whitespace.length
          next
        end

        # Handle backslash for line continuation
        if chunk.start_with?('\\')
          @tokens << {
            type: :line_continuation,
            value: '\\',
            line: @line_num,
            column: @column
          }
          @column += 1
          @position += 1

          # If followed by a newline, advance to next line
          if @position < @input.length && @input[@position] == "\n"
            @line_num += 1
            @column = 1
            @position += 1
          end

          next
        end

        # Check for special case where 'function' is followed by '('
        # which likely means it's used as a built-in function
        if chunk =~ /\Afunction\s*\(/
          @tokens << {
            type: :identifier,  # Treat as identifier, not keyword
            value: 'function',
            line: @line_num,
            column: @column
          }
          @column += 'function'.length
          @position += 'function'.length
          next
        end

        match_found = false

        TOKEN_TYPES.each do |type, pattern|
          if match = chunk.match(/\A(#{pattern})/)
            value = match[0]
            token = {
              type: type,
              value: value,
              line: @line_num,
              column: @column
            }
            @tokens << token unless type == :whitespace

            # Update position
            if value.include?("\n")
              lines = value.split("\n")
              @line_num += lines.size - 1
              if lines.size > 1
                @column = lines.last.length + 1
              else
                @column += value.length
              end
            else
              @column += value.length
            end

            @position += value.length
            match_found = true
            break
          end
        end

        unless match_found
          # Try to handle unknown characters
          @tokens << {
            type: :unknown,
            value: chunk[0],
            line: @line_num,
            column: @column
          }

          if chunk[0] == "\n"
            @line_num += 1
            @column = 1
          else
            @column += 1
          end

          @position += 1
        end
      end

      @tokens
    end
  end
end
