require 'httparty'
require 'fileutils'
require 'open3'
require 'time'

# URL of the README.md file
readme_url = 'https://raw.githubusercontent.com/saccarosium/awesome-vim9/main/README.md'

# Fetch the content of the README.md file using HTTParty
response = HTTParty.get(readme_url)

if response.code == 200
  readme_content = response.body

  # Regular expression to match GitHub repository URLs
  github_repo_regex = %r{https://github\.com/[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+}

  # Extract all GitHub repository URLs
  github_repos = readme_content.scan(github_repo_regex).uniq

  # Temporary directory for cloning repositories
  temp_dir = "tmp/"

  # Data collection for the report
  report_data = []

  github_repos.each do |repo_url|
    puts repo_url
    begin
      # Extract the repo name from the URL
      repo_name = repo_url.split('/').last

      # Clone the repository into the temp directory
      repo_path = File.join(temp_dir, repo_name)
      puts "Cloning #{repo_url} into #{repo_path}..."
      system("git clone #{repo_url} #{repo_path}")

      # Run `vinter .` in the cloned repository
      puts "Running `vinter .` in #{repo_path}..."
      stdout, stderr, status = Open3.capture3("cd #{repo_path} && vinter .")

      # Count the number of ERROR and WARNING messages
      error_count = stdout.scan(/ERROR/).size
      warning_count = stdout.scan(/WARNING/).size

      # Add the results to the report data
      report_data << { repo: repo_url, errors: error_count, warnings: warning_count }
    rescue => e
      puts "An error occurred while processing #{repo_url}: #{e.message}"
      report_data << { repo: repo_url, errors: 'N/A', warnings: 'N/A' }
    ensure
      # Clean up the cloned repository
      FileUtils.rm_rf(repo_path) if Dir.exist?(repo_path)
    end
  end

  # Clean up the temporary directory
  FileUtils.remove_entry(temp_dir)

  # Calculate summary statistics
  total_errors = report_data.sum { |data| data[:errors].is_a?(Integer) ? data[:errors] : 0 }
  total_warnings = report_data.sum { |data| data[:warnings].is_a?(Integer) ? data[:warnings] : 0 }
  repos_with_no_issues = report_data.count { |data| data[:errors] == 0 && data[:warnings] == 0 }

  # Read existing report if it exists
  cumulative_report = ""
  if File.exist?('vinter_report.md')
    cumulative_report = File.read('vinter_report.md')
  end

  # Extract existing cumulative list
  cumulative_list = cumulative_report[/## Cumulative Report\n\n((?:- .*\n?)+)/, 1] || ""

  # Add new entry to the cumulative list
  timestamp = Time.now.utc.iso8601
  new_entry = "- **#{timestamp}**: Total Errors: #{total_errors}, Total Warnings: #{total_warnings}, Repos with No Issues: #{repos_with_no_issues}\n\n"
  cumulative_list += new_entry

  # Generate the Markdown report
  markdown_report = <<~MARKDOWN
    # Vinter Analysis Report

    ## Summary
    Total Errors: #{total_errors}
    Total Warnings: #{total_warnings}
    Repos with No Issues: #{repos_with_no_issues}

    ## Cumulative Report

    #{cumulative_list}

    ## Detailed Report

    | Repository URL | Errors | Warnings |
    |----------------|--------|----------|
  MARKDOWN

  report_data.each do |data|
    markdown_report += "| #{data[:repo]} | #{data[:errors]} | #{data[:warnings]} |\n"
  end

  # Save the report to a file
  File.write('vinter_report.md', markdown_report)
  puts "Report generated: vinter_report.md"
else
  puts "Failed to fetch the README.md file. HTTP Status Code: #{response.code}"
end
