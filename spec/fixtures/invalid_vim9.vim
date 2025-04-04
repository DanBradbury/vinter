# Missing vim9script declaration

var count = 0  # Missing type annotation

function! LegacyFunction()  # Should use def instead
  echo 'Using legacy function'
endfunction

def MissingReturnType()  # No return type annotation
  return 42
enddef
