module Vinter
  class CLI
    def initialize
      @linter = Linter.new
    end

    def run(args)
      if args.empty?
        puts "Usage: vinter [file.vim|directory]"
        return 1
      end

      target_path = args[0]

      unless File.exist?(target_path)
        puts "Error: File or directory not found: #{target_path}"
        return 1
      end

      vim_files = if File.directory?(target_path)
                    find_vim_files(target_path)
                  else
                    [target_path]
                  end

      if vim_files.empty?
        puts "No .vim files found in #{target_path}"
        return 0
      end

      total_issues = 0
      error_count = 0

      vim_files.each do |file_path|
        content = File.read(file_path)
        issues = @linter.lint(content)
        total_issues += issues.length

        if issues.empty?
          puts "No issues found in #{file_path}" if vim_files.length == 1
        else
          puts "Found #{issues.length} issues in #{file_path}:" if vim_files.length > 1

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

          error_count += 1 if issues.any? { |i| i[:type] == :error }
        end
      end

      if vim_files.length > 1
        puts "\nProcessed #{vim_files.length} files, found #{total_issues} total issues"
      end

      return error_count > 0 ? 1 : 0
    end

    private

    def find_vim_files(directory)
      Dir.glob(File.join(directory, "**", "*.vim")).sort
    end
  end
end
