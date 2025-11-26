module Vinter
  module ASTPrinter
    def self.print(ast, indent=0)
      spaces = " " * indent * 2
      ast[:body].each do |node|
        puts "#{spaces}(#{node[:type]}|#{node[:value]})"
        if node[:type] == :export_statement
          puts "(#{node[:export][:type]})"
          print(node[:export], indent=1)
        end
      end
    end
  end
end
