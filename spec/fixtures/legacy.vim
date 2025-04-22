scriptencoding utf-8

if exists('loaded_nerd_tree')
    finish
endif
if v:version < 703
    echoerr "NERDTree: this plugin requires vim >= 7.3. DOWNLOAD IT! You'll thank me later!"
    finish
endif
let loaded_nerd_tree = 1

"for line continuation - i.e dont want C in &cpoptions
let s:old_cpo = &cpoptions
set cpoptions&vim
"SECTION: Initialize variable calls and other random constants {{{2
let g:NERDTreeAutoCenter            = get(g:, 'NERDTreeAutoCenter',            1)
let g:NERDTreeSortHiddenFirst       = get(g:, 'NERDTreeSortHiddenFirst',       1)
let g:NERDTreeUseTCD                = get(g:, 'NERDTreeUseTCD',                0)
let g:NERDTreeChDirMode             = get(g:, 'NERDTreeChDirMode',             0)
let g:NERDTreeCreatePrefix          = get(g:, 'NERDTreeCreatePrefix',          'silent')
let g:NERDTreeMinimalUI             = get(g:, 'NERDTreeMinimalUI',             0)
let g:NERDTreeMinimalMenu           = get(g:, 'NERDTreeMinimalMenu',           0)
let g:NERDTreeIgnore                = get(g:, 'NERDTreeIgnore',                ['\~$'])
let g:NERDTreeBookmarksFile         = get(g:, 'NERDTreeBookmarksFile',         expand('$HOME') . '/.NERDTreeBookmarks')
let g:NERDTreeBookmarksSort         = get(g:, 'NERDTreeBookmarksSort',         1)
let g:NERDTreeHighlightCursorline   = get(g:, 'NERDTreeHighlightCursorline',   1)
let g:NERDTreeHijackNetrw           = get(g:, 'NERDTreeHijackNetrw',           1)
let g:NERDTreeMarkBookmarks         = get(g:, 'NERDTreeMarkBookmarks',         1)
let g:NERDTreeMouseMode             = get(g:, 'NERDTreeMouseMode',             1)
let g:NERDTreeNotificationThreshold = get(g:, 'NERDTreeNotificationThreshold', 100)
let g:NERDTreeQuitOnOpen            = get(g:, 'NERDTreeQuitOnOpen',            0)
let g:NERDTreeRespectWildIgnore     = get(g:, 'NERDTreeRespectWildIgnore',     0)
let g:NERDTreeShowBookmarks         = get(g:, 'NERDTreeShowBookmarks',         0)
let g:NERDTreeShowFiles             = get(g:, 'NERDTreeShowFiles',             1)
let g:NERDTreeShowHidden            = get(g:, 'NERDTreeShowHidden',            0)
let g:NERDTreeShowLineNumbers       = get(g:, 'NERDTreeShowLineNumbers',       0)
let g:NERDTreeSortDirs              = get(g:, 'NERDTreeSortDirs',              1)
let g:NERDTreeFileLines             = get(g:, 'NERDTreeFileLines',             0)
if !nerdtree#runningWindows() && !nerdtree#runningCygwin()
    let g:NERDTreeDirArrowExpandable  = get(g:, 'NERDTreeDirArrowExpandable',  '▸')
    let g:NERDTreeDirArrowCollapsible = get(g:, 'NERDTreeDirArrowCollapsible', '▾')
elseif 1==2
    let s:thing = 33
else
    let g:NERDTreeDirArrowExpandable  = get(g:, 'NERDTreeDirArrowExpandable',  '+')
    let g:NERDTreeDirArrowCollapsible = get(g:, 'NERDTreeDirArrowCollapsible', '~')
endif

let g:NERDTreeCascadeOpenSingleChildDir = get(g:, 'NERDTreeCascadeOpenSingleChildDir', 1)
let g:NERDTreeCascadeSingleChildDir     = get(g:, 'NERDTreeCascadeSingleChildDir',     1)

let g:NERDTreeSortOrder    = get(g:, 'NERDTreeSortOrder', ['\/$', '*', '\.swp$', '\.bak$', '\~$'])
let g:NERDTreeOldSortOrder = []

