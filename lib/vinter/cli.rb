module Vinter
  class CLI
    def initialize
      @linter = Linter.new
    end

    def run(args)
      if args.empty?
        puts "Usage: vinter [file.vim|directory] [--exclude=dir1,dir2] [--stdio]"
        return 1
      end

      # Parse args: first non-option argument is the target path.
      exclude_value = nil
      target_path = nil
      stdio = false
      format_value = nil

      args.each_with_index do |a, i|
        if a.start_with?("--exclude=")
          exclude_value = a.split("=", 2)[1]
        elsif a == "--exclude"
          exclude_value = args[i + 1]
        elsif a == "--stdio" || a.start_with?("--stdio=")
          stdio = true
        elsif a.start_with?("--format=")
          format_value = a.split("=", 2)[1]
        elsif a == "--format"
          format_value = args[i + 1]
        elsif !a.start_with?('-') && target_path.nil?
          target_path = a
        end
      end

      if target_path.nil? && !stdio
        puts "Usage: vinter [file.vim|directory] [--exclude=dir1,dir2] [--stdio]"
        return 1
      end

      unless stdio
        unless File.exist?(target_path)
          puts "Error: File or directory not found: #{target_path}"
          return 1
        end
      end

      excludes = Array(exclude_value).flat_map { |v| v.to_s.split(',') }.map(&:strip).reject(&:empty?)

      # normalize format value
      format_value = format_value.to_s.downcase if format_value

      # Handle STDIN input mode
      if stdio
        content = STDIN.read

        if content.nil? || content.empty?
          puts "No input received on stdin"
          return 0
        end

        issues = @linter.lint(content)
        total_issues = issues.length

        if format_value == 'json'
          require 'json'

          files = [
            {
              path: 'stdin',
              offenses: issues.map do |issue|
                {
                  severity: (issue[:type] == :error ? 'fatal' : (issue[:type] == :warning ? 'warning' : 'convention')),
                  message: issue[:message],
                  cop_name: issue[:rule],
                  corrected: false,
                  correctable: false,
                  location: {
                    start_line: issue[:line] || 1,
                    start_column: issue[:column] || 1,
                    last_line: issue[:line] || 1,
                    last_column: issue[:column] || 1,
                    length: 0,
                    line: issue[:line] || 1,
                    column: issue[:column] || 1
                  }
                }
              end
            }
          ]

          metadata = {
            'rubocop_version' => defined?(Vinter::VERSION) ? Vinter::VERSION : nil,
            'ruby_engine' => defined?(RUBY_ENGINE) ? RUBY_ENGINE : RUBY_PLATFORM,
            'ruby_version' => RUBY_VERSION,
            'ruby_patchlevel' => RUBY_PATCHLEVEL.to_s,
            'ruby_platform' => RUBY_PLATFORM
          }

          summary = {
            'offense_count' => total_issues,
            'target_file_count' => files.length,
            'inspected_file_count' => files.length
          }

          output = { metadata: metadata, files: files, summary: summary }
          options = {
            indent: '',
            space: '',
            space_before: '',
            object_nl: '',
            array_nl: ''
          }
          puts JSON.pretty_generate(output, options)

          return total_issues > 0 ? 1 : 0
        end
      end

      vim_files = if File.directory?(target_path)
                    find_vim_files(target_path, excludes)
                  else
                    # Check if single file is inside an excluded directory
                    if excluded_file?(target_path, excludes, File.dirname(target_path))
                      []
                    else
                      [target_path]
                    end
                  end

      if vim_files.empty?
        puts "No .vim files found in #{target_path}"
        return 0
      end

      total_issues = 0
      error_count = 0
      json_files = []

      vim_files.each do |file_path|
        content = File.read(file_path)
        issues = @linter.lint(content)
        total_issues += issues.length

        if format_value == 'json'
          json_files << {
            path: file_path,
            offenses: issues.map do |issue|
              {
                severity: (issue[:type] == :error ? 'fatal' : (issue[:type] == :warning ? 'warning' : 'convention')),
                message: issue[:message],
                cop_name: issue[:rule],
                corrected: false,
                correctable: false,
                location: {
                  start_line: issue[:line] || 1,
                  start_column: issue[:column] || 1,
                  last_line: issue[:line] || 1,
                  last_column: issue[:column] || 1,
                  length: 0,
                  line: issue[:line] || 1,
                  column: issue[:column] || 1
                }
              }
            end
          }
        else
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
      end

      #if vim_files.length > 1
        #puts "\nProcessed #{vim_files.length} files, found #{total_issues} total issues"
      #end

      if format_value == 'json'
        require 'json'

        metadata = {
          'rubocop_version' => defined?(Vinter::VERSION) ? Vinter::VERSION : nil,
          'ruby_engine' => defined?(RUBY_ENGINE) ? RUBY_ENGINE : RUBY_PLATFORM,
          'ruby_version' => RUBY_VERSION,
          'ruby_patchlevel' => RUBY_PATCHLEVEL.to_s,
          'ruby_platform' => RUBY_PLATFORM
        }

        summary = {
          'offense_count' => total_issues,
          'target_file_count' => vim_files.length,
          'inspected_file_count' => vim_files.length
        }

        output = { metadata: metadata, files: json_files, summary: summary }
        options = {
          indent: '',
          space: '',
          space_before: '',
          object_nl: '',
          array_nl: ''
        }
        puts JSON.pretty_generate(output, options)

        return total_issues > 0 ? 1 : 0
      end

      return total_issues > 0 ? 1 : 0
    end

    private

    def find_vim_files(directory, excludes = [])
      files = Dir.glob(File.join(directory, "**", "*.vim")).sort

      return files if excludes.empty?

      # Normalize exclude directories to absolute paths (relative to the target directory)
      normalized = excludes.map { |e| File.expand_path(e, directory) }

      files.reject do |f|
        normalized.any? do |ex|
          ex_with_slash = ex.end_with?(File::SEPARATOR) ? ex : ex + File::SEPARATOR
          f.start_with?(ex_with_slash) || File.expand_path(f).start_with?(ex_with_slash)
        end
      end
    end

    def excluded_file?(file_path, excludes, base_dir)
      return false if excludes.empty?

      normalized = excludes.map { |e| File.expand_path(e, base_dir) }
      file_abs = File.expand_path(file_path)

      normalized.any? do |ex|
        ex_with_slash = ex.end_with?(File::SEPARATOR) ? ex : ex + File::SEPARATOR
        file_abs.start_with?(ex_with_slash)
      end
    end
  end
end
