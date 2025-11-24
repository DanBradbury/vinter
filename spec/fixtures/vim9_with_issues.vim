vim9script

# Vim9 script with type annotation issues

var count = 0  # Missing type annotation

def Greet(name: string)  # Missing return type
  return 'Hello, ' .. name
enddef

def Add(x, y): number  # Missing parameter types
  return x + y
enddef
