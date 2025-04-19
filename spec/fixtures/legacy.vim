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
