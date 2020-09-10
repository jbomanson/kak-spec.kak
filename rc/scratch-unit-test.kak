provide-module scratch-unit-test %~

require-module scratch-commands

# TODO.
declare-option -hidden str scratch_unit_test_suite_file

# TODO.
declare-option -hidden str scratch_unit_test_context_message

define-command scratch-unit-test-assert \
    -params .. \
    -docstring "scratch-unit-test-assert <title> <input> <matcher> <expected-value> <command>...
Runs <command> in a temporary scratch buffer initialized with a string that
contains <input> and where that <input> is selected, and then compares the
result against <expected-output>.
The <matcher> argument controls the comparison:
- 'output' compares the final contents of the buffer to <expected-value>
- 'error'  matches any raised error or '' against regex <expected-value>" \
%(
    try %(
        evaluate-commands scratch-commands %sh(
            eval "$SCRATCH_UNIT_TEST_PRELUDE_SH"
            printf "%s" "$(kak_quote "$2") "
            shift 4
            kak_quote "$@"
        )
        scratch-unit-test-log ""            %arg(@)
    ) catch %(
        scratch-unit-test-log "%val(error)" %arg(@)
    )
)

define-command scratch-unit-test-log \
    -hidden \
    -params .. \
    -docstring 'scratch-unit-test-log <error> <arg>...:
Logs the output and error of an assertion.' \
%(
    scratch-unit-test-log-impl \
        "%opt(scratch_unit_test_suite_file)" \
        "%opt(scratch_unit_test_context_message)" \
        scratch-unit-test-assert \
        "%opt(scratch_commands_output)" \
        %arg(@)
)

define-command scratch-unit-test-log-impl \
    -hidden \
    -params .. \
    -docstring 'scratch-unit-test-log-impl <suite_file> <context_message> <command-name> <output> <error> <assertion> <arg>...:
Logs the <output> and <error> of <assertion.' \
%(
    evaluate-commands -save-regs a %(
        set-register a %arg(@)
        nop %sh(
            if test -w "$SCRATCH_UNIT_TEST_DIR/fifo"; then
                {
                    printf "%s\n" "log"
                    printf "%s\n" "$kak_quoted_reg_a" | wc -l
                    printf "%s\n" "$kak_quoted_reg_a"
                } >"$SCRATCH_UNIT_TEST_DIR/fifo"
            fi
        )
    )
)

define-command scratch-unit-test-suite \
    -params 2 \
    -docstring 'scratch-unit-test-suite <current-file> <command>: Define a test suite.' \
%(
    try %(
        evaluate-commands %sh(
            test -f "$1" && printf "%s" "nop"
        ) fail "scratch-unit-test-suite: should be given a kakoune source file as the first argument"
        set-option global scratch_unit_test_suite_file "%arg(1)"
        evaluate-commands "%arg(2)"
        set-option global scratch_unit_test_suite_file ""
    ) catch %(
        fail "%val(error)"
    )
)

define-command scratch-unit-test-context \
    -params 2 \
    -docstring 'scratch-unit-test-context <context-message> <commands>:
Evaluates <commands> so that any assertions in them have context information.' \
%(
    evaluate-commands %sh(
        test "$kak_opt_scratch_unit_test_suite_file" && printf "%s" "nop"
    ) fail "scratch-unit-test-context: %arg(1): must be called within scratch-unit-test-suite"
    set-option global scratch_unit_test_context_message "%arg(1)"
    evaluate-commands "%arg(2)"
    set-option global scratch_unit_test_context_message ""
)

~