let g:NERDTreeGlyphReadOnly = get(g:, 'NERDTreeGlyphReadOnly', 'RO')
if has('conceal')
    let g:NERDTreeNodeDelimiter = get(g:, 'NERDTreeNodeDelimiter', "\x07")
elseif (g:NERDTreeDirArrowExpandable == "\u00a0")
    let g:NERDTreeNodeDelimiter = get(g:, 'NERDTreeNodeDelimiter', "\u00b7")
else
    let g:NERDTreeNodeDelimiter = get(g:, 'NERDTreeNodeDelimiter', "\u00a0")
endif
"the exists() crap here is a hack to stop vim spazzing out when
"loading a session that was created with an open nerd tree. It spazzes
"because it doesnt store b:NERDTree(its a b: var, and its a hash)
let g:NERDTreeStatusline = get(g:, 'NERDTreeStatusline', "%{exists('b:NERDTree')?b:NERDTree.root.path.str():''}")

let g:NERDTreeWinPos  = get(g:, 'NERDTreeWinPos', 'left')
let g:NERDTreeWinSize = get(g:, 'NERDTreeWinSize', 31)

"init the shell commands that will be used to copy nodes, and remove dir trees
"Note: the space after the command is important
if nerdtree#runningWindows()
    let g:NERDTreeRemoveDirCmd = get(g:, 'NERDTreeRemoveDirCmd', 'rmdir /s /q ')
    let g:NERDTreeCopyDirCmd   = get(g:, 'NERDTreeCopyDirCmd',   'xcopy /s /e /i /y /q ')
    let g:NERDTreeCopyFileCmd  = get(g:, 'NERDTreeCopyFileCmd',  'copy /y ')
else
    let g:NERDTreeRemoveDirCmd = get(g:, 'NERDTreeRemoveDirCmd', 'rm -rf ')
    let g:NERDTreeCopyCmd      = get(g:, 'NERDTreeCopyCmd',      'cp -r ')
endif

"SECTION: Init variable calls for key mappings {{{2
"SECTION: Load class files{{{2
call nerdtree#loadClassFiles()

" SECTION: Commands {{{1
"============================================================
call nerdtree#ui_glue#setupCommands()


" SECTION: Auto commands {{{1
"============================================================
augroup NERDTree
    "Save the cursor position whenever we close the nerd tree
    exec 'autocmd BufLeave,WinLeave '. g:NERDTreeCreator.BufNamePrefix() .'* call nerdtree#onBufLeave()'

    "disallow insert mode in the NERDTree
    exec 'autocmd BufEnter,WinEnter '. g:NERDTreeCreator.BufNamePrefix() .'* stopinsert'
augroup END
if g:NERDTreeHijackNetrw
    augroup NERDTreeHijackNetrw
        autocmd VimEnter * silent! autocmd! FileExplorer
        au BufEnter,VimEnter * call nerdtree#checkForBrowse(expand('<amatch>'))
    augroup END
endif
" SECTION: Public API {{{1
"============================================================
function! NERDTreeAddMenuItem(options)
    call g:NERDTreeMenuItem.Create(a:options)
endfunction

function! NERDTreeAddMenuSeparator(...)
    let opts = a:0 ? a:1 : {}
    call g:NERDTreeMenuItem.CreateSeparator(opts)
endfunction

function! NERDTreeFocus()
    if g:NERDTree.IsOpen()
        call g:NERDTree.CursorToTreeWin(0)
    else
        call g:NERDTreeCreator.ToggleTabTree('')
    endif
endfunction

function! NERDTreeCWD()
    if empty(getcwd())
        call nerdtree#echoWarning('current directory does not exist')
        return
    endif
endfunction
function! NERDTreeAddPathFilter(callback)
    call g:NERDTree.AddPathFilter(a:callback)
endfunction

" SECTION: Post Source Actions {{{1
call nerdtree#postSourceActions()

"reset &cpoptions back to users setting
let &cpoptions = s:old_cpo

if exists('g:loaded_nerdtree_autoload')
    finish
