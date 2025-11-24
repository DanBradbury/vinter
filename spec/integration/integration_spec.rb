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
      it 'rejects files without vim9script declaration' do
        file_path = File.join(fixtures_path, 'invalid_vim9.vim')
        content = File.read(file_path)
        issues = linter.lint(content)

        # Should immediately reject due to missing vim9script
        expect(issues.size).to eq(1)
        expect(issues[0][:type]).to eq(:error)
        expect(issues[0][:message]).to include("vim9script")
      end
    end

    context 'vim9 script with type issues' do
      it 'identifies type annotation violations in Vim9 script' do
        file_path = File.join(fixtures_path, 'vim9_with_issues.vim')
        content = File.read(file_path)
        issues = linter.lint(content)

        # Check for type annotation issues
        expect(issues.any? { |i| i[:rule] == "missing-type-annotation" }).to be true
        expect(issues.any? { |i| i[:rule] == "missing-return-type" }).to be true
      end
    end
  end

  describe 'legacy VimScript rejection' do
    context 'legacy script files' do
      it 'rejects legacy vim script files without vim9script' do
        file_path = File.join(fixtures_path, 'legacy.vim')
        content = File.read(file_path)

        issues = linter.lint(content)
        
        # Should reject because it doesn't start with vim9script
        expect(issues.size).to eq(1)
        expect(issues[0][:type]).to eq(:error)
        expect(issues[0][:message]).to include("vim9script")
      end
    end

    context 'legacy function syntax' do
      it 'detects legacy function syntax in vim9script files' do
        file_path = File.join(fixtures_path, 'vim9_with_legacy_function.vim')
        content = File.read(file_path)

        issues = linter.lint(content)
        
        expect(issues.any? { |i| i[:rule] == "no-legacy-function" }).to be true
      end
    end
  end

  describe 'complex vim9script files' do
    context 'vim9 features script' do
      it 'parses vim9 features file without errors' do
        file_path = File.join(fixtures_path, 'vim9_features.vim')
        content = File.read(file_path)
        issues = linter.lint(content).select { |f| [:error, :warning].include?(f[:type]) }
        
        expect(issues.size).to eq(0), "Expected no issues but found: #{issues.inspect}"
      end
    end
  end
end
