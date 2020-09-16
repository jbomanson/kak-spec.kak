require-module spec

evaluate-commands -save-regs n %(
    spec-assert -expect-%val(selection) "oops" -title "nop" -input "abc" -eval nop
    spec-assert -expect-%val(error) "joo" -title "raise joo" -input "" -eval %(raise joo)

    spec-assert -expect-%val(selection) "x" -title "nop" -input "x" -eval nop
    spec-assert -expect-%val(selection) " " -title "nop" -input " " -eval nop

    spec-assert -expect-%val(selection) "
" -title "nop" -input "
" -eval nop

    set-register n "
"

    spec-assert -expect-%val(selection) "
" -title "%%reg(n)" -input "%reg(n)" -eval nop

    spec-assert -expect-%val(selection) "word" -title "c"  -input "xyz" -eval %(execute-keys cword<esc>)
    spec-assert -expect-%val(selection) "word" -title "di" -input "xyz" -eval %(execute-keys diword<esc>)
    spec-assert -expect-%val(selection) "wordxyz" -title "i"  -input "xyz" -eval %(execute-keys iword<esc>)
    spec-assert -expect-%val(selection) "xyzword" -title "a"  -input "xyz" -eval %(execute-keys aword<esc>)
    spec-assert -expect-%val(selection) "word" -title "R"  -input "xyz" -eval %(set-register dquote word; execute-keys R<esc>)
    spec-assert -expect-%val(selection) "xyzword" -title "p"  -input "xyz" -eval %(set-register dquote word; execute-keys p<esc>)
    spec-assert -expect-%val(selection) "wordxyz" -title "P"  -input "xyz" -eval %(set-register dquote word; execute-keys P<esc>)

    spec-assert -expect-%val(selection) "one
word
two" -title "o"  -input "one
two" -eval %(execute-keys sone<ret>oword<esc>)
)
