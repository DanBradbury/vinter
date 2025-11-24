vim9script

# A valid Vim9 script file for testing with proper type annotations

var count: number = 0
const MAX_VALUE: number = 100

def Add(x: number, y: number): number
  return x + y
enddef

def Greet(name: string): string
  return 'Hello, ' .. name
enddef

def ProcessItems(value: number): void
  echo value
enddef

