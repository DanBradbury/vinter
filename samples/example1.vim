vim9script

# Simple vim9script example with proper type annotations

var count: number = 0
const MAX_COUNT: number = 100

def Increment(): void
  count += 1
enddef

def GetCount(): number
  return count
enddef

def Add(x: number, y: number): number
  return x + y
enddef

def Greet(name: string): string
  return 'Hello, ' .. name .. '!'
enddef
