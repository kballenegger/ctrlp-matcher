if !exists("g:path_to_matcher")
    let g:path_to_matcher = system("which matcher")
    let g:path_to_matcher = matchstr(g:path_to_matcher, '.*\ze\n')
    if v:shell_error != 0
        finish
    endif
endif


let g:ctrlp_match_func = { 'match': 'GoodMatch' }

" Original MatchIt... :( can't find a way to call it, so need to clone it.
fu! s:MatchIt(items, pat, limit, exc)
  let [lines, id] = [[], 0]
  let pat =
    \ s:byfname() ? map(split(a:pat, '^[^;]\+\\\@<!\zs;', 1), 's:martcs.v:val')
    \ : s:martcs.a:pat
  for item in a:items
    let id += 1
    try | if !( s:ispath && item == a:exc ) && call(s:mfunc, [item, pat]) >= 0
      cal add(lines, item)
    en | cat | brea | endt
    if a:limit > 0 && len(lines) >= a:limit | brea | en
  endfo
  let s:mdata = [s:dyncwd, s:itemtype, s:regexp, s:sublist(a:items, id, -1)]
  retu lines
endf

function! GoodMatch(items, str, limit, mmode, ispath, crfile, regex)

  if ispath == 0
    return s:MatchIt(items, str, limit, crfile)
  endif

  " Create a cache file if not yet exists
  let cachefile = ctrlp#utils#cachedir().'/matcher.cache'
  if !( filereadable(cachefile) && a:items == readfile(cachefile) )
    call writefile(a:items, cachefile)
  endif
  if !filereadable(cachefile)
    return []
  endif

  " a:mmode is currently ignored. In the future, we should probably do
  " something about that. the matcher behaves like "full-line".
  let cmd = g:path_to_matcher.' --limit '.a:limit.' --manifest '.cachefile.' '
  if !( exists('g:ctrlp_dotfiles') && g:ctrlp_dotfiles )
    let cmd = cmd.'--no-dotfiles '
  endif
  let cmd = cmd."'".a:str."'"

  return split(system(cmd), "\n")

endfunction
