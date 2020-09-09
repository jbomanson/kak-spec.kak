require-module scratch-unit-test

declare-option -hidden str sut_simple_source %sh(
    printf "%s" "${kak_source}"
)

hook -once global NormalIdle .* %(
    scratch-unit-test-suite "%opt(sut_simple_source)" %(
        echo -debug "scratch-unit-test-own-test-suite"
        evaluate-commands -save-regs n %(
            scratch-unit-test-assert "nop" "abc" output "oops" nop
            scratch-unit-test-assert "raise joo" "" error  "joo" raise joo

            scratch-unit-test-assert "nop" "x" output "x" nop
            scratch-unit-test-assert "nop" " " output " " nop

            scratch-unit-test-assert "nop" "
" output "
" nop

            set-register n "
"

            scratch-unit-test-assert "%%reg(n)" "%reg(n)" output "
" nop

            scratch-unit-test-assert "c"  "xyz" output "word"    %(execute-keys cword<esc>)
            scratch-unit-test-assert "di" "xyz" output "word"    %(execute-keys diword<esc>)
            scratch-unit-test-assert "i"  "xyz" output "wordxyz" %(execute-keys iword<esc>)
            scratch-unit-test-assert "a"  "xyz" output "xyzword" %(execute-keys aword<esc>)
            scratch-unit-test-assert "R"  "xyz" output "word"    %(set-register dquote word; execute-keys R<esc>)
            scratch-unit-test-assert "p"  "xyz" output "xyzword" %(set-register dquote word; execute-keys p<esc>)
            scratch-unit-test-assert "P"  "xyz" output "wordxyz" %(set-register dquote word; execute-keys P<esc>)

            scratch-unit-test-assert "o"  "one
two" output "one
word
two" %(execute-keys sone<ret>oword<esc>)
        )
    )
)
