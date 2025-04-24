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
