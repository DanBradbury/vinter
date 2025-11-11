require 'spec_helper'

RSpec.describe 'Vinter Integration Tests' do
  let(:linter) { Vinter::Linter.new }
  let(:fixtures_path) { File.join(File.dirname(__FILE__), '..', 'fixtures') }

  describe 'Vim9 script linting' do
    context 'valid vim9 script' do
      it 'reports no issues for well-formed Vim9 script' do
        file_path = File.join(fixtures_path, 'valid_vim9.vim')
        content = File.read(file_path)
        issues = linter.lint(content).select { |f| [:error, :warning].include?(f[:type]) }

        expect(issues.size).to eq(0), "Expected no issues but found: #{issues.inspect}"
      end
    end

    context 'invalid vim9 script' do
      it 'identifies multiple rule violations in poorly-formed Vim9 script' do
        file_path = File.join(fixtures_path, 'invalid_vim9.vim')
        content = File.read(file_path)
        issues = linter.lint(content)

        expect(issues.size).to be >= 4  # At least 4 issues should be found

        # Check specific issues
        expect(issues.any? { |i| i[:rule] == "missing-vim9script-declaration" }).to be true
        expect(issues.any? { |i| i[:rule] == "missing-type-annotation" }).to be true
        expect(issues.any? { |i| i[:rule] == "prefer-def-over-function" }).to be true
        expect(issues.any? { |i| i[:rule] == "missing-return-type" }).to be true
      end
    end
  end

  describe 'legacy VimScript linting' do
    context 'legacy script compatibility' do
      # TODO: Legacy script linting has known issues - needs parser enhancement
      xit 'handles legacy vim script without errors' do
        file_path = File.join(fixtures_path, 'legacy.vim')
        content = File.read(file_path)

        issues = linter.lint(content).select { |f| [:error, :warning].include?(f[:type]) }
        expect(issues.size).to eq(0), "Expected no issues but found: #{issues.inspect}"
      end
    end

    context 'backslash line continuations' do
      it 'parses files with backslash line continuations without warnings' do
        file_path = File.join(fixtures_path, 'isolated.vim')
        content = File.read(file_path)

        issues = linter.lint(content).select { |f| [:error, :warning].include?(f[:type]) }
        expect(issues.size).to eq(0), "Expected no issues but found: #{issues.inspect}"
      end
    end
  end

  describe 'complex real-world files' do
    context 'copilot chat script' do
      it 'parses copilot chat vim file without errors' do
        file_path = File.join(fixtures_path, 'copilot_chat.vim')
        content = File.read(file_path)
        issues = linter.lint(content).select { |f| [:error, :warning].include?(f[:type]) }
        
        expect(issues.size).to eq(0), "Expected no issues but found: #{issues.inspect}"
      end
    end

    context 'vim features script' do
      it 'parses vim features file without errors' do
        file_path = File.join(fixtures_path, 'features.vim')
        content = File.read(file_path)
        issues = linter.lint(content).select { |f| [:error, :warning].include?(f[:type]) }
        
        expect(issues.size).to eq(0), "Expected no issues but found: #{issues.inspect}"
      end
    end
  end
end
