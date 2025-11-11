require 'spec_helper'

RSpec.describe Vinter::Parser do
  let(:parse) do
    lambda do |input|
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      parser.parse
    end
  end

  describe '#parse' do
    context 'Legacy VimScript syntax' do
      describe 'variable assignments' do
        it 'parses simple let statements with global variables' do
          result = parse.call("let g:thing = 10")

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:let_statement)
        end

        it 'parses let statements with local variables' do
          result = parse.call("let l:foo = 1")

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:let_statement)
          expect(result[:ast][:body][0][:target][:type]).to eq(:local_variable)
          expect(result[:ast][:body][0][:target][:name]).to eq("l:foo")
        end

        it 'parses let statements with builtin function calls' do
          result = parse.call("let g:NERDTreeAutoCenter = get(g:, 'NERDTreeAutoCenter', 1)")

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:let_statement)
          expect(result[:ast][:body][0][:value][:type]).to eq(:builtin_function_call)
          arguments = result[:ast][:body][0][:value][:arguments]
          expect(arguments.count).to eq(3)
          expect(arguments.map { |f| f[:type] }).to eq([:namespace_prefix, :literal, :literal])
        end

        it 'parses let statements with compound assignment operators' do
          result = parse.call("let l:text .= substitute(l:changelog[l:line+1], '^.\{-}\(\.\d\+\).\{-}:\(.*\)', a:0>0 ? '\1:\2' : '\1', '')")

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:let_statement)
        end

        it 'parses let statements with ternary operators' do
          result = parse.call("let l:text .= substitute(l:changelog[l:line+1], '^.\{-}\(\.\d\+\).\{-}:\(.*\)', a:0>0 ? '\1:\2' : '\1', '')")

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:let_statement)
        end
      end

      describe 'function definitions' do
        it 'parses legacy function definitions' do
          input = <<-VIM
            function! NERDTreeCWD()
                if empty(getcwd())
                    call nerdtree#echoWarning('current directory does not exist')
                    return
                endif
            endfunction
          VIM
          result = parse.call(input)

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:legacy_function)
        end

        it 'parses legacy functions with abort flag' do
          input = <<-VIM
            function! nerdtree#completeBookmarks(A,L,P) abort
              return filter(g:NERDTreeBookmark.BookmarkNames(), 'v:val =~# "^' . a:A . '"')
            endfunction
          VIM
          result = parse.call(input)

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:legacy_function)
        end

        it 'parses legacy functions with multiple parameters' do
          input = <<-VIM
            function! nerdtree#compareNodePaths(p1, p2) abort
                " Keys are identical upto common length
                " The key which has smaller chunks is the lesser one
                return a:p1
            endfunction
          VIM
          result = parse.call(input)

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:legacy_function)
        end

        it 'parses legacy functions with string return values' do
          input = <<-VIM
            function! test() abort
              return '\'
            endfunction
          VIM
          result = parse.call(input)

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:legacy_function)
        end
      end

      describe 'comments' do
        it 'parses legacy-style string comments' do
          result = parse.call('"for line continuation - i.e dont want C in &cpoptions"')

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:comment)
        end
      end

      describe 'output statements' do
        it 'parses echo statements' do
          result = parse.call('echo "testing"')

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:echo_statement)
        end

        it 'parses echo statements with detailed content' do
          result = parse.call("echo 'hello'")
          
          expect(result[:ast][:body][0][:type]).to eq(:echo_statement)
          expect(result[:ast][:body][0][:expression][:type]).to eq(:literal)
          expect(result[:ast][:body][0][:expression][:token_type]).to eq(:string)
          expect(result[:ast][:body][0][:expression][:value]).to eq("'hello'")
        end

        it 'parses echoerr statements' do
          result = parse.call('echoerr "NERDTree: this plugin requires vim >= 7.3. DOWNLOAD IT! "')

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:echo_statement)
        end
      end
    end

    context 'Vim9 script syntax' do
      describe 'declarations' do
        it 'parses vim9script declaration' do
          result = parse.call("vim9script")

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:vim9script_declaration)
        end
      end

      describe 'variable declarations' do
        it 'parses var declarations without type annotations' do
          result = parse.call("var x = 10")

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:variable_declaration)
          expect(result[:ast][:body][0][:var_type]).to eq("var")
          expect(result[:ast][:body][0][:name]).to eq("x")
          expect(result[:ast][:body][0][:initializer][:type]).to eq(:literal)
          expect(result[:ast][:body][0][:initializer][:value]).to eq("10")
        end

        it 'parses var declarations with type annotations' do
          result = parse.call("var x: number = 10")

          expect(result[:ast][:body][0][:var_type_annotation]).to eq("number")
        end

        it 'parses const declarations' do
          result = parse.call("const myList = [1, 2, 3]")

          expect(result[:ast][:body][0][:type]).to eq(:variable_declaration)
          expect(result[:ast][:body][0][:var_type]).to eq("const")
          expect(result[:ast][:body][0][:name]).to eq("myList")
          expect(result[:ast][:body][0][:initializer][:type]).to eq(:list_literal)
          expect(result[:ast][:body][0][:initializer][:elements].size).to eq(3)
          expect(result[:ast][:body][0][:initializer][:elements][0][:value]).to eq("1")
        end
      end

      describe 'function definitions' do
        it 'parses def functions with type annotations' do
          result = parse.call("def Add(x: number, y: number): number\n  return x + y\nenddef")

          expect(result[:ast][:body][0][:type]).to eq(:def_function)
          expect(result[:ast][:body][0][:name]).to eq("Add")
          expect(result[:ast][:body][0][:params].size).to eq(2)
          expect(result[:ast][:body][0][:params][0][:name]).to eq("x")
          expect(result[:ast][:body][0][:params][0][:param_type]).to eq("number")
          expect(result[:ast][:body][0][:return_type]).to eq("number")
          expect(result[:ast][:body][0][:body].size).to eq(1)
          expect(result[:ast][:body][0][:body][0][:type]).to eq(:return_statement)
        end
      end

      describe 'import and export statements' do
        it 'parses import statements' do
          result = parse.call("import autoload '../autoload/foo.vim'")

          expect(result[:ast][:body][0][:type]).to eq(:import_statement)
          expect(result[:ast][:body][0][:module]).to eq("autoload")
          expect(result[:ast][:body][0][:path]).to eq("'../autoload/foo.vim'")
        end

        it 'parses export statements with def functions' do
          result = parse.call("export def Greet(name: string): string\n  return 'Hello, ' .. name\nenddef")

          expect(result[:ast][:body][0][:type]).to eq(:export_statement)
          expect(result[:ast][:body][0][:export][:type]).to eq(:def_function)
          expect(result[:ast][:body][0][:export][:name]).to eq("Greet")
        end
      end
    end

    context 'control flow structures' do
      describe 'conditionals' do
        it 'parses if statements without else' do
          input = <<-VIM
            if empty(getcwd())
                call nerdtree#echoWarning('current directory does not exist')
                return
            endif
          VIM
          result = parse.call(input)

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:if_statement)
        end

        it 'parses if statements with else branches' do
          result = parse.call("if x > 10\n  echo 'greater'\nelse\n  echo 'less or equal'\nendif")

          expect(result[:ast][:body][0][:type]).to eq(:if_statement)
          expect(result[:ast][:body][0][:then_branch].size).to eq(1)
          expect(result[:ast][:body][0][:else_branch].size).to eq(1)
        end
      end

      describe 'loops' do
        it 'parses while loops' do
          input = """
          while l:line <= len(l:changelog)
              let l:line += 1
          endwhile
          """
          result = parse.call(input)

          expect(result[:ast][:type]).to eq(:program)
          expect(result[:ast][:body].size).to eq(1)
          expect(result[:ast][:body][0][:type]).to eq(:while_statement)
        end
      end
    end

    context 'data structures' do
      describe 'lists' do
        it 'parses non-empty list literals' do
          result = parse.call("const myList = [1, 2, 3]")

          expect(result[:ast][:body][0][:type]).to eq(:variable_declaration)
          expect(result[:ast][:body][0][:var_type]).to eq("const")
          expect(result[:ast][:body][0][:name]).to eq("myList")
          expect(result[:ast][:body][0][:initializer][:type]).to eq(:list_literal)
          expect(result[:ast][:body][0][:initializer][:elements].size).to eq(3)
          expect(result[:ast][:body][0][:initializer][:elements][0][:value]).to eq("1")
        end

        it 'parses empty list literals' do
          result = parse.call("var emptyList = []")

          expect(result[:ast][:body][0][:initializer][:type]).to eq(:list_literal)
          expect(result[:ast][:body][0][:initializer][:elements]).to be_empty
        end
      end

      describe 'lambda expressions' do
        it 'parses lambda expressions with single parameter' do
          result = parse.call("var Lambda = (arg) => expression")

          expect(result[:ast][:body][0][:type]).to eq(:variable_declaration)
          expect(result[:ast][:body][0][:initializer][:type]).to eq(:lambda_expression)
          expect(result[:ast][:body][0][:initializer][:params].size).to eq(1)
          expect(result[:ast][:body][0][:initializer][:params][0][:name]).to eq("arg")
        end

        it 'parses lambda expressions with multiple parameters' do
          result = parse.call("filter(list, (k, v) => v > 0)")

          expect(result[:ast][:body][0][:type]).to eq(:filter_command)
        end
      end

      describe 'filter commands' do
        it 'parses filter commands with lambda expressions' do
          result = parse.call("filter(list, (k, v) => v > 0)")

          expect(result[:ast][:body][0][:type]).to eq(:filter_command)
        end
      end
    end

    context 'error handling' do
      # TODO: Parser currently does not detect this error - needs enhancement
      xit 'detects syntax errors in incomplete def functions' do
        result = parse.call("def MissingEnddef()")

        expect(result[:errors].size).to be > 0
      end
    end
  end
end
