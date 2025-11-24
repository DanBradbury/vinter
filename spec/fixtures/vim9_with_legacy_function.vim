vim9script

# Vim9 script with legacy function syntax (should be flagged)

function! LegacyFunc()
  echo "This is legacy syntax"
endfunction

def ProperFunc(): void
  echo "This is proper vim9script syntax"
enddef
