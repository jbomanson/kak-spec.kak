require-module spec

evaluate-commands -save-regs n %(
    spec -expect-%val(selection) "oops" -title "Smoke test: nop" -input "abc" -eval nop
    spec -expect-%val(error) "joo" -title "Smoke test: raise joo" -input "" -eval %(raise joo)

    spec -expect-%val(selection) "x" -title "nop" -input "x" -eval nop
    spec -expect-%val(selection) " " -title "nop" -input " " -eval nop

    spec -expect-%val(selection) "
" -title "nop" -input "
" -eval nop

    set-register n "
"

    spec -expect-%val(selection) "
" -title "%%reg(n)" -input "%reg(n)" -eval nop

    spec -expect-%val(selection) "word" -title "c"  -input "xyz" -eval %(execute-keys cword<esc>%H)
    spec -expect-%val(selection) "word" -title "di" -input "xyz" -eval %(execute-keys diword<esc>%H)
    spec -expect-%val(selection) "wordxyz" -title "i"  -input "xyz" -eval %(execute-keys iword<esc>%H)
    spec -expect-%val(selection) "xyzword" -title "a"  -input "xyz" -eval %(execute-keys aword<esc>%H)
    spec -expect-%val(selection) "word" -title "R"  -input "xyz" -eval %(set-register dquote word; execute-keys R<esc>%H)
    spec -expect-%val(selection) "xyzword" -title "p"  -input "xyz" -eval %(set-register dquote word; execute-keys p<esc>%H)
    spec -expect-%val(selection) "wordxyz" -title "P"  -input "xyz" -eval %(set-register dquote word; execute-keys P<esc>%H)

    spec -expect-%val(selection) "one
word
two" -title "o"  -input "one
two" -eval %(execute-keys sone<ret>oword<esc>%H)
)
