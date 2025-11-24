vim9script

# Example with control flow and loops

var counter: number = 0
const MAX_ITERATIONS: number = 10

def IncrementCounter(): void
  counter += 1
enddef

def GetCounter(): number
  return counter
enddef

def CountToMax(): void
  while counter < MAX_ITERATIONS
    IncrementCounter()
  endwhile
enddef

def Sum(start: number, end: number): number
  var total: number = 0
  var i: number = start
  while i <= end
    total += i
    i += 1
  endwhile
  return total
enddef
