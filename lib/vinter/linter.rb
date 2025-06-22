require "yaml"

module Vinter
  class Linter
    def initialize(config_path: nil)
      @rules = []
      @ignored_rules = []
      @config_path = config_path || find_config_path
      load_config
      register_default_rules
    end

    def register_rule(rule)
      @rules << rule
    end

    def register_default_rules
      # Rule: Vim9 script files should start with vim9script declaration
      register_rule(Rule.new("missing-vim9script-declaration", "Script does not start with vim9script declaration") do |ast|
        if ast[:type] == :program && (ast[:body].empty? || ast[:body][0][:type] != :vim9script_declaration)
          [{ message: "File should start with vim9script declaration", line: 1, column: 1 }]
        else
          []
        end
      end)

      # Rule: Prefer def over function in Vim9 script
      register_rule(Rule.new("prefer-def-over-function", "Use def instead of function in Vim9 script") do |ast|
        issues = []

        traverse_ast(ast) do |node|
          if node[:type] == :legacy_function
            issues << { message: "Use def instead of function for #{node[:name]}", line: node[:line] || 0, column: node[:column] || 0 }
          end
        end

        issues
      end)

      # Rule: Variables should have type annotations
      register_rule(Rule.new("missing-type-annotation", "Variable declaration is missing type annotation") do |ast|
        issues = []

        traverse_ast(ast) do |node|
          if node[:type] == :variable_declaration && node[:var_type_annotation].nil? && node[:var_type] != 'const'
            issues << { message: "Variable #{node[:name]} should have a type annotation", line: node[:line] || 0, column: node[:column] || 0 }
          end
        end

        issues
      end)

      # Rule: Functions should have return type annotations
      register_rule(Rule.new("missing-return-type", "Function is missing return type annotation") do |ast|
        issues = []

        traverse_ast(ast) do |node|
          if node[:type] == :def_function && node[:return_type].nil?
            issues << { message: "Function #{node[:name]} should have a return type annotation", line: node[:line] || 0, column: node[:column] || 0 }
          end
        end

        issues
      end)

      # Rule: Function parameters should have type annotations
      register_rule(Rule.new("missing-param-type", "Function parameter is missing type annotation") do |ast|
        issues = []

        traverse_ast(ast) do |node|
          if node[:type] == :def_function
            node[:params].each do |param|
              if param[:type] == :parameter && param[:param_type].nil?
                issues << { message: "Parameter #{param[:name]} should have a type annotation", line: param[:line] || 0, column: param[:column] || 0 }
              end
            end
          end
        end

        issues
      end)
    end

    def traverse_ast(node, &block)
      return unless node.is_a?(Hash)

      yield node

      node.each do |key, value|
        if value.is_a?(Array)
          value.each { |item| traverse_ast(item, &block) if item.is_a?(Hash) }
        elsif value.is_a?(Hash)
          traverse_ast(value, &block)
        end
      end
    end

    def lint(content)
      lexer = Lexer.new(content)
      tokens = lexer.tokenize

      parser = Parser.new(tokens, content)
      result = parser.parse

      issues = []

      # Add parser errors
      result[:errors].each do |error|
        issues << {
          type: :error,
          message: error[:message],
          position: error[:position],
          line: error[:line] || 0,
          column: error[:column] || 0
        }
      end

      # Add parser warnings
      result[:warnings].each do |warning|
        issues << {
          type: :warning,
          message: warning[:message],
          position: warning[:position],
          line: warning[:line] || 0,
          column: warning[:column] || 0
        }
      end

      # Apply rules, ignoring those specified in config
      @rules.each do |rule|
        next if @ignored_rules.include?(rule.id)
        rule_issues = rule.apply(result[:ast])
        issues.concat(rule_issues.map { |i| {
          type: :rule,
          rule: rule.id,
          message: i[:message],
          line: i[:line] || 0,
          column: i[:column] || 0
        }})
      end

      issues
    end

    private

    def find_config_path
      # check for project level config
      project_config = Dir.glob(".vinter{.yaml,.yml,}").first
      project_config if project_config

      # check for user-level config
      user_config = File.expand_path("~/.vinter")
      user_config if File.exist?(user_config)
    end

    def load_config
      return unless @config_path && File.exist?(@config_path)

      config = YAML.load_file(@config_path)
      @ignored_rules = config["ignore_rules"] || []
    end
  end

  class Rule
    attr_reader :id, :description

    def initialize(id, description, &block)
      @id = id
      @description = description
      @check = block
    end

    def apply(ast)
      @check.call(ast)
    end
  end
end
