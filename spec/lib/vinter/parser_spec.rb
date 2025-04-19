require 'spec_helper'

RSpec.describe Vinter::Parser do
  describe '#parse' do
    it "parses a simple let" do
      input = "let g:thing = 10"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:type]).to eq(:program)
      expect(result[:ast][:body].size).to eq(1)
      expect(result[:ast][:body][0][:type]).to eq(:let_statement)
    end

    it "handles complicated stuff" do
      input = 'echoerr "NERDTree: this plugin requires vim >= 7.3. DOWNLOAD IT! "'
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:type]).to eq(:program)
      expect(result[:ast][:body].size).to eq(1)
      expect(result[:ast][:body][0][:type]).to eq(:echo_statement)
    end

    it "more complicated stuff" do
      input = 'echo "testing"'
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:type]).to eq(:program)
      expect(result[:ast][:body].size).to eq(1)
      expect(result[:ast][:body][0][:type]).to eq(:echo_statement)
    end

    it "handles legacy comments" do
      input = '"for line continuation - i.e dont want C in &cpoptions"'
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:type]).to eq(:program)
      expect(result[:ast][:body].size).to eq(1)
      expect(result[:ast][:body][0][:type]).to eq(:comment)
    end

    it "parses setting globals with get" do
      input = "let g:NERDTreeAutoCenter            = get(g:, 'NERDTreeAutoCenter',            1)"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse
      # puts result.inspect

      expect(result[:ast][:type]).to eq(:program)
      expect(result[:ast][:body].size).to eq(1)
      expect(result[:ast][:body][0][:type]).to eq(:let_statement)
      expect(result[:ast][:body][0][:value][:type]).to eq(:function_call)
      arguments = result[:ast][:body][0][:value][:arguments]
      expect(arguments.count).to eq(3)
      expect(arguments.map{ |f| f[:type]}).to eq([:namespace_prefix, :literal, :literal])
    end

    it "parses nested conditions" do
      input = <<-VIM
        function! NERDTreeCWD()
            if empty(getcwd())
                call nerdtree#echoWarning('current directory does not exist')
                return
            endif
        endfunction
      VIM

      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse
      # puts result[:ast].inspect

      expect(result[:ast][:type]).to eq(:program)
      expect(result[:ast][:body].size).to eq(1)
      expect(result[:ast][:body][0][:type]).to eq(:legacy_function)
    end

    it "parses basic conditional" do
      input = <<-VIM
          if empty(getcwd())
              call nerdtree#echoWarning('current directory does not exist')
              return
          endif
      VIM

      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse
      # puts result[:ast].inspect

      expect(result[:ast][:type]).to eq(:program)
      expect(result[:ast][:body].size).to eq(1)
      expect(result[:ast][:body][0][:type]).to eq(:if_statement)
    end

    it "parses lets with l: variables" do
      input = "let l:foo = 1"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse
      # puts result[:ast].inspect

      expect(result[:ast][:type]).to eq(:program)
      expect(result[:ast][:body].size).to eq(1)
      expect(result[:ast][:body][0][:type]).to eq(:let_statement)
      expect(result[:ast][:body][0][:target][:type]).to eq(:local_variable)
      expect(result[:ast][:body][0][:target][:name]).to eq("l:foo")
    end

    it "parses while loops correctly" do
      input = """
      while l:line <= len(l:changelog)
          let l:line += 1
      endwhile
      """
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse
      puts result[:ast].inspect

      expect(result[:ast][:type]).to eq(:program)
      expect(result[:ast][:body].size).to eq(1)
      expect(result[:ast][:body][0][:type]).to eq(:while_statement)
    end

    it 'parses vim9script declaration' do
      input = "vim9script"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:type]).to eq(:program)
      expect(result[:ast][:body].size).to eq(1)
      expect(result[:ast][:body][0][:type]).to eq(:vim9script_declaration)
    end

    it 'parses variable declarations' do
      input = "var x = 10"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:type]).to eq(:program)
      expect(result[:ast][:body].size).to eq(1)
      expect(result[:ast][:body][0][:type]).to eq(:variable_declaration)
      expect(result[:ast][:body][0][:var_type]).to eq("var")
      expect(result[:ast][:body][0][:name]).to eq("x")
      expect(result[:ast][:body][0][:initializer][:type]).to eq(:literal)
      expect(result[:ast][:body][0][:initializer][:value]).to eq("10")
    end

    it 'parses typed variable declarations' do
      input = "var x: number = 10"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:body][0][:var_type_annotation]).to eq("number")
    end

    it 'parses def functions' do
      input = "def Add(x: number, y: number): number\n  return x + y\nenddef"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:body][0][:type]).to eq(:def_function)
      expect(result[:ast][:body][0][:name]).to eq("Add")
      expect(result[:ast][:body][0][:params].size).to eq(2)
      expect(result[:ast][:body][0][:params][0][:name]).to eq("x")
      expect(result[:ast][:body][0][:params][0][:param_type]).to eq("number")
      expect(result[:ast][:body][0][:return_type]).to eq("number")
      expect(result[:ast][:body][0][:body].size).to eq(1)
      expect(result[:ast][:body][0][:body][0][:type]).to eq(:return_statement)
    end

    it 'parses if statements' do
      input = "if x > 10\n  echo 'greater'\nelse\n  echo 'less or equal'\nendif"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:body][0][:type]).to eq(:if_statement)
      expect(result[:ast][:body][0][:then_branch].size).to eq(1)
      expect(result[:ast][:body][0][:else_branch].size).to eq(1)
    end

    it 'parses import statements' do
      input = "import autoload '../autoload/foo.vim'"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:body][0][:type]).to eq(:import_statement)
      expect(result[:ast][:body][0][:module]).to eq("autoload")
      expect(result[:ast][:body][0][:path]).to eq("'../autoload/foo.vim'")
    end

    it 'parses export statements' do
      input = "export def Greet(name: string): string\n  return 'Hello, ' .. name\nenddef"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:body][0][:type]).to eq(:export_statement)
      expect(result[:ast][:body][0][:export][:type]).to eq(:def_function)
      expect(result[:ast][:body][0][:export][:name]).to eq("Greet")
    end

    it 'detects syntax errors' do
      input = "def MissingEnddef()"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:errors].size).to be > 0
    end

    it 'parses echo statements correctly' do
      input = "echo 'hello'"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse
      expect(result[:ast][:body][0][:type]).to eq(:echo_statement)
      expect(result[:ast][:body][0][:expression][:type]).to eq(:literal)
      expect(result[:ast][:body][0][:expression][:token_type]).to eq(:string)
      expect(result[:ast][:body][0][:expression][:value]).to eq("'hello'")
    end

    it 'parses list literals correctly' do
      input = "const myList = [1, 2, 3]"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:body][0][:type]).to eq(:variable_declaration)
      expect(result[:ast][:body][0][:var_type]).to eq("const")
      expect(result[:ast][:body][0][:name]).to eq("myList")
      expect(result[:ast][:body][0][:initializer][:type]).to eq(:list_literal)
      expect(result[:ast][:body][0][:initializer][:elements].size).to eq(3)
      expect(result[:ast][:body][0][:initializer][:elements][0][:value]).to eq("1")
    end

    it 'parses empty list literals correctly' do
      input = "var emptyList = []"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:body][0][:initializer][:type]).to eq(:list_literal)
      expect(result[:ast][:body][0][:initializer][:elements]).to be_empty
    end

    it 'parses simple lambda expressions correctly' do
      input = "var Lambda = (arg) => expression"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:body][0][:type]).to eq(:variable_declaration)
      expect(result[:ast][:body][0][:initializer][:type]).to eq(:lambda_expression)
      expect(result[:ast][:body][0][:initializer][:params].size).to eq(1)
      expect(result[:ast][:body][0][:initializer][:params][0][:name]).to eq("arg")
    end

    it 'parses lambda expressions with multiple parameters correctly' do
      input = "filter(list, (k, v) => v > 0)"
      lexer = Vinter::Lexer.new(input)
      tokens = lexer.tokenize
      parser = described_class.new(tokens)
      result = parser.parse

      expect(result[:ast][:body][0][:type]).to eq(:expression_statement)
      expect(result[:ast][:body][0][:expression][:type]).to eq(:function_call)
      expect(result[:ast][:body][0][:expression][:arguments][1][:type]).to eq(:lambda_expression)
      expect(result[:ast][:body][0][:expression][:arguments][1][:params].size).to eq(2)
      expect(result[:ast][:body][0][:expression][:arguments][1][:params][0][:name]).to eq("k")
      expect(result[:ast][:body][0][:expression][:arguments][1][:params][1][:name]).to eq("v")
    end
  end
end