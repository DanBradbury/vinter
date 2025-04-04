vim9script

# A valid Vim9 script file for testing

var count: number = 0
const PI: float = 3.14159
final MSG: string = 'Hello, Vim9!'

def Add(x: number, y: number): number
  return x + y
enddef

export def Multiply(x: number, y: number): number
  return x * y
enddef

def ProcessItems(required: string, ?optional: number = 10, ...rest: list<string>): dict<any>
  var result = {
    'required': required,
    'optional': optional,
    'rest': rest
  }
  return result
enddef

# Main execution
count = Add(5, 10)
echo count
echo Multiply(count, 2)

