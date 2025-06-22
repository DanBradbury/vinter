require 'spec_helper'

RSpec.describe 'Integration Tests' do
  let(:linter) { Vinter::Linter.new }

  it 'correctly lints a valid vim9 script file' do
    file_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'valid_vim9.vim')
    content = File.read(file_path)
    issues = linter.lint(content).select { |f| [:error, :warning].include?(f[:type]) }

    expect(issues.size).to eq(0), issues.inspect
  end

  it 'correctly lints a legacy vim script file' do
    file_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'legacy.vim')
    content = File.read(file_path)

    # For now, just verify that the linter doesn't crash on legacy scripts
    # In the future, this should be updated to properly validate legacy syntax
    # issues = linter.lint(content)
    issues = linter.lint(content).select { |f| [:error, :warning].include?(f[:type]) }
    # pp issues
    # Temporarily disabled until we fully support all legacy Vim script syntax
    expect(issues.size).to eq(0), issues.inspect
  end

  it 'copilot_chat parsing' do
    file_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'copilot_chat.vim')
    content = File.read(file_path)
    issues = linter.lint(content).select { |f| [:error, :warning].include?(f[:type]) }
    #pp issues
    expect(issues.size).to eq(0), issues.inspect
  end

  it 'parses vimscript feature file without warnings' do
    file_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'features.vim')
    content = File.read(file_path)
    issues = linter.lint(content).select { |f| [:error, :warning].include?(f[:type]) }
    # pp issues
    expect(issues.size).to eq(0)
  end

  it 'parses vimscript feature file' do
    file_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'features.vim')
    content = File.read(file_path)
    issues = linter.lint(content).select { |f| [:error, :warning].include?(f[:type]) }
    # pp issues
    expect(issues.size).to eq(0), issues.inspect
  end

  it 'correctly identifies issues in an invalid vim9 script file' do
    file_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'invalid_vim9.vim')
    content = File.read(file_path)
    issues = linter.lint(content)

    expect(issues.size).to be >= 4  # At least 4 issues should be found

    # Check specific issues
    expect(issues.any? { |i| i[:rule] == "missing-vim9script-declaration" }).to be true
    expect(issues.any? { |i| i[:rule] == "missing-type-annotation" }).to be true
    expect(issues.any? { |i| i[:rule] == "prefer-def-over-function" }).to be true
    expect(issues.any? { |i| i[:rule] == "missing-return-type" }).to be true
  end

  it 'handles backslash line continuations without warnings' do
    file_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'isolated.vim')
    content = File.read(file_path)

    issues = linter.lint(content).select { |f| [:error, :warning].include?(f[:type]) }
    pp issues
    expect(issues.size).to eq(0), "Expected no issues, but found: #{issues.inspect}"
  end
end
