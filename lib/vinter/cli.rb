module Vinter
  class CLI
    def initialize
      @linter = Linter.new
    end

    def run(args)
      if args.empty?
        puts "Usage: vim9-lint [file.vim]"
        return 1
      end

      file_path = args[0]

      unless File.exist?(file_path)
        puts "Error: File not found: #{file_path}"
        return 1
      end

      content = File.read(file_path)
      issues = @linter.lint(content)

      if issues.empty?
        puts "No issues found in #{file_path}"
        return 0
      else
        puts "Found #{issues.length} issues in #{file_path}:"

        issues.each do |issue|
          type_str = case issue[:type]
                     when :error then "ERROR"
                     when :warning then "WARNING"
                     when :rule then "RULE(#{issue[:rule]})"
                     else "UNKNOWN"
                     end

          line = issue[:line] || 1
          column = issue[:column] || 1

          puts "#{file_path}:#{line}:#{column}: #{type_str}: #{issue[:message]}"
        end

        return issues.any? { |i| i[:type] == :error } ? 1 : 0
      end
    end
  end
end
