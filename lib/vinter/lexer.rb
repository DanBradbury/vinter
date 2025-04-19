module Vinter
  class Lexer
    TOKEN_TYPES = {
      # Vim9 specific keywords
      keyword: /\b(if|else|elseif|endif|while|endwhile|for|endfor|def|enddef|function|endfunction|endfunc|return|const|var|final|import|export|class|extends|static|enum|type|vim9script|abort|autocmd|echoerr|echohl|echomsg|let|execute|continue|break|try|catch|finally|endtry|throw)\b/,
      # Identifiers can include # and special characters
      identifier: /\b[a-zA-Z_][a-zA-Z0-9_#]*\b/,
      # Single-character operators
      operator: /[\+\-\*\/=<>!&\|\.]/,
      # Multi-character operators handled separately
      number: /\b\d+(\.\d+)?\b/,
      # Handle both single and double quoted strings
      string: /"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/,
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
        if match = chunk.match(/\Aa:[a-zA-Z_][a-zA-Z0-9_]*/)
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
        if match = chunk.match(/\A(\+=|-=|\*=|\/=|\.\.=)/)
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
        if match = chunk.match(/\A(==#|==|!=|=>|->|\.\.|\|\||&&)/)
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
            type: :backslash,
            value: '\\',
            line: @line_num,
            column: @column
          }
          @column += 1
          @position += 1
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
