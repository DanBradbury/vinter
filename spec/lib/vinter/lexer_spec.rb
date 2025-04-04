require 'spec_helper'

RSpec.describe Vinter::Lexer do
  describe '#tokenize' do
    it 'tokenizes keywords correctly' do
      input = "if while def vim9script"
      lexer = described_class.new(input)
      tokens = lexer.tokenize

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

    it 'tokenizes identifiers correctly' do
      input = "myVar _test Function#1"
      lexer = described_class.new(input)
      tokens = lexer.tokenize

      expect(tokens.size).to eq(3)
      expect(tokens[0][:type]).to eq(:identifier)
      expect(tokens[0][:value]).to eq("myVar")
      expect(tokens[1][:type]).to eq(:identifier)
      expect(tokens[1][:value]).to eq("_test")
      expect(tokens[2][:type]).to eq(:identifier)
      expect(tokens[2][:value]).to eq("Function#1")
    end

    it 'tokenizes operators correctly' do
      input = "+ - * / == != => ->"
      lexer = described_class.new(input)
      tokens = lexer.tokenize

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

    it 'tokenizes strings correctly' do
      input = "'single quoted' \"double quoted\""
      lexer = described_class.new(input)
      tokens = lexer.tokenize

      expect(tokens.size).to eq(2)
      expect(tokens[0][:type]).to eq(:string)
      expect(tokens[0][:value]).to eq("'single quoted'")
      expect(tokens[1][:type]).to eq(:string)
      expect(tokens[1][:value]).to eq("\"double quoted\"")
    end

    it 'tokenizes comments correctly' do
      input = "var x = 10 # This is a comment"
      lexer = described_class.new(input)
      tokens = lexer.tokenize

      expect(tokens.size).to eq(5)  # var, x, =, 10, comment
      expect(tokens[4][:type]).to eq(:comment)
      expect(tokens[4][:value]).to eq("# This is a comment")
    end

    it 'tokenizes a complete vim9 function' do
      input = "def Add(x: number, y: number): number\n  return x + y\nenddef"
      lexer = described_class.new(input)
      tokens = lexer.tokenize

      expect(tokens.size).to eq(17)
      expect(tokens[0][:type]).to eq(:keyword)
      expect(tokens[0][:value]).to eq("def")
      expect(tokens[1][:type]).to eq(:identifier)
      expect(tokens[1][:value]).to eq("Add")
      # Continue checking the rest of the tokens...
    end

    it 'handles ellipsis for variadic parameters' do
      input = "def Func(...args: list<string>)"
      lexer = described_class.new(input)
      tokens = lexer.tokenize

      expect(tokens.size).to eq(8)
      expect(tokens[3][:type]).to eq(:ellipsis)
      expect(tokens[3][:value]).to eq("...")
    end
  end
end
