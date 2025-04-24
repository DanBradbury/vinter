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

" Lists
let list1 = [1, 2, 3, 4, 5]                        " List of numbers
let list2 = ['apple', 'banana', 'cherry']          " List of strings
let list3 = [1, 'mixed', ["nested", "list"], {'key': 'value'}] " Mixed/nested list
let empty_list = []                                " Empty list

" Dictionaries
let dict1 = {'name': 'John', 'age': 30, 'city': 'New York'}  " Dictionary
let dict2 = {}                                               " Empty dictionary
let dict3 = {'nested': {'key': 'value'}, 'list': [1, 2, 3]}  " Nested structures

" Funcref (Function references)
let Funcref = function('strlen')                    " Reference to built-in function

" Boolean-like values (Vim uses 0 for false, non-zero for true)
let is_true = 1
let is_false = 0

" Null-like value
let null_val = v:null         " v:null (Vim 8.0+)

" -----------------------------------------------------------------------------
" 3. Operators
" -----------------------------------------------------------------------------
" 3.1 Arithmetic Operators
let a = 10
let b = 20
let sum = a + b              " Addition
let difference = b - a       " Subtraction
let product = a * b          " Multiplication
let quotient = b / a         " Division
let remainder = 23 % 5       " Modulus
let power = pow(2, 3)        " Exponentiation (8)

" Increment/Decrement
let c = 5
let c += 1                   " c = c + 1
let c -= 1                   " c = c - 1
let d = 10
let d *= 2                   " d = d * 2
let d /= 2                   " d = d / 2

" 3.2 Comparison Operators
let eq = a == b              " Equal to (0)
let neq = a != b             " Not equal to (1)
let gt = b > a               " Greater than (1)
let lt = a < b               " Less than (1)
let gte = a >= a             " Greater than or equal to (1)
let lte = b <= b             " Less than or equal to (1)

" String comparison
let str_eq = "abc" ==# "abc"  " Case-sensitive equal (1)
let str_neq = "abc" !=# "ABC" " Case-sensitive not equal (1)
let str_eq_i = "abc" ==? "ABC" " Case-insensitive equal (1)
let str_match = "abc" =~ "^a" " Pattern match (1)
let str_nomatch = "abc" !~ "^b" " Pattern not match (1)
let str_match_c = "abc" =~# "^a" " Case-sensitive pattern match (1)
let str_match_i = "abc" =~? "^A" " Case-insensitive pattern match (1)

" 3.3 Logical Operators
let log_and = (a > 0) && (b > 0)        " Logical AND (1)
let log_or = (a < 0) || (b > 0)         " Logical OR (1)
let log_not = !(a == b)                 " Logical NOT (1)

" 3.4 Ternary Operator
let max_val = a > b ? a : b             " Ternary operator (20)

" -----------------------------------------------------------------------------
" 4. Control Structures
" -----------------------------------------------------------------------------
" 4.1 Conditionals
" If-elseif-else
if a > b
  echo "a is greater than b"
elseif a == b
  echo "a is equal to b"
else
  echo "a is less than b"
endif

" One-line if
if 1 | echo "True condition" | endif

" Switch/Case equivalent
let fruit = "apple"
if fruit ==# "apple"
  echo "It's an apple"
elseif fruit ==# "banana"
  echo "It's a banana"
elseif fruit ==# "cherry"
  echo "It's a cherry"
else
  echo "Unknown fruit"
endif

" 4.2 Loops
" While loop
let i = 1
while i <= 5
  echo "While loop iteration: " . i
  let i += 1
endwhile

" For loop with range()
for j in range(1, 5)
  echo "For loop iteration: " . j
endfor

" For loop with list
for item in ['apple', 'banana', 'cherry']
  echo "Item: " . item
endfor

" For loop with dictionary
for [key, value] in items({'name': 'John', 'age': 30})
  echo "Key: " . key . ", Value: " . value
endfor

" For loop with continue and break
for k in range(1, 10)
  if k == 3
    continue    " Skip iteration
  endif
  if k > 7
    break       " Exit loop
  endif
  echo "K value: " . k
endfor

" -----------------------------------------------------------------------------
" 5. Exception Handling
" -----------------------------------------------------------------------------
" Try-catch-finally blocks
try
  " Code that might cause an error
  echo "Trying something..."
  " throw "Custom error"  " Uncomment to throw an error
catch /Custom/    " Catch specific errors
  echo "Caught custom error"
catch /^Vim\%((\a\+)\)\=:E/    " Catch all Vim errors
  echo "Caught Vim error: " . v:exception
catch /.*/       " Catch any other errors
  echo "Caught error: " . v:exception . " at " . v:throwpoint
finally          " Always executed
  echo "Finally block executed"
endtry

" Practical example
try
  " Try to use a plugin command that might not exist
  call NonExistentFunction()
catch
  echo "Function doesn't exist, using fallback"
endtry

" -----------------------------------------------------------------------------
" 6. Functions
" -----------------------------------------------------------------------------
" 6.1 Basic function
function! HelloWorld()
  echo "Hello, World!"
endfunction

" 6.2 Function with arguments
function! Greet(name)
  echo "Hello, " . a:name . "!"
