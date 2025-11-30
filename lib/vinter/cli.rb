module Vinter
  class CLI
    def initialize
      @linter = Linter.new
    end

    def run(args)
      if args.empty?
        puts "Usage: vinter [file.vim|directory] [--exclude=dir1,dir2]"
        return 1
      end

      # Parse args: first non-option argument is the target path.
      exclude_value = nil
      target_path = nil

      args.each_with_index do |a, i|
        if a.start_with?("--exclude=")
          exclude_value = a.split("=", 2)[1]
        elsif a == "--exclude"
          exclude_value = args[i + 1]
        elsif !a.start_with?('-') && target_path.nil?
          target_path = a
        end
      end

      if target_path.nil?
        puts "Usage: vinter [file.vim|directory] [--exclude=dir1,dir2]"
        return 1
      end

      unless File.exist?(target_path)
        puts "Error: File or directory not found: #{target_path}"
        return 1
      end

      excludes = Array(exclude_value).flat_map { |v| v.to_s.split(',') }.map(&:strip).reject(&:empty?)

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
