"==============================================================================
"    Copyright: Copyright (C) 2012 Stanislas Polu an other Contributors
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               dwm.vim is provided *as is* and comes with no warranty of
"               any kind, either expressed or implied. In no event will the
"               copyright holder be liable for any damages resulting from
"               the use of this software.
" Name Of File: dwm.vim
"  Description: Dynamic Window Manager behaviour for Vim
"   Maintainer: Stanislas Polu (polu.stanislas at gmail dot com)
" Last Changed: Tuesday, 23 August 2012
"      Version: See g:dwm_version for version number.
"        Usage: This file should reside in the plugin directory and be
"               automatically sourced.
"
"               For more help see supplied documentation.
"      History: See supplied documentation.
"==============================================================================

" Exit quickly if already running
if exists("g:dwm_version") || &diff || &cp
  finish
endif

let g:dwm_version = "0.1.2"

" Check for Vim version 700 or greater {{{1
if v:version < 700
  echo "Sorry, dwm.vim ".g:dwm_version."\nONLY runs with Vim 7.0 and greater."
  finish
endif

" All layout transformations assume the layout contains one master pane on the
" left and an arbitrary number of stacked panes on the right
" +--------+--------+--+--+--+
" |        |        |  |  |  |
" |        |        |  |  |  |
" |   M    |   S1   |S2|S3|S4|
" |        |        |  |  |  |
" |        |        |  |  |  |
" +--------+--------+--+--+--+

" Move the current master pane to the stack
function! DWM_Stack(ltor)
  1wincmd w
  if a:ltor
    " Move to the left of the stack
    wincmd H
  else
    " Move to the right of the stack
    wincmd L
  endif
  " At this point, the layout *should* be the following with the previous master
  " at the left.
  " +--------+--------+--+--+--+
  " |        |        |  |  |  |
  " |        |        |  |  |  |
  " |   M    |   S1   |S2|S3|S4|
  " |        |        |  |  |  |
  " |        |        |  |  |  |
  " +--------+--------+--+--+--+
endfunction

" Add a new buffer
function! DWM_New(split)
  " Move current master pane to the stack
  call DWM_Stack(1)
  " Create a vertical split
  if a:split
    vert topleft split
  else
    vert topleft new
  endif
  call DWM_ResizeMasterPaneWidth()
endfunction

" Move the current window to the master pane (the previous master window is
" added to the top of the stack). If current window is master already - switch
" to stack top
function! DWM_Focus()
  if winnr('$') == 1
    return
  endif

  "if winnr() == 1
    "wincmd w
  "endif

  let l:curwin = winnr()
  call DWM_Stack(1)
  exec l:curwin . "wincmd w"
  wincmd H
  call DWM_ResizeMasterPaneWidth()
endfunction

" Move the current window to the bottom of the stack
function! DWM_Bottom()
  call DWM_Stack(0)
  exec "wincmd w"
  call DWM_ResizeMasterPaneWidth()
endfunction

function! DWM_StartupComplete()
  let g:dwm_startup_complete = 1
endfunction

" Handler for BufWinEnter autocommand
" Recreate layout broken by new window
function! DWM_AutoEnter()
  if !exists("g:dwm_startup_complete")
    return
  endif
  if winnr('$') == 1
    return
  endif
  " Skip unlisted (except help)
  if !&l:buflisted && &l:filetype != 'help'
    return
  endif

  "" Skip buffers without filetype
  "if !len(&l:filetype)
    "return
  "endif

  " Skip quickfix buffers
  if &l:buftype == 'quickfix'
    return
  endif

  " Move new window to stack top
  wincmd H

  " Focus new window (twice :)
  call DWM_Focus()
  call DWM_Focus()
endfunction

" Close the current window
function! DWM_Close()
  if winnr() == 1
    " Close master panel.
    return 'close | wincmd H | call DWM_ResizeMasterPaneWidth()'
  else
    return 'close | 1wincmd w | call DWM_ResizeMasterPaneWidth()'
  end
endfunction

function! DWM_ZoomCurrentPane()
  " Make all windows equally high and wide
  wincmd =

  if winnr('$') == 1
    return
  end

  " resize the current pane
  exec 'vertical resize ' . ((33 * &columns)/100)
endfunction