endfunction

" 6.3 Function with default arguments
function! GreetWithDefault(name, greeting = "Hello")
  echo a:greeting . ", " . a:name . "!"
endfunction

" 6.4 Function with variable number of arguments
function! Sum(...)
  let result = 0
  for i in range(a:0)  " a:0 is the number of extra arguments
    let result += a:000[i]  " a:000 is the list of extra arguments
  endfor
  return result
endfunction

" 6.5 Function with both fixed and variable arguments
function! CalculateWithBase(base, ...)
  let result = a:base
  for i in range(a:0)
    let result += a:000[i]
  endfor
  return result
endfunction

" 6.6 Function with range support
function! ReverseLines() range
  for line_num in range(a:firstline, a:lastline)
    let curr_line = getline(line_num)
    let reversed = join(reverse(split(curr_line, '\zs')), '')
    call setline(line_num, reversed)
  endfor
endfunction

" 6.7 Function with dictionary context
function! s:dict_function() dict
  echo "Name: " . self.name
  echo "Age: " . self.age
endfunction

let person = {'name': 'John', 'age': 30, 'display': function('s:dict_function')}

" 6.8 Function that returns a value
function! Add(a, b)
  return a:a + a:b
endfunction

" 6.9 Calling functions
call HelloWorld()                " Call with no return value
let result = Add(10, 20)         " Call with return value
let str_len = Funcref("Vim")     " Call through a funcref
let uppercase = Capitalize("vim")  " Call a lambda function

" -----------------------------------------------------------------------------
" 7. Working with Lists
" -----------------------------------------------------------------------------
" List creation
let fruits = ['apple', 'banana', 'cherry']

" List access
let first_fruit = fruits[0]          " First item (apple)
let last_fruit = fruits[-1]          " Last item (cherry)

" List slicing
let two_fruits = fruits[0:1]         " First two items ['apple', 'banana']

" List manipulation
call add(fruits, 'date')             " Add item to end ['apple', 'banana', 'cherry', 'date']
call insert(fruits, 'apricot', 1)    " Insert at index 1 ['apple', 'apricot', 'banana', 'cherry', 'date']
call remove(fruits, 2)               " Remove item at index 2 ['apple', 'apricot', 'cherry', 'date']
let extracted = remove(fruits, 0, 1) " Remove range and return it ['apple', 'apricot']
call extend(fruits, ['fig', 'grape']) " Extend list ['cherry', 'date', 'fig', 'grape']

" List iteration
for fruit in fruits
  echo "Fruit: " . fruit
endfor

" List functions
let fruit_count = len(fruits)        " Length of list
let sorted_fruits = sort(copy(fruits)) " Sort (copy to avoid changing original)
let fruit_index = index(fruits, 'fig') " Find index of item
let fruit_joined = join(fruits, ', ') " Join list into string
let unique_list = uniq(sort(copy([1, 2, 2, 3, 3, 4]))) " Get unique items [1, 2, 3, 4]
let filtered = filter(copy(fruits), 'v:val =~# "^g"') " Filter items starting with 'g'
let mapped = map(copy(fruits), 'toupper(v:val)') " Map to uppercase
let reversed = reverse(copy(fruits)) " Reverse list

" -----------------------------------------------------------------------------
" 8. Working with Dictionaries
" -----------------------------------------------------------------------------
" Dictionary creation
let person = {'name': 'John', 'age': 30, 'city': 'New York'}

" Dictionary access
let name = person['name']           " Using key in brackets
let age = person.age                " Using dot notation
let maybe_job = get(person, 'job', 'unemployed') " Get with default if key doesn't exist

" Dictionary modification
let person.job = 'Developer'        " Add/modify using dot notation
let person['salary'] = 100000       " Add/modify using brackets
call remove(person, 'city')         " Remove a key-value pair
call extend(person, {'married': v:true}) " Extend dictionary

" Dictionary iteration
for key in keys(person)
  echo "Key: " . key . ", Value: " . person[key]
endfor

for [key, value] in items(person)
  echo "Key: " . key . ", Value: " . value
endfor

" Dictionary functions
let dict_keys = keys(person)        " Get list of keys
let dict_values = values(person)    " Get list of values
let dict_items = items(person)      " Get list of [key, value] pairs
let has_key_result = has_key(person, 'age') " Check if key exists
let dict_size = len(person)         " Number of items
let filtered_dict = filter(copy(person), 'type(v:val) == type("")') " Filter string values
let mapped_dict = map(copy(person), 'type(v:val) == type("") ? toupper(v:val) : v:val') " Map string values to uppercase

" -----------------------------------------------------------------------------
" 9. String Operations
" -----------------------------------------------------------------------------
" String creation
let str = "Hello, Vim script!"

" String access
let first_char = str[0]             " First character (H)
let substring = str[7:10]           " Substring "Vim"

