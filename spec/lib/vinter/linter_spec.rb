require 'spec_helper'

RSpec.describe Vinter::Linter do
  describe '#lint' do
    it 'detects missing vim9script declaration' do
      input = "var x = 10"
      linter = described_class.new
      issues = linter.lint(input)

      expect(issues.size).to eq(2) # missing vim9script + missing type annotation
      expect(issues[0][:type]).to eq(:rule)
      expect(issues[0][:rule]).to eq("missing-vim9script-declaration")
    end

    it 'detects use of legacy function syntax' do
      input = "vim9script\nfunction! OldFunc()\nendfunction"
      linter = described_class.new
      issues = linter.lint(input)

      expect(issues.any? { |i| i[:rule] == "prefer-def-over-function" }).to be true
    end

    it 'detects missing type annotations for variables' do
      input = "vim9script\nvar count = 0"
      linter = described_class.new
      issues = linter.lint(input)

      expect(issues.any? { |i| i[:rule] == "missing-type-annotation" }).to be true
    end

    it 'detects missing return type annotations for functions' do
      input = "vim9script\ndef Greet(name: string)\n  return 'Hello, ' .. name\nenddef"
      linter = described_class.new
      issues = linter.lint(input)

      expect(issues.any? { |i| i[:rule] == "missing-return-type" }).to be true
    end

    it 'reports no issues for well-formed code' do
      input = "vim9script\n\nvar count: number = 0\n\ndef Add(x: number, y: number): number\n  return x + y\nenddef"
      linter = described_class.new
      issues = linter.lint(input)

      expect(issues.size).to eq(0)
    end

    it 'handles multiple issues in a single file' do
      input = "# Missing vim9script\nvar x = 10\nfunction! OldFunc()\nendfunction\ndef NoReturn()\nenddef"
      linter = described_class.new
      issues = linter.lint(input)

      expect(issues.size).to be >= 3
    end
  end

  describe 'rule registration' do
    it 'allows custom rules to be registered' do
      custom_rule = Vinter::Rule.new("custom-rule", "A custom rule") do |ast|
        [{ message: "Custom issue", line: 1, column: 1 }]
      end

      linter = described_class.new
      linter.register_rule(custom_rule)

      input = "vim9script"
      issues = linter.lint(input)

      expect(issues.any? { |i| i[:rule] == "custom-rule" }).to be true
    end
  end
end
