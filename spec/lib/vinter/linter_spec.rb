require 'spec_helper'

RSpec.describe Vinter::Linter do
  let(:linter) { described_class.new }

  describe '#lint' do
    context 'missing vim9script declaration rule' do
      it 'detects missing vim9script declaration in Vim9 code' do
        input = "var x = 10"
        issues = linter.lint(input)

        expect(issues.size).to eq(2) # missing vim9script + missing type annotation
        expect(issues[0][:type]).to eq(:rule)
        expect(issues[0][:rule]).to eq("missing-vim9script-declaration")
      end
    end

    context 'prefer-def-over-function rule' do
      it 'detects use of legacy function syntax in Vim9 scripts' do
        input = "vim9script\nfunction! OldFunc()\nendfunction"
        issues = linter.lint(input)

        expect(issues.any? { |i| i[:rule] == "prefer-def-over-function" }).to be true
      end
    end

    context 'missing-type-annotation rule' do
      it 'detects missing type annotations for variable declarations' do
        input = "vim9script\nvar count = 0"
        issues = linter.lint(input)

        expect(issues.any? { |i| i[:rule] == "missing-type-annotation" }).to be true
      end
    end

    context 'missing-return-type rule' do
      it 'detects missing return type annotations for functions' do
        input = "vim9script\ndef Greet(name: string)\n  return 'Hello, ' .. name\nenddef"
        issues = linter.lint(input)

        expect(issues.any? { |i| i[:rule] == "missing-return-type" }).to be true
      end
    end

    context 'well-formed code' do
      it 'reports no issues for properly typed Vim9 code' do
        input = "vim9script\n\nvar count: number = 0\n\ndef Add(x: number, y: number): number\n  return x + y\nenddef"
        issues = linter.lint(input)

        expect(issues.size).to eq(0)
      end
    end

    context 'multiple issues' do
      it 'detects multiple rule violations in a single file' do
        input = "# Missing vim9script\nvar x = 10\nfunction! OldFunc()\nendfunction\ndef NoReturn()\nenddef"
        issues = linter.lint(input)

        expect(issues.size).to be >= 3
      end
    end
  end

  describe 'custom rules' do
    it 'allows registration and execution of custom rules' do
      custom_rule = Vinter::Rule.new("custom-rule", "A custom rule") do |ast|
        [{ message: "Custom issue", line: 1, column: 1 }]
      end

      linter.register_rule(custom_rule)
      input = "vim9script"
      issues = linter.lint(input)

      expect(issues.any? { |i| i[:rule] == "custom-rule" }).to be true
    end
  end
end
