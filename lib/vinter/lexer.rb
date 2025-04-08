module Vinter
  class Lexer
    TOKEN_TYPES = {
      # Vim9 specific keywords
      keyword: /\b(if|else|elseif|endif|while|endwhile|for|endfor|def|enddef|function|endfunction|return|const|var|final|import|export|class|extends|static|enum|type|vim9script|abort|autocmd)\b/,
      # Identifiers can include # and special characters
      identifier: /\b[a-zA-Z_][a-zA-Z0-9_#]*\b/,
      # Single-character operators
      operator: /[\+\-\*\/=<>!&\|\.]/,
      # Multi-character operators handled separately
      number: /\b\d+(\.\d+)?\b/,
      # Handle both single and double quoted strings
      string: /"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/,
      # Vim9 comments use #
      comment: /#.*/,
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
    }

    CONTINUATION_OPERATORS = %w(. .. + - * / = == != > < >= <= && || ? : -> =>)
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

        # Handle multi-character operators explicitly
        if match = chunk.match(/\A(==|!=|=>|->|\.\.)/)
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
