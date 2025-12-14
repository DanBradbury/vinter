module Vinter
  class Lexer
    BUILTINS = [
      "abs(",
      "acos(",
      "add(",
      "and(",
      "append(",
      "appendbufline(",
      "argc(",
      "argidx(",
      "arglistid(",
      "argv(",
      "argv(",
      "asin(",
      "assert_beeps(",
      "assert_equal(",
      "assert_equalfile(",
      "assert_exception(",
      "assert_fails(",
      "assert_false(",
      "assert_inrange(",
      "assert_match(",
      "assert_nobeep(",
      "assert_notequal(",
      "assert_notmatch(",
      "assert_report(",
      "assert_true(",
      "atan(",
      "atan2(",
      "autocmd_add(",
      "autocmd_delete(",
      "autocmd_get(",
      "balloon_gettext(",
      "balloon_show(",
      "balloon_split(",
      "bindtextdomain(",
      "blob2list(",
      "browse(",
      "browsedir(",
      "bufadd(",
      "bufexists(",
      "buflisted(",
      "bufload(",
      "bufloaded(",
      "bufname(",
      "bufnr(",
      "bufwinid(",
      "bufwinnr(",
      "byte2line(",
      "byteidx(",
      "byteidxcomp(",
      "call(",
      "ceil(",
      "ch_canread(",
      "ch_close(",
      "ch_close_in(",
      "ch_evalexpr(",
      "ch_evalraw(",
      "ch_getbufnr(",
      "ch_getjob(",
      "ch_info(",
      "ch_log(",
      "ch_logfile(",
      "ch_open(",
      "ch_read(",
      "ch_readblob(",
      "ch_readraw(",
      "ch_sendexpr(",
      "ch_sendraw(",
      "ch_setoptions(",
      "ch_status(",
      "changenr(",
      "char2nr(",
      "charclass(",
      "charcol(",
      "charidx(",
      "chdir(",
      "cindent(",
      "clearmatches(",
      "col(",
      "complete(",
      "complete_add(",
      "complete_check(",
      "complete_info(",
      "confirm(",
      "copy(",
      "cos(",
      "cosh(",
      "count(",
      "cscope_connection(",
      "cursor(",
      "cursor(",
      "debugbreak(",
      "deepcopy(",
      "delete(",
      "deletebufline(",
      "did_filetype(",
      "diff(",
      "diff_filler(",
      "diff_hlID(",
      "digraph_get(",
      "digraph_getlist(",
      "digraph_set(",
      "digraph_setlist(",
      "echoraw(",
      "empty(",
      "environ(",
      "err_teapot(",
      "escape(",
      "eval(",
      "eventhandler(",
      "executable(",
      "execute(",
      "exepath(",
      "exists(",
      "exists_compiled(",
      "exp(",
      "expand(",
      "expandcmd(",
      "extend(",
      "extendnew(",
      "feedkeys(",
      "filecopy(",
      "filereadable(",
      "filewritable(",
      "filter(",
      "finddir(",
      "findfile(",
      "flatten(",
      "flattennew(",
      "float2nr(",
      "floor(",
      "fmod(",
      "fnameescape(",
      "fnamemodify(",
      "foldclosed(",
      "foldclosedend(",
      "foldlevel(",
      "foldtext(",
      "foldtextresult(",
      "foreach(",
      "foreground(",
      "fullcommand(",
      "funcref(",
      "function(",
      "garbagecollect(",
      "get(",
      "get(",
      "get(",
      "getbufinfo(",
      "getbufline(",
      "getbufoneline(",
      "getbufvar(",
      "getcellwidths(",
      "getchangelist(",
      "getchar(",
      "getcharmod(",
      "getcharpos(",
      "getcharsearch(",
      "getcharstr(",
      "getcmdcompltype(",
      "getcmdline(",
      "getcmdpos(",
      "getcmdscreenpos(",
      "getcmdtype(",
      "getcmdwintype(",
      "getcompletion(",
      "getcurpos(",
      "getcursorcharpos(",
      "getcwd(",
      "getenv(",
      "getfontname(",
      "getfperm(",
      "getfsize(",
      "getftime(",
      "getftype(",
      "getimstatus(",
      "getjumplist(",
      "getline(",
      "getline(",
      "getloclist(",
      "getloclist(",
      "getmarklist(",
      "getmatches(",
      "getmousepos(",
      "getmouseshape(",
      "getpid(",
      "getpos(",
      "getqflist(",
      "getqflist(",
      "getreg(",
      "getreginfo(",
      "getregion(",
      "getregionpos(",
      "getregtype(",
      "getscriptinfo(",
      "gettabinfo(",
      "gettabvar(",
      "gettabwinvar(",
      "gettagstack(",
      "gettext(",
      "getwininfo(",
      "getwinpos(",
      "getwinposx(",
      "getwinposy(",
      "getwinvar(",
      "glob(",
      "glob2regpat(",
      "globpath(",
      "has(",
      "has_key(",
      "haslocaldir(",
      "hasmapto(",
      "histadd(",
      "histdel(",
      "histget(",
      "histnr(",
      "hlID(",
      "hlexists(",
      "hlget(",
      "hlset(",
      "hostname(",
      "iconv(",
      "id(",
      "indent(",
      "index(",
      "indexof(",
      "input(",
      "inputdialog(",
      "inputlist(",
      "inputrestore(",
      "inputsave(",
      "inputsecret(",
      "insert(",
      "instanceof(",
      "interrupt(",
      "invert(",
      "isabsolutepath(",
      "isdirectory(",
      "isinf(",
      "islocked(",
      "isnan(",
      "items(",
      "job_getchannel(",
      "job_info(",
      "job_setoptions(",
      "job_start(",
      "job_status(",
      "job_stop(",
      "join(",
      "js_decode(",
      "js_encode(",
      "json_decode(",
      "json_encode(",
      "keys(",
      "keytrans(",
      "len(",
      "libcall(",
      "libcallnr(",
      "line(",
      "line2byte(",
      "lispindent(",
      "list2blob(",
      "list2str(",
      "listener_add(",
      "listener_flush(",
      "listener_remove(",
      "localtime(",
      "log(",
      "log10(",
      "luaeval(",
      "map(",
      "maparg(",
      "mapcheck(",
      "maplist(",
      "mapnew(",
      "mapset(",
      "match(",
      "matchadd(",
      "matchaddpos(",
      "matcharg(",
      "matchbufline(",
      "matchdelete(",
      "matchend(",
      "matchfuzzy(",
      "matchfuzzypos(",
      "matchlist(",
      "matchstr(",
      "matchstrlist(",
      "matchstrpos(",
      "max(",
      "menu_info(",
      "min(",
      "mkdir(",
      "mode(",
      "mzeval(",
      "nextnonblank(",
      "nr2char(",
      "or(",
      "pathshorten(",
      "perleval(",
      "popup_atcursor(",
      "popup_beval(",
      "popup_clear(",
      "popup_close(",
      "popup_create(",
      "popup_dialog(",
      "popup_filter_menu(",
      "popup_filter_yesno(",
      "popup_findecho(",
      "popup_findinfo(",
      "popup_findpreview(",
      "popup_getoptions(",
      "popup_getpos(",
      "popup_hide(",
      "popup_list(",
      "popup_locate(",
      "popup_menu(",
      "popup_move(",
      "popup_notification(",
      "popup_setbuf(",
      "popup_setoptions(",
      "popup_settext(",
      "popup_show(",
      "pow(",
      "prevnonblank(",
      "printf(",
      "prompt_getprompt(",
      "prompt_setcallback(",
      "prompt_setinterrupt(",
      "prompt_setprompt(",
      "prop_add(",
      "prop_add_list(",
      "prop_clear(",
      "prop_find(",
      "prop_list(",
      "prop_remove(",
      "prop_type_add(",
      "prop_type_change(",
      "prop_type_delete(",
      "prop_type_get(",
      "prop_type_list(",
      "pum_getpos(",
      "pumvisible(",
      "py3eval(",
      "pyeval(",
      "pyxeval(",
      "rand(",
      "range(",
      "readblob(",
      "readdir(",
      "readdirex(",
      "readfile(",
      "reduce(",
      "reg_executing(",
      "reg_recording(",
      "reltime(",
      "reltimefloat(",
      "reltimestr(",
      "remote_expr(",
      "remote_foreground(",
      "remote_peek(",
      "remote_read(",
      "remote_send(",
      "remote_startserver(",
      "remove(",
      "remove(",
      "remove(",
      "rename(",
      "repeat(",
      "resolve(",
      "reverse(",
      "round(",
      "rubyeval(",
      "screenattr(",
      "screenchar(",
      "screenchars(",
      "screencol(",
      "screenpos(",
      "screenrow(",
      "screenstring(",
      "search(",
      "searchcount(",
      "searchdecl(",
      "searchpair(",
      "searchpairpos(",
      "searchpos(",
      "server2client(",
      "serverlist(",
      "setbufline(",
      "setbufvar(",
      "setcellwidths(",
      "setcharpos(",
      "setcharsearch(",
      "setcmdline(",
      "setcmdpos(",
      "setcursorcharpos(",
      "setenv(",
      "setfperm(",
      "setline(",
      "setloclist(",
      "setloclist(",
      "setmatches(",
      "setpos(",
      "setqflist(",
      "setqflist(",
      "setreg(",
      "settabvar(",
      "settabwinvar(",
      "settagstack(",
      "setwinvar(",
      "sha256(",
      "shellescape(",
      "shiftwidth(",
      "showdefinition(",
      "sign_define(",
      "sign_define(",
      "sign_getdefined(",
      "sign_getplaced(",
      "sign_jump(",
      "sign_place(",
      "sign_placelist(",
      "sign_undefine(",
      "sign_undefine(",
      "sign_unplace(",
      "sign_unplacelist(",
      "simplify(",
      "sin(",
      "sinh(",
      "slice(",
      "sort(",
      "sound_clear(",
      "sound_playevent(",
      "sound_playfile(",
      "sound_stop(",
      "soundfold(",
      "spellbadword(",
      "spellsuggest(",
      "split(",
      "sqrt(",
      "srand(",
      "state(",
      "str2float(",
      "str2list(",
      "str2nr(",
      "strcharlen(",
      "strcharpart(",
      "strchars(",
      "strdisplaywidth(",
      "strftime(",
      "strgetchar(",
      "stridx(",
      "string(",
      "strlen(",
      "strpart(",
      "strptime(",
      "strridx(",
      "strtrans(",
      "strutf16len(",
      "strwidth(",
      "submatch(",
      "substitute(",
      "swapfilelist(",
      "swapinfo(",
      "swapname(",
      "synID(",
      "synIDattr(",
      "synIDtrans(",
      "synconcealed(",
      "synstack(",
      "system(",
      "systemlist(",
      "tabpagebuflist(",
      "tabpagenr(",
      "tabpagewinnr(",
      "tagfiles(",
      "taglist(",
      "tan(",
      "tanh(",
      "tempname(",
      "term_dumpdiff(",
      "term_dumpload(",
      "term_dumpwrite(",
      "term_getaltscreen(",
      "term_getansicolors(",
      "term_getattr(",
      "term_getcursor(",
      "term_getjob(",
      "term_getline(",
      "term_getscrolled(",
      "term_getsize(",
      "term_getstatus(",
      "term_gettitle(",
      "term_gettty(",
      "term_list(",
      "term_scrape(",
      "term_sendkeys(",
      "term_setansicolors(",
      "term_setapi(",
      "term_setkill(",
      "term_setrestore(",
      "term_setsize(",
      "term_start(",
      "term_wait(",
      "terminalprops(",
      "test_alloc_fail(",
      "test_autochdir(",
      "test_feedinput(",
      "test_garbagecollect_now(",
      "test_garbagecollect_soon(",
      "test_getvalue(",
      "test_gui_event(",
      "test_ignore_error(",
      "test_mswin_event(",
      "test_null_blob(",
      "test_null_channel(",
      "test_null_dict(",
      "test_null_function(",
      "test_null_job(",
      "test_null_list(",
      "test_null_partial(",
      "test_null_string(",
      "test_option_not_set(",
      "test_override(",
      "test_refcount(",
      "test_setmouse(",
      "test_settime(",
      "test_srand_seed(",
      "test_unknown(",
      "test_void(",
      "timer_info(",
      "timer_pause(",
      "timer_start(",
      "timer_stop(",
      "timer_stopall(",
      "tolower(",
      "toupper(",
      "tr(",
      "trim(",
      "trunc(",
      "type(",
      "typename(",
      "undofile(",
      "undotree(",
      "uniq(",
      "utf16idx(",
      "values(",
      "virtcol(",
      "virtcol2col(",
      "visualmode(",
      "wildmenumode(",
      "win_execute(",
      "win_findbuf(",
      "win_getid(",
      "win_gettype(",
      "win_gotoid(",
      "win_id2tabwin(",
      "win_id2win(",
      "win_move_separator(",
      "win_move_statusline(",
      "win_screenpos(",
      "win_splitmove(",
      "winbufnr(",
      "wincol(",
      "windowsversion(",
      "winheight(",
      "winlayout(",
      "winline(",
      "winnr(",
      "winrestcmd(",
      "winrestview(",
      "winsaveview(",
      "winwidth(",
      "wordcount(",
      "writefile(",
      "xor("
    ]
    TOKEN_TYPES = {
      # Vim9 specific keywords
      keyword: /\b(if|else|elseif|endif|while|endwhile|for|endfor|def|enddef|function|endfunction|endfunc|return|const|var|final|import|export|class|extends|static|enum|vim9script|scriptencoding|abort|autocmd|echom|echoerr|echohl|echomsg|let|unlet|continue|break|try|catch|finally|endtry|throw|runtime|silent|delete|command|call|set|setlocal|syntax|sleep|source|nnoremap|nmap|inoremap|imap|vnoremap|vmap|xnoremap|xmap|cnoremap|cmap|noremap|var)\b/,
      encodings: /\b(latin1|iso|koi8|macroman|cp437|cp737|cp775|cp850|cp852|cp855|cp857|cp860|cp861|cp862|cp863|cp865|cp866|cp869|cp874|cp1250|cp1251|cp1253|cp1254|cp1255|cp1256|cp1257|cp1258|cp932|euc\-jp|sjis|cp949|euc\-kr|cp936|euc\-cn|cp950|big5|euc\-tw|utf\-8|ucs\-2|ucs\-21e|utf\-16|utf\-16le|ucs\-4|ucs\-4le|ansi|japan|korea|prc|chinese|taiwan|utf8|unicode|ucs2be|ucs\-2be|ucs\-4be|utf\-32|utf\-32le)\b/,
      #builtin_funcs: /\b(highlight||normal!|normal|filter|match|extend|redraw!|setbufline)\b/,
      type: /\b(number|list|dict|void|string)\b/,
      builtin_funcs: /\b(#{Regexp.union(BUILTINS).source})\b/,
      # Identifiers can include # and special characters
      heredoc: /=<</,
      # Single-character operators
      operator: /[\+\-\*\/=%<>!&\|\.]/,
      # Multi-character operators handled separately
      number: /\b(0[xX][0-9A-Fa-f]+|0[oO][0-7]+|0[bB][01]+|\d+(\.\d+)?([eE][+-]?\d+)?[smh]?)\b/,
      # Handle both single and double quoted strings
      # string: /"(\\"|[^"])*"|'(\\'|[^'])*'/,
      register_access: /@[a-zA-Z0-9":.%#=*+~_\/\-]/,
      identifier: /\b[a-zA-Z_][a-zA-Z0-9_#]*/,
      # Vim9 comments use #
      comment: /^(?: (?! g:).)*#.*/,
      whitespace: /\s+/,
      brace_open: /\{/,
      brace_close: /\}/,
      paren_open: /\(/,
      paren_close: /\)/,
      bracket_open: /\[/,
      bracket_close: /\]/,
      colon: /:/,
      semicolon: /;/,
      comma: /,/,
      backslash: /\\/,
      question_mark: /\?/,
      command_separator: /\|/,
    }

    CONTINUATION_OPERATORS = %w(. .. + - * / = == ==# ==? != > < >= <= && || ? : -> =>)
    def initialize(input)
      @input = input
      @tokens = []
      @position = 0
      @line_num = 1
      @column = 1
    end

    def should_parse_as_regex
      # Look at recent tokens to determine if we're in a regex context
      recent_tokens = @tokens.last(3)

      # Check for contexts where regex is expected
      return true if recent_tokens.any? { |t|
        t && t[:type] == :keyword && ['syntax'].include?(t[:value])
      }

      return true if recent_tokens.any? { |t|
        t && t[:type] == :identifier && ['match', 'region', 'keyword'].include?(t[:value])
      }

      # Check for comparison operators that often use regex
      return true if recent_tokens.any? { |t|
        t && t[:type] == :operator && ['=~', '!~', '=~#', '!~#', '=~?', '!~?'].include?(t[:value])
      }

      false
    end

    def find_unescaped_newline(chunk)
      i = 0
      while i < chunk.length
        if chunk[i] == "\n" && (i == 0 || chunk[i - 1] != '\\')
          return i
        end
        i += 1
      end
      nil # Return nil if no unescaped newline is found
    end

    def tokenize
      until @position >= @input.length
        chunk = @input[@position..-1]

        # First check if the line starts with a quote (comment in Vim)
        # Check if we're at the beginning of a line (optionally after whitespace)
        line_start = @position == 0 || @input[@position - 1] == "\n"
        if !line_start
          # Check if we're after whitespace at the start of a line
          temp_pos = @position - 1
          while temp_pos >= 0 && @input[temp_pos] =~ /[ \t]/
            temp_pos -= 1
          end
          line_start = temp_pos < 0 || @input[temp_pos] == "\n"
        end

        # If we're at the start of a line and it begins with a quote
        #if line_start && chunk.start_with?('"')
          ## Find the end of the line
          #line_end = find_unescaped_newline(chunk) || chunk.length
          #comment_text = chunk[0...line_end]

          #@tokens << {
            #type: :comment,
            #value: comment_text,
            #line: @line_num,
            #column: @column
          #}

          #@position += comment_text.length
          #@column += comment_text.length
          #next
        #end

        # --- Interpolated String Handling ---
        if chunk.start_with?("$'")
          i = 2
          string_value = "$'"
          brace_depth = 0
          escaped = false

          while i < chunk.length
            char = chunk[i]
            string_value += char

            if char == '\\' && !escaped
              escaped = true
            elsif char == "'" && !escaped && brace_depth == 0
              # End of interpolated string
              i += 1
              break
            elsif char == '{' && !escaped
              brace_depth += 1
            elsif char == '}' && !escaped && brace_depth > 0
              brace_depth -= 1
            elsif escaped
              escaped = false
            end

            i += 1
          end

          @tokens << {
            type: :interpolated_string,
            value: string_value,
            line: @line_num,
            column: @column
          }
          @column += string_value.length
          @position += string_value.length
          @line_num += string_value.count("\n")
          next
        end

        # XXX: i dont like this not being combined with $' condition above
        if chunk.start_with?('$"')
          i = 2
          string_value = '$"'
          brace_depth = 0
          escaped = false

          while i < chunk.length
            char = chunk[i]
            string_value += char

            if char == '\\' && !escaped
              escaped = true
            elsif char == '"' && !escaped && brace_depth == 0
              # End of interpolated string
              i += 1
              break
            elsif char == '{' && !escaped
              brace_depth += 1
            elsif char == '}' && !escaped && brace_depth > 0
              brace_depth -= 1
            elsif escaped
              escaped = false
            end

            i += 1
          end

          @tokens << {
            type: :interpolated_string,
            value: string_value,
            line: @line_num,
            column: @column
          }
          @column += string_value.length
          @position += string_value.length
          @line_num += string_value.count("\n")
          next
        end

        # Handle string literals manually
        if chunk.start_with?("'") || chunk.start_with?('"')
          quote = chunk[0]
          i = 1
          string_value = quote

          # Keep going until we find an unescaped closing quote
          while i < chunk.length
            char = chunk[i]
            next_char = chunk[i + 1] if i + 1 < chunk.length

            string_value += char

            if char == quote && next_char == quote
              # Handle escaped single quote ('') or double quote ("")
              string_value += next_char
              i += 1
            elsif char == quote
              # End of string
              i += 1
              break
            end

            i += 1
          end

          # Add the string token if we found a closing quote
          @tokens << {
            type: :string,
            value: string_value,
            line: @line_num,
            column: @column
          }

          @column += string_value.length
          @position += string_value.length
          @line_num += string_value.count("\n")
          next
        end

        # Add special handling for command options in the tokenize method
        if chunk.start_with?('<q-args>', '<f-args>', '<args>')
          arg_token = chunk.match(/\A(<q-args>|<f-args>|<args>)/)[0]
          @tokens << {
            type: :command_arg_placeholder,
            value: arg_token,
            line: @line_num,
            column: @column
          }
          @column += arg_token.length
          @position += arg_token.length
          next
        end

        # Special handling for a:000 variable arguments array
        if chunk =~ /\Aa:0+/
          varargs_token = chunk.match(/\Aa:0+/)[0]
          @tokens << {
            type: :arg_variable,
            value: varargs_token,
            line: @line_num,
            column: @column
          }
          @column += varargs_token.length
          @position += varargs_token.length
          next
        end

        # Also add special handling for 'silent!' keyword
        # Add this after the keyword check in tokenize method
        if chunk.start_with?('silent!')
          @tokens << {
            type: :silent_bang,
            value: 'silent!',
            line: @line_num,
            column: @column
          }
          @column += 7
          @position += 7
          next
        end

        # Check for keywords first, before other token types
        if match = chunk.match(/\A\b(if|else|elseif|endif|while|endwhile|for|endfor|def|enddef|function|endfunction|endfunc|return|const|var|final|import|export|class|extends|static|enum|vim9script|abort|autocmd|echoerr|echohl|echomsg|let|unlet|var|setlocal|syntax|highlight|sleep|source)\b/)
          @tokens << {
            type: :keyword,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle Vim scoped option variables with &l: or &g: prefix
        if match = chunk.match(/\A&[lg]:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :scoped_option_variable,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle Vim option variables with & prefix
        if match = chunk.match(/\A&[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :option_variable,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle Vim special variables with v: prefix
        if match = chunk.match(/\Av:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :special_variable,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle script-local identifiers with s: prefix
        if match = chunk.match(/\As:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :script_local,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle buffer-local identifiers with b: prefix
        if match = chunk.match(/\Ab:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :buffer_local,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle window-local identifiers with w: prefix
        if match = chunk.match(/\Aw:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :window_local,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle tab-local identifiers with t: prefix
        if match = chunk.match(/\At:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :tab_local,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end


        # Handle global variables with g: prefix
        if match = chunk.match(/\Ag:[a-zA-Z_][\w#]*/)
          @tokens << {
            type: :global_variable,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle argument variables with a: prefix
        if match = chunk.match(/\Aa:[a-zA-Z_][a-zA-Z0-9_]*/) || match = chunk.match(/\Aa:[A-Z0-9]/)
          @tokens << {
            type: :arg_variable,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle argument variables with a: prefix
        if match = chunk.match(/\Al:[a-zA-Z_][a-zA-Z0-9_]*/)
          @tokens << {
            type: :local_variable,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Add support for standalone namespace prefixes (like g:)
        if match = chunk.match(/\A([gbwt]):/)
          @tokens << {
            type: :namespace_prefix,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle compound assignment operators
        if match = chunk.match(/\A(\+=|-=|\*=|\/=|\.\.=|\.=)/)
          @tokens << {
            type: :compound_operator,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle ellipsis for variable args
        if chunk.start_with?('...')
          @tokens << {
            type: :ellipsis,
            value: '...',
            line: @line_num,
            column: @column
          }
          @column += 3
          @position += 3
          next
        end

        # Handle multi-character operators explicitly
        if match = chunk.match(/\A(=~#|=~\?|=~|!~#|!~\?|!~|==#|==\?|==|!=#|!=\?|!=|=>\?|=>|>=#|>=\?|>=|<=#|<=\?|<=|->#|->\?|->|\.\.|\|\||&&)/)
          @tokens << {
            type: :operator,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle regex patterns /pattern/ - only in specific contexts
        if chunk.start_with?('/') && should_parse_as_regex
          i = 1
          regex_value = '/'

          # Keep going until we find the closing slash
          while i < chunk.length
            char = chunk[i]
            regex_value += char

            if char == '/' && (i == 1 || chunk[i-1] != '\\')
              # Found closing slash
              i += 1
              break
            end

            i += 1
          end

          # Add the regex token if we found a closing slash
          if regex_value.end_with?('/')
            @tokens << {
              type: :regex,
              value: regex_value,
              line: @line_num,
              column: @column
            }
            @column += regex_value.length
            @position += regex_value.length
            next
          end
        end

        # Handle hex colors like #33FF33
        if match = chunk.match(/\A#[0-9A-Fa-f]{6}/)
          @tokens << {
            type: :hex_color,
            value: match[0],
            line: @line_num,
            column: @column
          }
          @column += match[0].length
          @position += match[0].length
          next
        end

        # Handle register access (@a, @", etc.)
        if chunk =~ /\A@[a-zA-Z0-9":.%#=*+~_\/\-]/
          register_token = chunk.match(/\A@[a-zA-Z0-9":.%#=*+~_\/\-]/)[0]
          @tokens << {
            type: :register_access,
            value: register_token,
            line: @line_num,
            column: @column
          }
          @column += register_token.length
          @position += register_token.length
          next
        end

        # In the tokenize method, add special handling for common mapping components
        if chunk.start_with?('<CR>', '<Esc>', '<Tab>', '<Space>', '<C-')
          # Extract the special key notation
          match = chunk.match(/\A(<[^>]+>)/)
          if match
            special_key = match[1]
            @tokens << {
              type: :special_key,
              value: special_key,
              line: @line_num,
              column: @column
            }
            @position += special_key.length
            @column += special_key.length
            next
          end
        end

        # Skip whitespace but track position
        if match = chunk.match(/\A(\s+)/)
          whitespace = match[0]
          whitespace.each_char do |c|
            if c == "\n"
              @line_num += 1
              @column = 1
            else
              @column += 1
            end
          end
          @position += whitespace.length
          next
        end

        # Handle backslash for line continuation
        if chunk.start_with?('\\')
          @tokens << {
            type: :line_continuation,
            value: '\\',
            line: @line_num,
            column: @column
          }
          @column += 1
          @position += 1

          # If followed by a newline, advance to the next line
          if @position < @input.length && @input[@position] == "\n"
            @line_num += 1
            @column = 1
            @position += 1
          end

          # Skip whitespace after the continuation
          while @position < @input.length && @input[@position] =~ /\s/
            if @input[@position] == "\n"
              @line_num += 1
              @column = 1
            else
              @column += 1
            end
            @position += 1
          end

          next
        end

        # Check for special case where 'function' is followed by '('
        # which likely means it's used as a built-in function
        if chunk =~ /\Afunction\s*\(/
          @tokens << {
            type: :identifier,  # Treat as identifier, not keyword
            value: 'function',
            line: @line_num,
            column: @column
          }
          @column += 'function'.length
          @position += 'function'.length
          next
        end

        match_found = false

        TOKEN_TYPES.each do |type, pattern|
          if match = chunk.match(/\A(#{pattern})/)
            value = match[0]
            token = {
              type: type,
              value: value,
              line: @line_num,
              column: @column
            }
            @tokens << token unless type == :whitespace

            # Update position
            if value.include?("\n")
              lines = value.split("\n")
              @line_num += lines.size - 1
              if lines.size > 1
                @column = lines.last.length + 1
              else
                @column += value.length
              end
            else
              @column += value.length
            end

            @position += value.length
            match_found = true
            break
          end
        end

        unless match_found
          # Try to handle unknown characters
          @tokens << {
            type: :unknown,
            value: chunk[0],
            line: @line_num,
            column: @column
          }

          if chunk[0] == "\n"
            @line_num += 1
            @column = 1
          else
            @column += 1
          end

          @position += 1
        end
      end

      @tokens
    end
  end
end
