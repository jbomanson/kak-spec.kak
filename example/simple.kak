require-module scratch-unit-test

evaluate-commands -save-regs n %(
    scratch-unit-test-assert -expect-%val(selection) "oops" "nop" "abc" nop
    scratch-unit-test-assert -expect-%val(error) "joo" "raise joo" "" %(raise joo)

    scratch-unit-test-assert -expect-%val(selection) "x" "nop" "x" nop
    scratch-unit-test-assert -expect-%val(selection) " " "nop" " " nop

    scratch-unit-test-assert -expect-%val(selection) "
" "nop" "
" nop

    set-register n "
"

    scratch-unit-test-assert -expect-%val(selection) "
" "%%reg(n)" "%reg(n)" nop

    scratch-unit-test-assert -expect-%val(selection) "word" "c"  "xyz" %(execute-keys cword<esc>)
    scratch-unit-test-assert -expect-%val(selection) "word" "di" "xyz" %(execute-keys diword<esc>)
    scratch-unit-test-assert -expect-%val(selection) "wordxyz" "i"  "xyz" %(execute-keys iword<esc>)
    scratch-unit-test-assert -expect-%val(selection) "xyzword" "a"  "xyz" %(execute-keys aword<esc>)
    scratch-unit-test-assert -expect-%val(selection) "word" "R"  "xyz" %(set-register dquote word; execute-keys R<esc>)
    scratch-unit-test-assert -expect-%val(selection) "xyzword" "p"  "xyz" %(set-register dquote word; execute-keys p<esc>)
    scratch-unit-test-assert -expect-%val(selection) "wordxyz" "P"  "xyz" %(set-register dquote word; execute-keys P<esc>)

    scratch-unit-test-assert -expect-%val(selection) "one
word
two" "o"  "one
two" %(execute-keys sone<ret>oword<esc>)
)
