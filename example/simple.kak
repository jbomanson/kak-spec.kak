require-module scratch-unit-test

evaluate-commands -save-regs n %(
    scratch-unit-test-assert -expect-%val(selection) "oops" -title "nop" -input "abc" -eval nop
    scratch-unit-test-assert -expect-%val(error) "joo" -title "raise joo" -input "" -eval %(raise joo)

    scratch-unit-test-assert -expect-%val(selection) "x" -title "nop" -input "x" -eval nop
    scratch-unit-test-assert -expect-%val(selection) " " -title "nop" -input " " -eval nop

    scratch-unit-test-assert -expect-%val(selection) "
" -title "nop" -input "
" -eval nop

    set-register n "
"

    scratch-unit-test-assert -expect-%val(selection) "
" -title "%%reg(n)" -input "%reg(n)" -eval nop

    scratch-unit-test-assert -expect-%val(selection) "word" -title "c"  -input "xyz" -eval %(execute-keys cword<esc>)
    scratch-unit-test-assert -expect-%val(selection) "word" -title "di" -input "xyz" -eval %(execute-keys diword<esc>)
    scratch-unit-test-assert -expect-%val(selection) "wordxyz" -title "i"  -input "xyz" -eval %(execute-keys iword<esc>)
    scratch-unit-test-assert -expect-%val(selection) "xyzword" -title "a"  -input "xyz" -eval %(execute-keys aword<esc>)
    scratch-unit-test-assert -expect-%val(selection) "word" -title "R"  -input "xyz" -eval %(set-register dquote word; execute-keys R<esc>)
    scratch-unit-test-assert -expect-%val(selection) "xyzword" -title "p"  -input "xyz" -eval %(set-register dquote word; execute-keys p<esc>)
    scratch-unit-test-assert -expect-%val(selection) "wordxyz" -title "P"  -input "xyz" -eval %(set-register dquote word; execute-keys P<esc>)

    scratch-unit-test-assert -expect-%val(selection) "one
word
two" -title "o"  -input "one
two" -eval %(execute-keys sone<ret>oword<esc>)
)
