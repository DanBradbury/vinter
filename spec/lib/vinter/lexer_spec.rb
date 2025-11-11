require 'spec_helper'

RSpec.describe Vinter::Lexer do
  let(:tokenize) do
    lambda do |input|
      lexer = described_class.new(input)
      lexer.tokenize
    end
  end

  describe '#tokenize' do
    context 'keywords' do
      it 'tokenizes VimScript keywords' do
        tokens = tokenize.call("if while def vim9script")

        expect(tokens.size).to eq(4)
        expect(tokens[0][:type]).to eq(:keyword)
        expect(tokens[0][:value]).to eq("if")
        expect(tokens[1][:type]).to eq(:keyword)
        expect(tokens[1][:value]).to eq("while")
        expect(tokens[2][:type]).to eq(:keyword)
        expect(tokens[2][:value]).to eq("def")
        expect(tokens[3][:type]).to eq(:keyword)
        expect(tokens[3][:value]).to eq("vim9script")
      end
    end

    context 'identifiers' do
      it 'tokenizes variable names' do
        tokens = tokenize.call("myVar _test Function#1")

        expect(tokens.size).to eq(3)
        expect(tokens[0][:type]).to eq(:identifier)
        expect(tokens[0][:value]).to eq("myVar")
        expect(tokens[1][:type]).to eq(:identifier)
        expect(tokens[1][:value]).to eq("_test")
        expect(tokens[2][:type]).to eq(:identifier)
        expect(tokens[2][:value]).to eq("Function#1")
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
      it 'tokenizes single and double-quoted strings' do
        tokens = tokenize.call("'single quoted' \"double quoted\"")

        expect(tokens.size).to eq(2)
        expect(tokens[0][:type]).to eq(:string)
        expect(tokens[0][:value]).to eq("'single quoted'")
        expect(tokens[1][:type]).to eq(:string)
        expect(tokens[1][:value]).to eq("\"double quoted\"")
      end
    end

    context 'comments' do
      it 'tokenizes Vim9 script comments' do
        tokens = tokenize.call("var x = 10 # This is a comment")

        expect(tokens.size).to eq(5)  # var, x, =, 10, comment
        expect(tokens[4][:type]).to eq(:comment)
        expect(tokens[4][:value]).to eq("# This is a comment")
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
