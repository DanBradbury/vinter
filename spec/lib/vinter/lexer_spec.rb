require 'spec_helper'

RSpec.describe Vinter::Lexer do
  let(:tokenize) do
    lambda do |input|
      lexer = described_class.new(input)
      lexer.tokenize
    end
  end

  describe '#tokenize' do
    context 'variables' do
      it 'tokenizes variables correctly' do
        basic = """
        var command = '123'
        command ..= '33'
        """
        tokens = tokenize.call(basic)
        token_types = tokens.map { |f| f[:type] }
        expect(token_types).to eq %i[keyword identifier operator string identifier compound_operator string]
      end
    end

    context 'operators' do
      it 'tokenizes arithmetic and comparison operators' do
        tokens = tokenize.call("+ - * / == != => ->")

        expect(tokens.size).to eq(8)
        expect(tokens[0][:type]).to eq(:operator)
        expect(tokens[0][:value]).to eq("+")
        expect(tokens[5][:type]).to eq(:operator)
        expect(tokens[5][:value]).to eq("!=")
        expect(tokens[6][:type]).to eq(:operator)
        expect(tokens[6][:value]).to eq("=>")
        expect(tokens[7][:type]).to eq(:operator)
        expect(tokens[7][:value]).to eq("->")
      end
    end

    context 'string literals' do
      it 'tokenizes double quoted stirngs' do
        tokens = tokenize.call('var thing = "double quoted"')
        token_types = tokens.map { |f| f[:type] }
        expect(token_types).to eq %i[keyword identifier operator string]
      end

      it 'tokenizes single and double-quoted strings' do
        tokens = tokenize.call("var thing = 'single quoted'")

        token_types = tokens.map { |f| f[:type] }
        expect(token_types).to eq %i[keyword identifier operator string]
      end
    end

    context 'comments' do
      it 'tokenizes Vim9 script comments' do
        tokens = tokenize.call("var x = 10 # This is a comment")
        token_types = tokens.map { |f| f[:type] }
        expect(token_types).to eq([:keyword, :identifier, :operator, :number, :comment])
        expect(tokens[4][:type]).to eq(:comment)
        expect(tokens[4][:value]).to eq("# This is a comment")
      end
    end

    context 'commands' do
      it 'tokenizes normal commands' do
        tokens = tokenize.call('normal! gv"xy')
        token_types = tokens.map { |f| f[:type] }
        expect(token_types).to eq([:mode_command])
      end

      it 'handles exec commands' do
        tokens = tokenize.call("exec ':%s/^ ━\+/ ' .. repeat('━', width) .. '/ge'")
        token_types = tokens.map { |f| f[:type] }
        expect(token_types).to eq([:exec_command])
      end
    end

    context 'complete statements' do
      it 'tokenizes a complete Vim9 function definition' do
        tokens = tokenize.call("def Add(x: number, y: number): number\n  return x + y\nenddef")

        expect(tokens.size).to eq(18)
        expect(tokens[0][:type]).to eq(:keyword)
        expect(tokens[0][:value]).to eq("def")
        expect(tokens[1][:type]).to eq(:identifier)
        expect(tokens[1][:value]).to eq("Add")
      end
    end
  end
end
