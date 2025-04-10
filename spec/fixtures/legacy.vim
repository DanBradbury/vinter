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
let g:NERDTreeAutoCenterThreshold   = get(g:, 'NERDTreeAutoCenterThreshold',   3)
let g:NERDTreeCaseSensitiveFS       = get(g:, 'NERDTreeCaseSensitiveFS',       2)
let g:NERDTreeCaseSensitiveSort     = get(g:, 'NERDTreeCaseSensitiveSort',     0)
let g:NERDTreeNaturalSort           = get(g:, 'NERDTreeNaturalSort',           0)
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
elseif (g:NERDTreeDirArrowExpandable ==# "\u00a0" || g:NERDTreeDirArrowCollapsible ==# "\u00a0")
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
let g:NERDTreeMapCustomOpen      = get(g:, 'NERDTreeMapCustomOpen',      '<CR>')
let g:NERDTreeMapJumpBookmarks   = get(g:, 'NERDTreeMapJumpBookmarks',   'gb')
let g:NERDTreeMapActivateNode    = get(g:, 'NERDTreeMapActivateNode',    'o')
let g:NERDTreeMapChangeRoot      = get(g:, 'NERDTreeMapChangeRoot',      'C')
let g:NERDTreeMapChdir           = get(g:, 'NERDTreeMapChdir',           'cd')
let g:NERDTreeMapCloseChildren   = get(g:, 'NERDTreeMapCloseChildren',   'X')
let g:NERDTreeMapCloseDir        = get(g:, 'NERDTreeMapCloseDir',        'x')
let g:NERDTreeMapDeleteBookmark  = get(g:, 'NERDTreeMapDeleteBookmark',  'D')
let g:NERDTreeMapMenu            = get(g:, 'NERDTreeMapMenu',            'm')
let g:NERDTreeMapHelp            = get(g:, 'NERDTreeMapHelp',            '?')
let g:NERDTreeMapJumpFirstChild  = get(g:, 'NERDTreeMapJumpFirstChild',  'K')
let g:NERDTreeMapJumpLastChild   = get(g:, 'NERDTreeMapJumpLastChild',   'J')
let g:NERDTreeMapJumpNextSibling = get(g:, 'NERDTreeMapJumpNextSibling', '<C-j>')
let g:NERDTreeMapJumpParent      = get(g:, 'NERDTreeMapJumpParent',      'p')
let g:NERDTreeMapJumpPrevSibling = get(g:, 'NERDTreeMapJumpPrevSibling', '<C-k>')
let g:NERDTreeMapJumpRoot        = get(g:, 'NERDTreeMapJumpRoot',        'P')
let g:NERDTreeMapOpenExpl        = get(g:, 'NERDTreeMapOpenExpl',        'e')
let g:NERDTreeMapOpenInTab       = get(g:, 'NERDTreeMapOpenInTab',       't')
let g:NERDTreeMapOpenInTabSilent = get(g:, 'NERDTreeMapOpenInTabSilent', 'T')
let g:NERDTreeMapOpenRecursively = get(g:, 'NERDTreeMapOpenRecursively', 'O')
let g:NERDTreeMapOpenSplit       = get(g:, 'NERDTreeMapOpenSplit',       'i')
let g:NERDTreeMapOpenVSplit      = get(g:, 'NERDTreeMapOpenVSplit',      's')
let g:NERDTreeMapPreview         = get(g:, 'NERDTreeMapPreview',         'g'.NERDTreeMapActivateNode)
let g:NERDTreeMapPreviewSplit    = get(g:, 'NERDTreeMapPreviewSplit',    'g'.NERDTreeMapOpenSplit)
let g:NERDTreeMapPreviewVSplit   = get(g:, 'NERDTreeMapPreviewVSplit',   'g'.NERDTreeMapOpenVSplit)
let g:NERDTreeMapQuit            = get(g:, 'NERDTreeMapQuit',            'q')
let g:NERDTreeMapRefresh         = get(g:, 'NERDTreeMapRefresh',         'r')
let g:NERDTreeMapRefreshRoot     = get(g:, 'NERDTreeMapRefreshRoot',     'R')
let g:NERDTreeMapToggleBookmarks = get(g:, 'NERDTreeMapToggleBookmarks', 'B')
let g:NERDTreeMapToggleFiles     = get(g:, 'NERDTreeMapToggleFiles',     'F')
let g:NERDTreeMapToggleFilters   = get(g:, 'NERDTreeMapToggleFilters',   'f')
let g:NERDTreeMapToggleHidden    = get(g:, 'NERDTreeMapToggleHidden',    'I')
let g:NERDTreeMapToggleFileLines = get(g:, 'NERDTreeMapToggleFileLines', 'FL')
let g:NERDTreeMapToggleZoom      = get(g:, 'NERDTreeMapToggleZoom',      'A')
let g:NERDTreeMapUpdir           = get(g:, 'NERDTreeMapUpdir',           'u')
let g:NERDTreeMapUpdirKeepOpen   = get(g:, 'NERDTreeMapUpdirKeepOpen',   'U')
let g:NERDTreeMapCWD             = get(g:, 'NERDTreeMapCWD',             'CD')
let g:NERDTreeMenuDown           = get(g:, 'NERDTreeMenuDown',           'j')
let g:NERDTreeMenuUp             = get(g:, 'NERDTreeMenuUp',             'k')

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

if g:NERDTreeChDirMode ==# 3
    augroup NERDTreeChDirOnTabSwitch
        autocmd TabEnter * if g:NERDTree.ExistsForTab()|call g:NERDTree.ForCurrentTab().getRoot().path.changeToDir()|endif
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

function! NERDTreeAddSubmenu(options)
    return g:NERDTreeMenuItem.Create(a:options)
endfunction

function! NERDTreeAddKeyMap(options)
    call g:NERDTreeKeyMap.Create(a:options)
endfunction

function! NERDTreeRender()
    call nerdtree#renderView()
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

    try
        let l:cwdPath = g:NERDTreePath.New(getcwd())
    catch /^NERDTree.InvalidArgumentsError/
        call nerdtree#echoWarning('current directory does not exist')
        return
    endtry

    call NERDTreeFocus()

    if b:NERDTree.root.path.equals(l:cwdPath)
        return
    endif

    let l:newRoot = g:NERDTreeFileNode.New(l:cwdPath, b:NERDTree)
    call b:NERDTree.changeRoot(l:newRoot)
    normal! ^
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
    let sortKey1 = a:p1.getSortKey()
    let sortKey2 = a:p2.getSortKey()
    let i = 0
    while i < min([len(sortKey1), len(sortKey2)])
        " Compare chunks upto common length.
        " If chunks have different type, the one which has
        " integer type is the lesser.
        if type(sortKey1[i]) == type(sortKey2[i])
            if sortKey1[i] <# sortKey2[i]
                return - 1
            elseif sortKey1[i] ># sortKey2[i]
                return 1
            endif
        elseif type(sortKey1[i]) == type(0)
            return -1
        elseif type(sortKey2[i]) == type(0)
            return 1
        endif
        let i += 1
    endwhile

    " Keys are identical upto common length.
    " The key which has smaller chunks is the lesser one.
    if len(sortKey1) < len(sortKey2)
        return -1
    elseif len(sortKey1) > len(sortKey2)
        return 1
    else
        return 0
    endif
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


"SECTION: Interface bindings {{{1
"============================================================

"FUNCTION: s:customOpenFile() {{{1
" Open file node with the 'custom' key, initially <CR>.
function! s:customOpenFile(node) abort
    call a:node.activate(s:initCustomOpenArgs().file)
endfunction

"FUNCTION: s:customOpenDir() {{{1
" Open directory node with the 'custom' key, initially <CR>.
function! s:customOpenDir(node) abort
    call s:activateDirNode(a:node, s:initCustomOpenArgs().dir)
endfunction

"FUNCTION: s:customOpenBookmark() {{{1
" Open bookmark node with the 'custom' key, initially <CR>.
function! s:customOpenBookmark(node) abort
    if a:node.path.isDirectory
        call a:node.activate(b:NERDTree, s:initCustomOpenArgs().dir)
    else
        call a:node.activate(b:NERDTree, s:initCustomOpenArgs().file)
    endif
endfunction

"FUNCTION: s:initCustomOpenArgs() {{{1
function! s:initCustomOpenArgs() abort
    let l:defaultOpenArgs = {'file': {'reuse': 'all', 'where': 'p', 'keepopen':!nerdtree#closeTreeOnOpen()}, 'dir': {}}
    try
        let g:NERDTreeCustomOpenArgs = get(g:, 'NERDTreeCustomOpenArgs', {})
        call  extend(g:NERDTreeCustomOpenArgs, l:defaultOpenArgs, 'keep')
    catch /^Vim(\a\+):E712:/
        call nerdtree#echoWarning('g:NERDTreeCustomOpenArgs is not set properly. Using default value.')
        let g:NERDTreeCustomOpenArgs = l:defaultOpenArgs
    finally
        return g:NERDTreeCustomOpenArgs
    endtry
endfunction

"FUNCTION: s:activateAll() {{{1
"handle the user activating the updir line
function! s:activateAll() abort
    if getline('.') ==# g:NERDTreeUI.UpDirLine()
        return nerdtree#ui_glue#upDir(0)
    endif
endfunction

" FUNCTION: s:activateDirNode(directoryNode, options) {{{1
" Open a directory with optional options
function! s:activateDirNode(directoryNode, ...) abort

    if a:directoryNode.isRoot() && a:directoryNode.isOpen
        call nerdtree#echo('cannot close tree root')
        return
    endif

    call a:directoryNode.activate((a:0 > 0) ? a:1 : {})
endfunction

"FUNCTION: s:activateFileNode() {{{1
"handle the user activating a tree node
function! s:activateFileNode(node) abort
    call a:node.activate({'reuse': 'all', 'where': 'p', 'keepopen': !nerdtree#closeTreeOnOpen()})
endfunction

"FUNCTION: s:activateBookmark(bookmark) {{{1
"handle the user activating a bookmark
function! s:activateBookmark(bm) abort
    call a:bm.activate(b:NERDTree, !a:bm.path.isDirectory ? {'where': 'p', 'keepopen': !nerdtree#closeTreeOnOpen()} : {})
endfunction

" FUNCTION: nerdtree#ui_glue#bookmarkNode(name) {{{1
" Associate the current node with the given name
function! nerdtree#ui_glue#bookmarkNode(...) abort
    let currentNode = g:NERDTreeFileNode.GetSelected()
    if currentNode !=# {}
        let name = a:1
        if empty(name)
            let name = currentNode.path.getLastPathComponent(0)
        endif
        try
            call currentNode.bookmark(name)
            call b:NERDTree.render()
        catch /^NERDTree.IllegalBookmarkNameError/
            call nerdtree#echo('bookmark names must not contain spaces')
        endtry
    else
        call nerdtree#echo('select a node first')
    endif
endfunction

" FUNCTION: s:chCwd(node) {{{1
function! s:chCwd(node) abort
    try
        call a:node.path.changeToDir()
    catch /^NERDTree.PathChangeError/
        call nerdtree#echoWarning('could not change cwd')
    endtry
endfunction

" FUNCTION: s:chRoot(node) {{{1
" changes the current root to the selected one
function! s:chRoot(node) abort
    call b:NERDTree.changeRoot(a:node)
endfunction

" FUNCTION: s:nerdtree#ui_glue#chRootCwd() {{{1
" Change the NERDTree root to match the current working directory.
function! nerdtree#ui_glue#chRootCwd() abort
    NERDTreeCWD
endfunction

" FUNCTION: nnerdtree#ui_glue#clearBookmarks(bookmarks) {{{1
function! nerdtree#ui_glue#clearBookmarks(bookmarks) abort
    if a:bookmarks ==# ''
        let currentNode = g:NERDTreeFileNode.GetSelected()
        if currentNode !=# {}
            call currentNode.clearBookmarks()
        endif
    else
        for name in split(a:bookmarks, ' ')
            let bookmark = g:NERDTreeBookmark.BookmarkFor(name)
            call bookmark.delete()
        endfor
    endif
    call b:NERDTree.root.refresh()
    call b:NERDTree.render()
endfunction

" FUNCTION: s:closeChildren(node) {{{1
" closes all childnodes of the current node
function! s:closeChildren(node) abort
    call a:node.closeChildren()
    call b:NERDTree.render()
    call a:node.putCursorHere(0, 0)
endfunction

" FUNCTION: s:closeCurrentDir(node) {{{1
" Close the parent directory of the current node.
function! s:closeCurrentDir(node) abort

    if a:node.isRoot()
        call nerdtree#echo('cannot close parent of tree root')
        return
    endif

    let l:parent = a:node.parent

    while l:parent.isCascadable()
        let l:parent = l:parent.parent
    endwhile

    if l:parent.isRoot()
        call nerdtree#echo('cannot close tree root')
        return
    endif

    call l:parent.close()
    call b:NERDTree.render()
    call l:parent.putCursorHere(0, 0)
endfunction

" FUNCTION: s:closeTreeWindow() {{{1
" close the tree window
function! s:closeTreeWindow() abort
    if b:NERDTree.isWinTree() && b:NERDTree.previousBuf() !=# -1
        exec 'buffer ' . b:NERDTree.previousBuf()
    else
        if winnr('$') > 1
            call g:NERDTree.Close()
        else
            call nerdtree#echo('Cannot close last window')
        endif
    endif
endfunction

" FUNCTION: s:deleteBookmark(bookmark) {{{1
" Prompt the user to confirm the deletion of the selected bookmark.
function! s:deleteBookmark(bookmark) abort
    let l:message = 'Delete the bookmark "' . a:bookmark.name
                \ . '" from the bookmark list?'

    let l:choices = "&Yes\n&No"

    echo | redraw
    let l:selection = confirm(l:message, l:choices, 1, 'Warning')

    if l:selection !=# 1
        call nerdtree#echo('bookmark not deleted')
        return
    endif

    try
        call a:bookmark.delete()
        silent call b:NERDTree.root.refresh()
        call b:NERDTree.render()
        echo | redraw
    catch /^NERDTree/
        call nerdtree#echoWarning('could not remove bookmark')
    endtry
endfunction

" FUNCTION: s:displayHelp() {{{1
" toggles the help display
function! s:displayHelp() abort
    call b:NERDTree.ui.toggleHelp()
    call b:NERDTree.render()
    call b:NERDTree.ui.centerView()
endfunction

" FUNCTION: s:findAndRevealPath(pathStr) {{{1
function! s:findAndRevealPath(pathStr) abort
    let l:pathStr = !empty(a:pathStr) ? a:pathStr : expand('%:p')
    let l:revealOpts = {}

    if empty(l:pathStr)
        call nerdtree#echoWarning('no file for the current buffer')
        return
    endif

    if !filereadable(l:pathStr)
        let l:pathStr = fnamemodify(l:pathStr, ':h')
        let l:revealOpts['open'] = 1
    endif

    try
        let l:pathStr = g:NERDTreePath.Resolve(l:pathStr)
        let l:pathObj = g:NERDTreePath.New(l:pathStr)
    catch /^NERDTree.InvalidArgumentsError/
        call nerdtree#echoWarning('invalid path')
        return
    endtry

    if !g:NERDTree.ExistsForTab()
        try
            let l:cwd = g:NERDTreePath.New(getcwd())
        catch /^NERDTree.InvalidArgumentsError/
            call nerdtree#echo('current directory does not exist.')
            let l:cwd = l:pathObj.getParent()
        endtry

        if l:pathObj.isUnder(l:cwd)
            call g:NERDTreeCreator.CreateTabTree(l:cwd.str())
        else
            call g:NERDTreeCreator.CreateTabTree(l:pathObj.getParent().str())
        endif
    else
        NERDTreeFocus

        if !l:pathObj.isUnder(b:NERDTree.root.path)
            call s:chRoot(g:NERDTreeDirNode.New(l:pathObj.getParent(), b:NERDTree))
        endif
    endif

    if l:pathObj.isHiddenUnder(b:NERDTree.root.path)
        call b:NERDTree.ui.setShowHidden(1)
    endif

    let l:node = b:NERDTree.root.reveal(l:pathObj, l:revealOpts)
    call b:NERDTree.render()
    call l:node.putCursorHere(1, 0)
endfunction

"FUNCTION: s:handleLeftClick() {{{1
"Checks if the click should open the current node
function! s:handleLeftClick() abort
    let currentNode = g:NERDTreeFileNode.GetSelected()
    if currentNode !=# {}

        "the dir arrows are multibyte chars, and vim's string functions only
        "deal with single bytes - so split the line up with the hack below and
        "take the line substring manually
        let line = split(getline(line('.')), '\zs')
        let startToCur = ''
        for i in range(0,len(line)-1)
            let startToCur .= line[i]
        endfor

        if currentNode.path.isDirectory
            if startToCur =~# g:NERDTreeUI.MarkupReg() && startToCur =~# '[+~'.g:NERDTreeDirArrowExpandable.g:NERDTreeDirArrowCollapsible.'] \?$'
                call currentNode.activate()
                return
            endif
        endif

        if (g:NERDTreeMouseMode ==# 2 && currentNode.path.isDirectory) || g:NERDTreeMouseMode ==# 3
            let char = strpart(startToCur, strlen(startToCur)-1, 1)
            if char !~# g:NERDTreeUI.MarkupReg()
                if currentNode.path.isDirectory
                    call currentNode.activate()
                else
                    call currentNode.activate({'reuse': 'all', 'where': 'p', 'keepopen':!nerdtree#closeTreeOnOpen()})
                endif
                return
            endif
        endif
    endif
endfunction

" FUNCTION: s:handleMiddleMouse() {{{1
function! s:handleMiddleMouse() abort

    " A middle mouse click does not automatically position the cursor as one
    " would expect. Forcing the execution of a regular left mouse click here
    " fixes this problem.
    execute "normal! \<LeftMouse>"

    let l:currentNode = g:NERDTreeFileNode.GetSelected()
    if empty(l:currentNode)
        call nerdtree#echoError('use the pointer to select a node')
        return
    endif

    if l:currentNode.path.isDirectory
        call l:currentNode.openExplorer()
    else
        call l:currentNode.open({'where': 'h'})
    endif
endfunction

" FUNCTION: nerdtree#ui_glue#invokeKeyMap(key) {{{1
"this is needed since I cant figure out how to invoke dict functions from a
"key map
function! nerdtree#ui_glue#invokeKeyMap(key) abort
    call g:NERDTreeKeyMap.Invoke(a:key)
endfunction

" FUNCTION: s:jumpToFirstChild(node) {{{1
function! s:jumpToFirstChild(node) abort
    call s:jumpToChild(a:node, 0)
endfunction

" FUNCTION: s:jumpToLastChild(node) {{{1
function! s:jumpToLastChild(node) abort
    call s:jumpToChild(a:node, 1)
endfunction

" FUNCTION: s:jumpToChild(node, last) {{{1
" Jump to the first or last child node at the same file system level.
"
" Args:
" node: the node on which the cursor currently sits
" last: 1 (true) if jumping to last child, 0 (false) if jumping to first
function! s:jumpToChild(node, last) abort
    let l:node = a:node.path.isDirectory ? a:node.getCascadeRoot() : a:node

    if l:node.isRoot()
        return
    endif

    let l:parent = l:node.parent
    let l:children = l:parent.getVisibleChildren()

    let l:target = a:last ? l:children[len(l:children) - 1] : l:children[0]

    call l:target.putCursorHere(1, 0)
    call b:NERDTree.ui.centerView()
endfunction

" FUNCTION: s:jumpToParent(node) {{{1
" Move the cursor to the parent of the specified node.  For a cascade, move to
" the parent of the cascade's first node.  At the root node, do nothing.
function! s:jumpToParent(node) abort
    let l:node = a:node.path.isDirectory ? a:node.getCascadeRoot() : a:node

    if l:node.isRoot()
        return
    endif

    if empty(l:node.parent)
        call nerdtree#echo('could not jump to parent node')
        return
    endif

    call l:node.parent.putCursorHere(1, 0)
    call b:NERDTree.ui.centerView()
endfunction

" FUNCTION: s:jumpToRoot() {{{1
" moves the cursor to the root node
function! s:jumpToRoot() abort
    call b:NERDTree.root.putCursorHere(1, 0)
    call b:NERDTree.ui.centerView()
endfunction

" FUNCTION: s:jumpToNextSibling(node) {{{1
function! s:jumpToNextSibling(node) abort
    call s:jumpToSibling(a:node, 1)
endfunction

" FUNCTION: s:jumpToPrevSibling(node) {{{1
function! s:jumpToPrevSibling(node) abort
    call s:jumpToSibling(a:node, 0)
endfunction

" FUNCTION: s:jumpToSibling(node, forward) {{{1
" Move the cursor to the next or previous node at the same file system level.
"
" Args:
" node: the node on which the cursor currently sits
" forward: 0 to jump to previous sibling, 1 to jump to next sibling
function! s:jumpToSibling(node, forward) abort
    let l:node = a:node.path.isDirectory ? a:node.getCascadeRoot() : a:node
    let l:sibling = l:node.findSibling(a:forward)

    if empty(l:sibling)
        return
    endif

    call l:sibling.putCursorHere(1, 0)
    call b:NERDTree.ui.centerView()
endfunction

" FUNCTION: s:jumpToBookmarks() {{{1
" moves the cursor to the bookmark table
function! s:jumpToBookmarks() abort
    try
        if b:NERDTree.ui.getShowBookmarks()
            call g:NERDTree.CursorToBookmarkTable()
        else
            call b:NERDTree.ui.setShowBookmarks(1)
        endif
    catch /^NERDTree/
        call nerdtree#echoError('Failed to jump to the bookmark table')
        return
    endtry
endfunction

" FUNCTION: nerdtree#ui_glue#openBookmark(name) {{{1
" Open the Bookmark that has the specified name. This function provides the
" implementation for the :OpenBookmark command.
function! nerdtree#ui_glue#openBookmark(name) abort
    try
        let l:bookmark = g:NERDTreeBookmark.BookmarkFor(a:name)
    catch /^NERDTree.BookmarkNotFoundError/
        call nerdtree#echoError('bookmark "' . a:name . '" not found')
        return
    endtry
    if l:bookmark.path.isDirectory
        call l:bookmark.open(b:NERDTree)
        return
    endif

    call l:bookmark.open(b:NERDTree, s:initCustomOpenArgs().file)
endfunction

" FUNCTION: s:openHSplit(target) {{{1
function! s:openHSplit(target) abort
    call a:target.activate({'where': 'h', 'keepopen': !nerdtree#closeTreeOnOpen()})
endfunction

" FUNCTION: s:openVSplit(target) {{{1
function! s:openVSplit(target) abort
    call a:target.activate({'where': 'v', 'keepopen': !nerdtree#closeTreeOnOpen()})
endfunction

"FUNCTION: s:openHSplitBookmark(bookmark) {{{1
"handle the user activating a bookmark
function! s:openHSplitBookmark(bm) abort
    call a:bm.activate(b:NERDTree, !a:bm.path.isDirectory ? {'where': 'h', 'keepopen': !nerdtree#closeTreeOnOpen()} : {})
endfunction

"FUNCTION: s:openVSplitBookmark(bookmark) {{{1
"handle the user activating a bookmark
function! s:openVSplitBookmark(bm) abort
    call a:bm.activate(b:NERDTree, !a:bm.path.isDirectory ? {'where': 'v', 'keepopen': !nerdtree#closeTreeOnOpen()} : {})
endfunction

" FUNCTION: s:previewHSplitBookmark(bookmark) {{{1
function! s:previewNodeHSplitBookmark(bookmark) abort
    call a:bookmark.activate(b:NERDTree, !a:bookmark.path.isDirectory ? {'stay': 1, 'where': 'h', 'keepopen': 1} : {})
endfunction

" FUNCTION: s:previewVSplitBookmark(bookmark) {{{1
function! s:previewNodeVSplitBookmark(bookmark) abort
    call a:bookmark.activate(b:NERDTree, !a:bookmark.path.isDirectory ? {'stay': 1, 'where': 'v', 'keepopen': 1} : {})
endfunction

" FUNCTION: s:openExplorer(node) {{{1
function! s:openExplorer(node) abort
    call a:node.openExplorer()
endfunction

" FUNCTION: s:openInNewTab(target) {{{1
function! s:openInNewTab(target) abort
    let l:opener = g:NERDTreeOpener.New(a:target.path, {'where': 't', 'keepopen': !nerdtree#closeTreeOnOpen()})
    call l:opener.open(a:target)
endfunction

" FUNCTION: s:openInNewTabSilent(target) {{{1
function! s:openInNewTabSilent(target) abort
    let l:opener = g:NERDTreeOpener.New(a:target.path, {'where': 't', 'keepopen': !nerdtree#closeTreeOnOpen(), 'stay': 1})
    call l:opener.open(a:target)
endfunction

" FUNCTION: s:openNodeRecursively(node) {{{1
function! s:openNodeRecursively(node) abort
    call nerdtree#echo('Recursively opening node. Please wait...')
    call a:node.openRecursively()
    call b:NERDTree.render()
    call nerdtree#echo('')
endfunction

" FUNCTION: s:previewBookmark(bookmark) {{{1
function! s:previewBookmark(bookmark) abort
    if a:bookmark.path.isDirectory
        execute 'NERDTreeFind '.a:bookmark.path.str()
    else
        call a:bookmark.activate(b:NERDTree, {'stay': 1, 'where': 'p', 'keepopen': 1})
    endif
endfunction

"FUNCTION: s:previewNodeCurrent(node) {{{1
function! s:previewNodeCurrent(node) abort
    call a:node.open({'stay': 1, 'where': 'p', 'keepopen': 1})
endfunction

"FUNCTION: s:previewNodeHSplit(node) {{{1
function! s:previewNodeHSplit(node) abort
    call a:node.open({'stay': 1, 'where': 'h', 'keepopen': 1})
endfunction

"FUNCTION: s:previewNodeVSplit(node) {{{1
function! s:previewNodeVSplit(node) abort
    call a:node.open({'stay': 1, 'where': 'v', 'keepopen': 1})
endfunction

" FUNCTION: nerdtree#ui_glue#revealBookmark(name) {{{1
" put the cursor on the node associate with the given name
function! nerdtree#ui_glue#revealBookmark(name) abort
    try
        let targetNode = g:NERDTreeBookmark.GetNodeForName(a:name, 0, b:NERDTree)
        call targetNode.putCursorHere(0, 1)
    catch /^NERDTree.BookmarkNotFoundError/
        call nerdtree#echo('Bookmark isn''t cached under the current root')
    endtry
endfunction

" FUNCTION: s:refreshRoot() {{{1
" Reloads the current root. All nodes below this will be lost and the root dir
" will be reloaded.
function! s:refreshRoot() abort
    if !g:NERDTree.IsOpen()
        return
    endif
    call nerdtree#echo('Refreshing the root node. This could take a while...')

    let l:curWin = winnr()
    call nerdtree#exec(g:NERDTree.GetWinNum() . 'wincmd w', 1)
    call b:NERDTree.root.refresh()
    call b:NERDTree.render()
    redraw
    call nerdtree#exec(l:curWin . 'wincmd w', 1)
    call nerdtree#echo('')
endfunction

" FUNCTION: s:refreshCurrent(node) {{{1
" refreshes the root for the current node
function! s:refreshCurrent(node) abort
    let node = a:node
    if !node.path.isDirectory
        let node = node.parent
    endif

    call nerdtree#echo('Refreshing node. This could take a while...')
    call node.refresh()
    call b:NERDTree.render()
    call nerdtree#echo('')
endfunction

" FUNCTION: nerdtree#ui_glue#setupCommands() {{{1
function! nerdtree#ui_glue#setupCommands() abort
    command! -n=? -complete=dir -bar NERDTree :call g:NERDTreeCreator.CreateTabTree('<args>')
    command! -n=? -complete=dir -bar NERDTreeToggle :call g:NERDTreeCreator.ToggleTabTree('<args>')
    command! -n=? -complete=dir -bar NERDTreeExplore :call g:NERDTreeCreator.CreateExploreTree('<args>')
    command! -n=0 -bar NERDTreeClose :call g:NERDTree.Close()
    command! -n=1 -complete=customlist,nerdtree#completeBookmarks -bar NERDTreeFromBookmark call g:NERDTreeCreator.CreateTabTree('<args>')
    command! -n=0 -bar NERDTreeMirror call g:NERDTreeCreator.CreateMirror()
    command! -n=? -complete=file -bar NERDTreeFind call s:findAndRevealPath('<args>')
    command! -n=0 -bar NERDTreeRefreshRoot call s:refreshRoot()
    command! -n=0 -bar NERDTreeFocus call NERDTreeFocus()
    command! -n=0 -bar NERDTreeCWD call NERDTreeCWD()
endfunction

" Function: s:SID()   {{{1
function! s:SID() abort
    if !exists('s:sid')
        let s:sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
    endif
    return s:sid
endfun

" FUNCTION: s:showMenu(node) {{{1
function! s:showMenu(node) abort
    let mc = g:NERDTreeMenuController.New(g:NERDTreeMenuItem.AllEnabled())
    call mc.showMenu()
endfunction

" FUNCTION: s:toggleIgnoreFilter() {{{1
function! s:toggleIgnoreFilter() abort
    call b:NERDTree.ui.toggleIgnoreFilter()
endfunction

" FUNCTION: s:toggleShowBookmarks() {{{1
function! s:toggleShowBookmarks() abort
    call b:NERDTree.ui.toggleShowBookmarks()
endfunction

" FUNCTION: s:toggleShowFiles() {{{1
function! s:toggleShowFiles() abort
    call b:NERDTree.ui.toggleShowFiles()
endfunction

" FUNCTION: s:toggleShowHidden() {{{1
" toggles the display of hidden files
function! s:toggleShowHidden() abort
    call b:NERDTree.ui.toggleShowHidden()
endfunction

" FUNCTION: s:toggleShowFileLines() {{{1
" toggles the display of hidden files
function! s:toggleShowFileLines() abort
    call b:NERDTree.ui.toggleShowFileLines()
endfunction

" FUNCTION: s:toggleZoom() {{{1
function! s:toggleZoom() abort
    call b:NERDTree.ui.toggleZoom()
endfunction

" FUNCTION: nerdtree#ui_glue#upDir(preserveState) {{{1
" Move the NERDTree up one level.
"
" Args:
" preserveState: if 1, the current root is left open when the new tree is
" rendered; if 0, the current root node is closed
function! nerdtree#ui_glue#upDir(preserveState) abort

    try
        call b:NERDTree.root.cacheParent()
    catch /^NERDTree.CannotCacheParentError/
        call nerdtree#echo('already at root directory')
        return
    endtry

    let l:oldRoot = b:NERDTree.root
    let l:newRoot = b:NERDTree.root.parent

    call l:newRoot.open()
    call l:newRoot.transplantChild(l:oldRoot)

    if !a:preserveState
        call l:oldRoot.close()
    endif

    call b:NERDTree.changeRoot(l:newRoot)
    call l:oldRoot.putCursorHere(0, 0)
endfunction

" FUNCTION: s:upDirCurrentRootOpen() {{{1
function! s:upDirCurrentRootOpen() abort
    call nerdtree#ui_glue#upDir(1)
endfunction

" FUNCTION: s:upDirCurrentRootClosed() {{{1
function! s:upDirCurrentRootClosed() abort
    call nerdtree#ui_glue#upDir(0)
endfunction