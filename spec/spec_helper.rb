require "vinter"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random
  Kernel.srand config.seed
end

def print_ast(ast)
  if ast.include?(:name)
    puts "#{ast[:type]} = #{ast[:name]}"
  else
    puts ast[:type]
  end
  if ast.include?(:body)
    ast[:body].each do |e|
      if e.include?(:body)
        print_ast(e)
      else
        puts "|-> #{e[:type]}"
        if e.include?(:target)
          puts "|-> target (#{e[:target][:type]} = #{e[:target][:name]})"
        end

        if e.include?(:operator)
          puts "|-> operator #{e[:operator]}"
        end

        if e.include?(:value)
          puts "|-> value #{e[:value][:type]} #{e[:value][:value]} (#{e[:value][:token_type]})"
        end
        if e.include?(:condition)
          puts "|-> condition #{e[:condition]}"
        end
      end
    end
  end
end

