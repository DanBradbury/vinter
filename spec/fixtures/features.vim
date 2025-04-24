" =============================================================================
" Comprehensive Vim Script Features Demo
" =============================================================================
" This script demonstrates the major features of Vim script language
" and its built-in functions. Use it as a reference for Vim scripting.
" Version: 1.0
" Last Change: 2025-04-23
" =============================================================================

" -----------------------------------------------------------------------------
" 1. Comments
" -----------------------------------------------------------------------------
" This is a single line comment

" Multi-line comments can be done with
" multiple single-line comments

" -----------------------------------------------------------------------------
" 2. Variables and Data Types
" -----------------------------------------------------------------------------
" 2.1 Variable Scopes
let g:global_var = "Available everywhere"          " Global
let s:script_var = "Only in this script"           " Script-local
let b:buffer_var = "Only in current buffer"        " Buffer-local
let w:window_var = "Only in current window"        " Window-local
let t:tab_var = "Only in current tab"              " Tab-local
let l:local_var = "Only in current function/block" " Local to function
let a:arg = "Defined in function arguments"        " Function argument (only in functions)
let v:count = v:count                              " Vim special variable

" 2.2 Data Types
" Numbers
let num_dec = 42       " Decimal
let num_hex = 0xFF     " Hexadecimal (255)
let num_oct = 0o77     " Octal (63)
let num_bin = 0b1010   " Binary (10)
let num_float = 3.14   " Float

" Strings
let str1 = "Double quoted string"
let str2 = 'Single quoted string'
let str3 = "String with \"escaped quotes\""
let str4 = "String with \nnewline"
let str5 = "String with " . "concatenation"        " String concatenation with .
let str6 = printf("Formatted %s with %d", "string", 42)  " Formatted string

" Special strings
let str_literal = "Line one
      \Line two
      \Line three"     " Multi-line string with line continuation
let heredoc = [
      \ 'Line one',
      \ 'Line two',
      \ 'Line three'
      \ ]               " List of strings (another way for multi-line)