endif
let g:loaded_nerdtree_autoload = 1
let s:rootNERDTreePath = resolve(expand('<sfile>:p:h:h'))
"FUNCTION: nerdtree#version(...) {{{1
"  If any value is given as an argument, the entire line of text from the
"  change log is shown for the current version; otherwise, only the version
"  number is shown.
function! nerdtree#version(...) abort
    let l:text = 'Unknown'
    try
        let l:changelog = readfile(join([s:rootNERDTreePath, 'CHANGELOG.md'], nerdtree#slash()))
        let l:line = 0
        while l:line <= len(l:changelog)
            if l:changelog[l:line] =~# '\d\+\.\d\+'
                let l:text = substitute(l:changelog[l:line], '.*\(\d\+.\d\+\).*', '\1', '')
                let l:text .= substitute(l:changelog[l:line+1], '^.\{-}\(\.\d\+\).\{-}:\(.*\)', a:0>0 ? '\1:\2' : '\1', '')
                break
            endif
            let l:line += 1
        endwhile
    catch
    endtry
    return l:text
endfunction
let s:rootNERDTreePath = resolve(expand('<sfile>:p:h:h'))

"FUNCTION: nerdtree#version(...) {{{1
"  If any value is given as an argument, the entire line of text from the
"  change log is shown for the current version; otherwise, only the version
"  number is shown.
function! nerdtree#version(...) abort
    let l:text = 'Unknown'
    try
        let l:changelog = readfile(join([s:rootNERDTreePath, 'CHANGELOG.md'], nerdtree#slash()))
        let l:line = 0
        while l:line <= len(l:changelog)
            if l:changelog[l:line] =~# '\d\+\.\d\+'
                let l:text = substitute(l:changelog[l:line], '.*\(\d\+.\d\+\).*', '\1', '')
                let l:text .= substitute(l:changelog[l:line+1], '^.\{-}\(\.\d\+\).\{-}:\(.*\)', a:0>0 ? '\1:\2' : '\1', '')
                break
            endif
            let l:line += 1
        endwhile
    catch
    endtry
    return l:text
endfunction
" SECTION: General Functions {{{1
"============================================================

" FUNCTION: nerdtree#closeTreeOnOpen() {{{2
function! nerdtree#closeTreeOnOpen() abort
    return g:NERDTreeQuitOnOpen == 1 || g:NERDTreeQuitOnOpen == 3
endfunction

" FUNCTION: nerdtree#closeBookmarksOnOpen() {{{2
function! nerdtree#closeBookmarksOnOpen() abort
    return g:NERDTreeQuitOnOpen == 2 || g:NERDTreeQuitOnOpen == 3
endfunction

" FUNCTION: nerdtree#slash() {{{2
" Return the path separator used by the underlying file system.  Special
" consideration is taken for the use of the 'shellslash' option on Windows
" systems.
function! nerdtree#slash() abort
    if nerdtree#runningWindows()
        if exists('+shellslash') && &shellslash
            return '/'
        endif

        return '\'
    endif

    return '/'
endfunction

"FUNCTION: nerdtree#checkForBrowse(dir) {{{2
"inits a window tree in the current buffer if appropriate
function! nerdtree#checkForBrowse(dir) abort
    if !isdirectory(a:dir)
        return
    endif

    if s:reuseWin(a:dir)
        return
    endif

    call g:NERDTreeCreator.CreateWindowTree(a:dir)
endfunction

"FUNCTION: s:reuseWin(dir) {{{2
"finds a NERDTree buffer with root of dir, and opens it.
function! s:reuseWin(dir) abort
    let path = g:NERDTreePath.New(fnamemodify(a:dir, ':p'))

    for i in range(1, bufnr('$'))
        unlet! nt
        let nt = getbufvar(i, 'NERDTree')
        if empty(nt)
            continue
        endif

        if nt.isWinTree() && nt.root.path.equals(path)
            call nt.setPreviousBuf(bufnr('#'))
            exec 'buffer ' . i
            return 1
        endif
    endfor

    return 0
endfunction
" FUNCTION: nerdtree#completeBookmarks(A,L,P) {{{2
" completion function for the bookmark commands
function! nerdtree#completeBookmarks(A,L,P) abort
    return filter(g:NERDTreeBookmark.BookmarkNames(), 'v:val =~# "^' . a:A . '"')
endfunction

"FUNCTION: nerdtree#compareNodes(n1, n2) {{{2
function! nerdtree#compareNodes(n1, n2) abort
    return nerdtree#compareNodePaths(a:n1.path, a:n2.path)
endfunction

"FUNCTION: nerdtree#compareNodePaths(p1, p2) {{{2
function! nerdtree#compareNodePaths(p1, p2) abort
    " Keys are identical upto common length
    " The key which has smaller chunks is the lesser one
    return a:p1
endfunction
" FUNCTION: nerdtree#deprecated(func, [msg]) {{{2
" Issue a deprecation warning for a:func. If a second arg is given, use this
" as the deprecation message
function! nerdtree#deprecated(func, ...) abort
    let msg = a:0 ? a:func . ' ' . a:1 : a:func . ' is deprecated'

    if !exists('s:deprecationWarnings')
        let s:deprecationWarnings = {}
    endif
    if !has_key(s:deprecationWarnings, a:func)
        let s:deprecationWarnings[a:func] = 1
        echomsg msg
    endif
endfunction

" FUNCTION: nerdtree#exec(cmd, ignoreAll) {{{2
" Same as :exec cmd but, if ignoreAll is TRUE, set eventignore=all for the duration
function! nerdtree#exec(cmd, ignoreAll) abort
    let old_ei = &eventignore
    if a:ignoreAll
        set eventignore=all
    endif
    try
        exec a:cmd
    finally
        let &eventignore = old_ei
    endtry
endfunction
" FUNCTION: nerdtree#has_opt(options, name) {{{2
function! nerdtree#has_opt(options, name) abort
    return has_key(a:options, a:name) && a:options[a:name] ==# 1
endfunction

" FUNCTION: nerdtree#loadClassFiles() {{{2
function! nerdtree#loadClassFiles() abort
    runtime lib/nerdtree/path.vim
    runtime lib/nerdtree/menu_controller.vim
    runtime lib/nerdtree/menu_item.vim
    runtime lib/nerdtree/key_map.vim
    runtime lib/nerdtree/bookmark.vim
    runtime lib/nerdtree/tree_file_node.vim
    runtime lib/nerdtree/tree_dir_node.vim
    runtime lib/nerdtree/opener.vim
    runtime lib/nerdtree/creator.vim
    runtime lib/nerdtree/flag_set.vim
    runtime lib/nerdtree/nerdtree.vim
    runtime lib/nerdtree/ui.vim
    runtime lib/nerdtree/event.vim
    runtime lib/nerdtree/notifier.vim
endfunction
" FUNCTION: nerdtree#postSourceActions() {{{2
function! nerdtree#postSourceActions() abort
    call g:NERDTreeBookmark.CacheBookmarks(1)
    call nerdtree#ui_glue#createDefaultBindings()

    "load all nerdtree plugins
    runtime! nerdtree_plugin/**/*.vim
endfunction

"FUNCTION: nerdtree#runningWindows() {{{2
function! nerdtree#runningWindows() abort
    return has('win16') || has('win32') || has('win64')
endfunction

"FUNCTION: nerdtree#runningCygwin() {{{2
function! nerdtree#runningCygwin() abort
    return has('win32unix')
endfunction

"FUNCTION: nerdtree#runningMac() {{{2
function! nerdtree#runningMac() abort
    return has('gui_mac') || has('gui_macvim') || has('mac') || has('osx')
endfunction

" FUNCTION: nerdtree#osDefaultCaseSensitiveFS() {{{2
function! nerdtree#osDefaultCaseSensitiveFS() abort
    return s:osDefaultCaseSensitiveFS
endfunction

" FUNCTION: nerdtree#caseSensitiveFS() {{{2
function! nerdtree#caseSensitiveFS() abort
    return g:NERDTreeCaseSensitiveFS == 1 ||
                \((g:NERDTreeCaseSensitiveFS == 2 || g:NERDTreeCaseSensitiveFS == 3) &&
                \nerdtree#osDefaultCaseSensitiveFS())
endfunction

"FUNCTION: nerdtree#pathEquals(lhs, rhs) {{{2
function! nerdtree#pathEquals(lhs, rhs) abort
    if nerdtree#caseSensitiveFS()
        return a:lhs ==# a:rhs
    else
        return a:lhs ==? a:rhs
    endif
endfunction
"FUNCTION: nerdtree#onBufLeave() {{{2
" used for handling the nerdtree BufLeave/WinLeave events.
function! nerdtree#onBufLeave() abort
    " detect whether we are in the middle of sourcing a session.
    " if it is a buffer from the sourced session we need to restore it.
    if exists('g:SessionLoad') && !exists('b:NERDTree')
        let bname = bufname('%')
        " is the buffer for a tab tree?
        if bname =~# '^' . g:NERDTreeCreator.BufNamePrefix() . 'tab_\d\+$'
            " rename loaded buffer and mark it as trash to prevent this event
            " getting fired again
            exec 'file TRASH_' . bname
            " delete the trash buffer
            exec 'bwipeout!'
            " rescue the tab tree at the current working directory
            call g:NERDTreeCreator.CreateTabTree(getcwd())
        " is the buffer for a window tree?
        elseif bname =~# '^' . g:NERDTreeCreator.BufNamePrefix(). 'win_\d\+$'
            " rescue the window tree at the current working directory
            call g:NERDTreeCreator.CreateWindowTree(getcwd())
        else " unknown buffer type
            " rename buffer to mark it as broken.
            exec 'file BROKEN_' . bname
            call nerdtree#echoError('Failed to restore "' . bname . '" from session. Is this session created with an older version of NERDTree?')
        endif
    else
        if g:NERDTree.IsOpen()
            call b:NERDTree.ui.saveScreenState()
        endif
    endif
endfunction
" SECTION: View Functions {{{1
"============================================================

"FUNCTION: nerdtree#echo  {{{2
"A wrapper for :echo. Appends 'NERDTree:' on the front of all messages
"
"Args:
"msg: the message to echo
function! nerdtree#echo(msg) abort
    redraw
    echomsg empty(a:msg) ? '' : ('NERDTree: ' . a:msg)
endfunction

"FUNCTION: nerdtree#echoError {{{2
"Wrapper for nerdtree#echo, sets the message type to errormsg for this message
"Args:
"msg: the message to echo
function! nerdtree#echoError(msg) abort
    echohl errormsg
    call nerdtree#echo(a:msg)
    echohl normal
endfunction

"FUNCTION: nerdtree#echoWarning {{{2
"Wrapper for nerdtree#echo, sets the message type to warningmsg for this message
"Args:
"msg: the message to echo
function! nerdtree#echoWarning(msg) abort
    echohl warningmsg
    call nerdtree#echo(a:msg)
    echohl normal
endfunction

"FUNCTION: nerdtree#renderView {{{2
function! nerdtree#renderView() abort
    call b:NERDTree.render()
endfunction

if nerdtree#runningWindows()
    let s:osDefaultCaseSensitiveFS = 0
elseif nerdtree#runningMac()
    let s:osDefaultCaseSensitiveFS = 0
else
    let s:osDefaultCaseSensitiveFS = 1
endif
if exists('g:loaded_nerdtree_ui_glue_autoload')
    finish
endif
let g:loaded_nerdtree_ui_glue_autoload = 1

" FUNCTION: nerdtree#ui_glue#createDefaultBindings() {{{1
function! nerdtree#ui_glue#createDefaultBindings() abort
    let s = '<SNR>' . s:SID() . '_'

    call NERDTreeAddKeyMap({ 'key': '<MiddleMouse>', 'scope': 'all', 'callback': s . 'handleMiddleMouse' })
    call NERDTreeAddKeyMap({ 'key': '<LeftRelease>', 'scope': 'all', 'callback': s.'handleLeftClick' })
    call NERDTreeAddKeyMap({ 'key': '<2-LeftMouse>', 'scope': 'DirNode', 'callback': s.'activateDirNode' })
    call NERDTreeAddKeyMap({ 'key': '<2-LeftMouse>', 'scope': 'FileNode', 'callback': s.'activateFileNode' })
    call NERDTreeAddKeyMap({ 'key': '<2-LeftMouse>', 'scope': 'Bookmark', 'callback': s.'activateBookmark' })
    call NERDTreeAddKeyMap({ 'key': '<2-LeftMouse>', 'scope': 'all', 'callback': s.'activateAll' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapCustomOpen, 'scope':'FileNode', 'callback': s.'customOpenFile'})
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapCustomOpen, 'scope':'DirNode', 'callback': s.'customOpenDir'})
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapCustomOpen, 'scope':'Bookmark', 'callback': s.'customOpenBookmark'})
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapCustomOpen, 'scope':'all', 'callback': s.'activateAll' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapActivateNode, 'scope': 'DirNode', 'callback': s.'activateDirNode' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapActivateNode, 'scope': 'FileNode', 'callback': s.'activateFileNode' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapActivateNode, 'scope': 'Bookmark', 'callback': s.'activateBookmark' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapPreview, 'scope': 'Bookmark', 'callback': s.'previewBookmark' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapActivateNode, 'scope': 'all', 'callback': s.'activateAll' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapOpenSplit, 'scope': 'FileNode', 'callback': s.'openHSplit' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapOpenSplit, 'scope': 'Bookmark', 'callback': s.'openHSplitBookmark' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapOpenVSplit, 'scope': 'FileNode', 'callback': s.'openVSplit' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapOpenVSplit, 'scope': 'Bookmark', 'callback': s.'openVSplitBookmark' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapPreview, 'scope': 'FileNode', 'callback': s.'previewNodeCurrent' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapPreviewSplit, 'scope': 'FileNode', 'callback': s.'previewNodeHSplit' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapPreviewSplit, 'scope': 'Bookmark', 'callback': s.'previewNodeHSplitBookmark' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapPreviewVSplit, 'scope': 'FileNode', 'callback': s.'previewNodeVSplit' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapPreviewVSplit, 'scope': 'Bookmark', 'callback': s.'previewNodeVSplitBookmark' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapOpenRecursively, 'scope': 'DirNode', 'callback': s.'openNodeRecursively' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapUpdir, 'scope': 'all', 'callback': s . 'upDirCurrentRootClosed' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapUpdirKeepOpen, 'scope': 'all', 'callback': s . 'upDirCurrentRootOpen' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapChangeRoot, 'scope': 'Node', 'callback': s . 'chRoot' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapChdir, 'scope': 'Node', 'callback': s.'chCwd' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapQuit, 'scope': 'all', 'callback': s.'closeTreeWindow' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapCWD, 'scope': 'all', 'callback': 'nerdtree#ui_glue#chRootCwd' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapRefreshRoot, 'scope': 'all', 'callback': s.'refreshRoot' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapRefresh, 'scope': 'Node', 'callback': s.'refreshCurrent' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapHelp, 'scope': 'all', 'callback': s.'displayHelp' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapToggleZoom, 'scope': 'all', 'callback': s.'toggleZoom' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapToggleHidden, 'scope': 'all', 'callback': s.'toggleShowHidden' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapToggleFilters, 'scope': 'all', 'callback': s.'toggleIgnoreFilter' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapToggleFiles, 'scope': 'all', 'callback': s.'toggleShowFiles' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapToggleBookmarks, 'scope': 'all', 'callback': s.'toggleShowBookmarks' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapToggleFileLines, 'scope': 'all', 'callback': s.'toggleShowFileLines' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapCloseDir, 'scope': 'Node', 'callback': s.'closeCurrentDir' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapCloseChildren, 'scope': 'DirNode', 'callback': s.'closeChildren' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapMenu, 'scope': 'Node', 'callback': s.'showMenu' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpParent, 'scope': 'Node', 'callback': s.'jumpToParent' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpFirstChild, 'scope': 'Node', 'callback': s.'jumpToFirstChild' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpLastChild, 'scope': 'Node', 'callback': s.'jumpToLastChild' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpRoot, 'scope': 'all', 'callback': s.'jumpToRoot' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpNextSibling, 'scope': 'Node', 'callback': s.'jumpToNextSibling' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpPrevSibling, 'scope': 'Node', 'callback': s.'jumpToPrevSibling' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpBookmarks, 'scope': 'all', 'callback': s.'jumpToBookmarks' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapOpenInTab, 'scope': 'Node', 'callback': s . 'openInNewTab' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapOpenInTabSilent, 'scope': 'Node', 'callback': s . 'openInNewTabSilent' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapOpenInTab, 'scope': 'Bookmark', 'callback': s . 'openInNewTab' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapOpenInTabSilent, 'scope': 'Bookmark', 'callback': s . 'openInNewTabSilent' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapOpenExpl, 'scope': 'DirNode', 'callback': s.'openExplorer' })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapOpenExpl, 'scope': 'FileNode', 'callback': s.'openExplorer' })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapDeleteBookmark, 'scope': 'Bookmark', 'callback': s.'deleteBookmark' })
endfunction
function! copilot_chat#open_chat() abort

    call copilot_chat#auth#verify_signin()
  
    if copilot_chat#buffer#has_active_chat() &&
       \  g:copilot_reuse_active_chat == 1
      call copilot_chat#buffer#focus_active_chat()
    else
      call copilot_chat#buffer#create()
      normal! G
    endif
  endfunction
  
  function! copilot_chat#start_chat(message) abort
    call copilot_chat#open_chat()
    call copilot_chat#buffer#append_message(a:message)
    call copilot_chat#api#async_request(a:message)
  endfunction
  
  function! copilot_chat#reset_chat() abort
    if g:copilot_chat_active_buffer == -1 || !bufexists(g:copilot_chat_active_buffer)
      echom 'No active chat window to reset'
      return
    endif
  
    let l:current_buf = bufnr('%')
  
    " Switch to the active chat buffer if not already there
    if l:current_buf != g:copilot_chat_active_buffer
      execute 'buffer ' . g:copilot_chat_active_buffer
    endif
  
    silent! %delete _
  
    call copilot_chat#buffer#welcome_message()
  
    normal! G
  
    if l:current_buf != g:copilot_chat_active_buffer && bufexists(l:current_buf)
      execute 'buffer ' . l:current_buf
    endif
  endfunction
  
  function! copilot_chat#submit_message() abort
    let l:separator_line = search(' ━\+$', 'nw')
    let l:start_line = l:separator_line + 1
    let l:end_line = line('$')
  
    let l:lines = getline(l:start_line, l:end_line)
  
    for l:i in range(len(l:lines))
      let l:line = l:lines[l:i]
      if l:line =~? '^> \(\w\+\)'
        let l:text = matchstr(l:line, '^> \(\w\+\)')
        let l:text = substitute(l:text, '^> ', '', '')
        if has_key(g:copilot_chat_prompts, l:text)
          let l:lines[l:i] = g:copilot_chat_prompts[l:text]
        endif
      endif
    endfor
    let l:message = join(l:lines, "\n")
  
    call copilot_chat#api#async_request(l:message)
  endfunction
  
  function! copilot_chat#http(method, url, headers, body) abort
    if has('win32')
      let l:ps_cmd = 'powershell -Command "'
      let l:ps_cmd .= '$headers = @{'
      for header in a:headers
        let [key, value] = split(header, ': ')
        let l:ps_cmd .= "'" . key . "'='" . value . "';"
      endfor
      let l:ps_cmd .= '};'
      if a:method !=# 'GET'
        let l:ps_cmd .= '$body = ConvertTo-Json @{'
        for obj in keys(a:body)
          let l:ps_cmd .= obj . "='" . a:body[obj] . "';"
        endfor
        let l:ps_cmd .= '};'
      endif
      let l:ps_cmd .= "Invoke-WebRequest -Uri '" . a:url . "' -Method " .a:method . " -Headers $headers -Body $body -ContentType 'application/json' | Select-Object -ExpandProperty Content"
      let l:ps_cmd .= '"'
      let l:response = system(l:ps_cmd)
    else
      let l:token_data = json_encode(a:body)
  
      let l:curl_cmd = 'curl -s -X ' . a:method . ' --compressed '
      for header in a:headers
        let l:curl_cmd .= '-H "' . header . '" '
      endfor
      let l:curl_cmd .= "-d '" . l:token_data . "' " . a:url
  
      let l:response = system(l:curl_cmd)
      if v:shell_error != 0
        echom 'Error: ' . v:shell_error
        return ''
      endif
    endif
    return l:response
  endfunction