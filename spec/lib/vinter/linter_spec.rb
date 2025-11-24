require 'spec_helper'

RSpec.describe Vinter::Linter do
  let(:linter) { described_class.new }

  describe '#lint' do
    context 'vim9script declaration requirement' do
      it 'rejects files without vim9script declaration' do
        input = "var x = 10"
        issues = linter.lint(input)

        expect(issues.size).to eq(1)
        expect(issues[0][:type]).to eq(:error)
        expect(issues[0][:message]).to include("vim9script")
      end

      it 'rejects files with code before vim9script' do
        input = "let x = 10\nvim9script"
        issues = linter.lint(input)

        expect(issues.size).to eq(1)
        expect(issues[0][:type]).to eq(:error)
        expect(issues[0][:message]).to include("vim9script")
      end

      it 'allows empty lines and comments before vim9script' do
        input = "\n# Comment\nvim9script\nvar x: number = 10"
        issues = linter.lint(input)

        # Should not have vim9script error
        expect(issues.none? { |i| i[:message].include?("vim9script") && i[:type] == :error }).to be true
      end
    end

    context 'no-legacy-function rule' do
      it 'detects use of legacy function syntax in Vim9 scripts' do
        input = "vim9script\nfunction! OldFunc()\nendfunction"
        issues = linter.lint(input)

        expect(issues.any? { |i| i[:rule] == "no-legacy-function" }).to be true
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

    context 'missing-param-type rule' do
      it 'detects missing parameter type annotations' do
        input = "vim9script\ndef Greet(name): string\n  return 'Hello, ' .. name\nenddef"
        issues = linter.lint(input)

        expect(issues.any? { |i| i[:rule] == "missing-param-type" }).to be true
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
      it 'stops at missing vim9script declaration' do
        input = "# Missing vim9script\nvar x = 10\nfunction! OldFunc()\nendfunction"
        issues = linter.lint(input)

        # Should only report the missing vim9script error and stop
        expect(issues.size).to eq(1)
        expect(issues[0][:type]).to eq(:error)
        expect(issues[0][:message]).to include("vim9script")
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