function! DWM_ResizeMasterPaneWidth()
  " Make all windows equally high and wide
  wincmd =

  if winnr('$') == 1
    return
  end

  " resize the master pane if user defined it
  if exists('g:dwm_master_pane_width')
    if type(g:dwm_master_pane_width) == type("")
      exec 'vertical resize ' . ((str2nr(g:dwm_master_pane_width)*&columns)/100)
    else
      exec 'vertical resize ' . g:dwm_master_pane_width
    endif
  else
    exec 'vertical resize ' . ((33 * &columns)/100)
    2wincmd w
    exec 'vertical resize ' . ((33 * &columns)/100)
    1wincmd w
  endif
endfunction

function! DWM_GrowMaster()
  if winnr() == 1
    exec "vertical resize +1"
  else
    exec "vertical resize -1"
  endif
  if exists("g:dwm_master_pane_width") && g:dwm_master_pane_width
    let g:dwm_master_pane_width += 1
  else
    let g:dwm_master_pane_width = ((&columns)/2)+1
  endif
endfunction

function! DWM_ShrinkMaster()
  if winnr() == 1
    exec "vertical resize -1"
  else
    exec "vertical resize +1"
  endif
  if exists("g:dwm_master_pane_width") && g:dwm_master_pane_width
    let g:dwm_master_pane_width -= 1
  else
    let g:dwm_master_pane_width = ((&columns)/2)-1
  endif
endfunction

function! DWM_ResetMaster()
  if exists("g:dwm_master_pane_width")
    unlet g:dwm_master_pane_width
  endif
  call DWM_ResizeMasterPaneWidth()
endfunction

function! DWM_Rotate(ltor)
  call DWM_Stack(a:ltor)
  if a:ltor
    wincmd W
  else
    wincmd w
  endif
  wincmd H
  call DWM_ResizeMasterPaneWidth()
endfunction

function! DWM_Tag()
  let l:target = expand("<cword>")
  call DWM_New(1)
  exec("tag " . l:target)
endfunction

function! DWM_FocusReset()
  call DWM_Focus()
  call DWM_ResetMaster()
endfunction

nnoremap <silent> <Plug>DWMRotateCounterclockwise :call DWM_Rotate(0)<CR>
nnoremap <silent> <Plug>DWMRotateClockwise        :call DWM_Rotate(1)<CR>

nnoremap <silent> <Plug>DWMNew   :call DWM_New(0)<CR>
nnoremap <silent> <Plug>DWMSplit   :call DWM_New(1)<CR>
nnoremap <silent> <Plug>DWMClose :exec DWM_Close()<CR>
nnoremap <silent> <Plug>DWMFocus :call DWM_Focus()<CR>
nnoremap <silent> <Plug>DWMZoom :call DWM_ZoomCurrentPane()<CR>

nnoremap <silent> <Plug>DWMGrowMaster   :call DWM_GrowMaster()<CR>
nnoremap <silent> <Plug>DWMShrinkMaster :call DWM_ShrinkMaster()<CR>
nnoremap <silent> <Plug>DWMResetMaster :call DWM_ResetMaster()<CR>

nnoremap <silent> <Plug>DWMFocusReset   :call DWM_FocusReset()<CR>
nnoremap <silent> <Plug>DWMTag   :call DWM_Tag()<CR>
nnoremap <silent> <Plug>DWMBottom   :call DWM_Bottom()<CR>

if !exists('g:dwm_map_keys')
  let g:dwm_map_keys = 1
endif

if g:dwm_map_keys
  nnoremap <C-J> <C-W>w
  nnoremap <C-K> <C-W>W

  if !hasmapto('<Plug>DWMRotateCounterclockwise')
      nmap <C-,> <Plug>DWMRotateCounterclockwise
  endif
  if !hasmapto('<Plug>DWMRotateClockwise')
      nmap <C-.> <Plug>DWMRotateClockwise
  endif

  if !hasmapto('<Plug>DWMSplit')
      nmap <C-N> <Plug>DWMSplit
  endif
  if !hasmapto('<Plug>DWMClose')
      nmap <C-C> <Plug>DWMClose
  endif
  if !hasmapto('<Plug>DWMFocus')
      nmap <C-@> <Plug>DWMFocus
      nmap <C-Space> <Plug>DWMFocus
  endif

  if !hasmapto('<Plug>DWMGrowMaster')
      nmap <C-L> <Plug>DWMGrowMaster
  endif
  if !hasmapto('<Plug>DWMShrinkMaster')
      nmap <C-H> <Plug>DWMShrinkMaster
  endif
endif

if has('autocmd')
  augroup dwm
    au!
    au BufWinEnter * call DWM_AutoEnter()
    au VimEnter * call DWM_StartupComplete()
  augroup end
endif
