declare-option str scratch_unit_test_client %val(client)

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
    scratch-unit-test-send \
        "message_assert" \
        "%opt(scratch_unit_test_suite_file)" \
        "%opt(scratch_unit_test_context_message)" \
        scratch-unit-test-assert \
        "%opt(scratch_commands_output)" \
        %arg(@)
)

define-command scratch-unit-test-suite \
    -params 2 \
    -docstring 'scratch-unit-test-suite <current-file> <command>: Define a test suite.' \
%(
    try %(
        evaluate-commands %sh(
            test -f "$1" && printf "%s" "nop"
        ) fail "scratch-unit-test-suite: expected a kakoune source file as the first argument"
        set-option global scratch_unit_test_suite_file "%arg(1)"
        evaluate-commands "%arg(2)"
    ) catch %(
        # Send the error as a command to the translator.
        scratch-unit-test-send "message_non_assertion_error" %arg(1) %val(error)
        # Re-raise the caught error.
        fail "%val(error)"
    )
    set-option global scratch_unit_test_suite_file ""
)

define-command scratch-unit-test-context \
    -params 2 \
    -docstring 'scratch-unit-test-context <context-message> <commands>:
Evaluates <commands> so that any assertions in them have context information.' \
%(
    try %(
        evaluate-commands %sh(
            test "$kak_opt_scratch_unit_test_suite_file" && printf "%s" "nop"
        ) fail "scratch-unit-test-context: can only be called within scratch-unit-test-suite"
        set-option global scratch_unit_test_context_message "%arg(1)"
        evaluate-commands "%arg(2)"
    ) catch %(
        # Send the error as a command to the translator.
        scratch-unit-test-send "message_context_error" %opt(scratch_unit_test_suite_file) %arg(1) %val(error)
        # Re-raise the caught error.
        fail "%val(error)"
    )
    set-option global scratch_unit_test_context_message ""
)

define-command scratch-unit-test-send \
    -hidden \
    -params 1.. \
    -docstring 'scratch-unit-test-send <message-name> [<argument>]+:
send a message to scratch_unit_test_translate' \
%(
    evaluate-commands -save-regs a %(
        set-register a %arg(@)
        nop %sh(
            eval "$SCRATCH_UNIT_TEST_SEND_MESSAGE"
            send_message "$kak_quoted_reg_a"
        )
    )
)

define-command scratch-unit-test-quit \
    -hidden \
    -docstring 'scratch-unit-test-quit: quit kakoune' \
%(
    try %(
        write %sh(printf "%s" "$SCRATCH_UNIT_TEST_DIR/debug")
    )
    quit!
)

scratch-unit-test-send message_init %val(session) %opt(scratch_unit_test_client)

~