" String functions
let str_len = strlen(str)           " String length
let str_lower = tolower(str)        " Lowercase
let str_upper = toupper(str)        " Uppercase
let str_words = split(str, " ")     " Split into list of words
let str_join = join(['Hello', 'Vim', 'script'], ' ') " Join list into string
let str_replace = substitute(str, 'Vim', 'VimL', 'g') " Replace text
let str_match = match(str, 'Vim')   " Find position of substring (7)
let str_chars = split(str, '\zs')   " Split into list of characters
let trim_str = trim("  Hello  ")    " Trim whitespace (Vim 8.0+)
let str_fmt = printf("%s has %d characters", str, strlen(str)) " Formatted string

" Regular expressions
let matches = matchlist(str, '\v(\w+), (\w+)')  " Find captures: ['Hello, Vim', 'Hello', 'Vim']
let str_subst = substitute(str, '\v(\w+)', '\=toupper(submatch(1))', '') " Replace using expression

" -----------------------------------------------------------------------------
" 10. File Operations
" -----------------------------------------------------------------------------
" Reading and writing files
let lines = readfile('input.txt')                      " Read file into list of lines
call writefile(['Line 1', 'Line 2'], 'output.txt')     " Write list to file
let file_exists = filereadable('input.txt')            " Check if file exists
let is_writable = filewritable('output.txt')           " Check if file is writable
let file_size = getfsize('input.txt')                  " Get file size
let file_time = getftime('input.txt')                  " Get last modification time
let file_type = getftype('input.txt')                  " Get file type
let files = glob('*.txt')                              " Get matching files
let expanded = expand('%:p')                           " Current file full path
let dirname = fnamemodify('path/to/file.txt', ':h')    " Get directory name
let filename = fnamemodify('path/to/file.txt', ':t')   " Get file name
let noext = fnamemodify('path/to/file.txt', ':r')      " Remove extension

" -----------------------------------------------------------------------------
" 11. Buffer Operations
" -----------------------------------------------------------------------------
" Buffer manipulation
let buf_list = getbufinfo()                            " Get info for all buffers
let cur_buf = bufnr('%')                               " Current buffer number
let buf_count = bufnr('$')                             " Highest buffer number
let is_loaded = bufloaded('file.txt')                  " Check if buffer is loaded
let buf_name = bufname(1)                              " Get name of buffer 1
let buf_exists = bufexists(2)                          " Check if buffer 2 exists
let modified = getbufvar(1, '&modified')               " Get buffer option

" -----------------------------------------------------------------------------
" 12. Window Operations
" -----------------------------------------------------------------------------
" Window information
let win_count = winnr('$')                             " Number of windows
let cur_win = winnr()                                  " Current window number
let win_id = win_getid()                               " Get window ID
let win_info = getwininfo()                            " Get info for all windows
let buf_in_win = winbufnr(1)                           " Buffer in window 1
let win_height = winheight(0)                          " Height of current window
let win_width = winwidth(0)                            " Width of current window

" -----------------------------------------------------------------------------
" 13. Tab Operations
" -----------------------------------------------------------------------------
" Tab information
let tab_count = tabpagenr('$')                         " Number of tabs
let cur_tab = tabpagenr()                              " Current tab number
let tab_info = gettabinfo()                            " Get info for all tabs

" -----------------------------------------------------------------------------
" 14. Option Handling
" -----------------------------------------------------------------------------
" Get and set options
let opt_value = &tabstop                               " Get option value
let &shiftwidth = 4                                    " Set option value
let old_opt = &textwidth                               " Save option value
let &textwidth = 80                                    " Change option
set number                                             " Set boolean option
set nonumber                                           " Unset boolean option
let is_set = &number                                   " Get boolean option
let local_opt = &l:indentexpr                          " Get local option
let global_opt = &g:undolevels                         " Get global option

" -----------------------------------------------------------------------------
" 15. Register Operations
" -----------------------------------------------------------------------------
" Register manipulation
let reg_value = @a                                     " Get register 'a' content
let @b = "New content"                                 " Set register 'b' content
let clipboard = @+                                     " Get clipboard content (if available)
let search_pat = @/                                    " Get search pattern register
let reg_types = getregtype('a')                        " Get register type
call setreg('c', 'Content', 'v')                       " Set register with type

" -----------------------------------------------------------------------------
" 16. Cursor and Screen Functions
" -----------------------------------------------------------------------------
" Cursor position
let cursor_pos = getcurpos()                           " Get cursor position [bufnum, lnum, col, off, curswant]
let line_num = line('.')                               " Current line number
let col_num = col('.')                                 " Current column number
let cursor_byte = line2byte(line('.')) + col('.') - 1  " Byte position of cursor
let screen_row = winline()                             " Screen row of cursor
let screen_col = wincol()                              " Screen column of cursor

" Screen information
let screen_rows = &lines                               " Number of screen rows
let screen_cols = &columns                             " Number of screen columns

" -----------------------------------------------------------------------------
" 17. Text Manipulation
" -----------------------------------------------------------------------------
" Line operations
let cur_line = getline('.')                            " Get current line
call setline('.', 'New text')                          " Set current line
call append('.', 'Add after current')                  " Append after current line
call append(0, 'Add to top')                           " Add to top of buffer
let line_count = line('$')                             " Number of lines in buffer
call deletebufline('%', 5)                             " Delete line 5 (Vim 8.1+)