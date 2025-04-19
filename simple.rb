require 'rubygems'
require 'treetop'
Treetop.load 'viml'

parser = VimlParser.new
puts parser.parse("hello daniel")