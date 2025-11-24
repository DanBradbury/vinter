vim9script

# Comprehensive vim9script features with proper typing

var globalCount: number = 0
const PI: number = 3.14159

def BasicFunction(): void
  echo "Basic function"
enddef

def FunctionWithParams(name: string, age: number): string
  return name .. ' is ' .. age .. ' years old'
enddef

def Add(x: number, y: number): number
  return x + y
enddef

def Multiply(num1: number, num2: number): number
  var result: number = num1 * num2
  return result
enddef

def Greet(name: string): string
  const greeting: string = 'Hello, ' .. name
  return greeting
enddef
