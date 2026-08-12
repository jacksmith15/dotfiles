" Python syntax tweaks, to match the oxide theme used by the pi agent.
"
" These cannot live in colors/oxide.vim. Vim's bundled syntax/python.vim assigns
" its links with 'hi! def link', and the bang defeats the 'default' -- it
" overrides whatever the colorscheme set. An after/syntax file is sourced last,
" so it wins.

" True/False/None/NotImplemented/Ellipsis are literals, but python.vim sends
" them to Function alongside print() and len(), because 'builtin' lumps
" constants and callables together. Put them with the numbers on Constant.
hi! link pythonBoolean  Constant
hi! link pythonConstant Constant

" Builtins go to Type, so 'list' in 'x: list[str]' and 'len' in 'len(xs)' are
" both turquoise. Turquoise then means "a name the language gave you" -- types,
" exceptions and builtins alike -- and green is left to mark the site where a
" name is defined, after def and class.
"
" python.vim links pythonBuiltin to Function, which singles builtin calls out in
" green while calls to your own functions stay plain text. That distinction is
" backwards: it is the definition that deserves the accent, not the call.
hi! link pythonBuiltin Type

" The name in 'class Thing:' is a definition site, so it takes green like the
" name after def. python.vim sends it to Structure, which lands on Type -- but
" that colours the definition the same as every later mention of Thing, hiding
" the one place it is introduced. Only the name directly after 'class' is
" pythonClass; base classes in the parens stay on their own groups.
hi! link pythonClass Function

" python.vim only ever matches the five word operators (and in is not or), so
" '+' and '==' fall through to plain text. Create the missing match and hand it
" to the same group, as a run of operator characters -- that covers ==, !=, //,
" **, <<, >>, ->, += and friends without enumerating them.
"
" '@' is deliberately excluded. Decorators are far more common than matrix
" multiplication, and because this file is sourced after python.vim, a match on
" '@' here would outrank pythonDecorator and break the nextgroup that colours
" the decorator's name.
"
" ':' and ',' are left alone too: they are punctuation, not operators, so the
" walrus ':=' comes out as a plain colon followed by a red '='.
syn match pythonOperator "[-+*/%<>=!&|^~]\+" display

" '...' is the Ellipsis literal, but python.vim routes it through pythonBuiltin,
" which would now make it turquoise while the 'Ellipsis' spelling is purple.
" Keep both with the literals.
hi! link pythonEllipsis Constant

" vim: sw=4
