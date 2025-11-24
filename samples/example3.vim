vim9script

# Example with conditional logic and string operations

var isEnabled: bool = true
var errorMessage: string = ''

def CheckStatus(): bool
  return isEnabled
enddef

def SetError(message: string): void
  errorMessage = message
  isEnabled = false
enddef

def ClearError(): void
  errorMessage = ''
  isEnabled = true
enddef

def FormatMessage(prefix: string, message: string): string
  return prefix .. ': ' .. message
enddef

def ValidateInput(input: string): bool
  if len(input) == 0
    SetError('Input cannot be empty')
    return false
  endif
  
  if len(input) > 100
    SetError('Input too long')
    return false
  endif
  
  ClearError()
  return true
enddef
