declare-option str scratch_unit_test_client %val(client)

provide-module scratch-unit-test %~

require-module scratch-commands

# TODO.
declare-option -hidden str scratch_unit_test_source_file UNDEFINED

# TODO.
declare-option -hidden str scratch_unit_test_context_message UNDEFINED

# A monotonically increasing counter that is used to stamp messages sent internally to #
# scratch_unit_test_translate.
declare-option -hidden int scratch_unit_test_message_count 0

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
        "%opt(scratch_unit_test_source_file)" \
        "%opt(scratch_unit_test_context_message)" \
        scratch-unit-test-assert \
        "%opt(scratch_commands_output)" \
        %arg(@)
)

define-command scratch-unit-test-source \
    -params 1 \
    -docstring 'scratch-unit-test-source <filename>:
Define a test suite source file.' \
%(
    scratch-unit-test-scope scratch_unit_test_source_file %arg(1) source %arg(1)
)

define-command scratch-unit-test-context \
    -params 2 \
    -docstring 'scratch-unit-test-context <context-message> <commands>:
Evaluates <commands> so that any assertions in them have context information.' \
%(
    scratch-unit-test-scope scratch_unit_test_context_message %arg(@)
)

define-command scratch-unit-test-scope \
    -hidden \
    -params 3..4 \
    -docstring 'scratch-unit-test-scope <option> <description> <command> [<argument>]:
Evaluates <commands> so that any assertions in them have scope information.' \
%(
    try %(
        set-option global %arg(1) %arg(2)
        evaluate-commands %arg(3) %arg(4)
    ) catch %(
        # Send the error as a command to the translator.
        scratch-unit-test-send "message_non_assertion_error" \
            %opt(scratch_unit_test_source_file) \
            %opt(scratch_unit_test_context_message) \
            %val(error)
        set-option global %arg(1) UNDEFINED
        # Re-raise the caught error.
        fail "%val(error)"
    )
    set-option global %arg(1) UNDEFINED
)

define-command scratch-unit-test-send \
    -hidden \
    -params 1.. \
    -docstring 'scratch-unit-test-send <message-name> [<argument>]+:
send a message to scratch_unit_test_translate' \
%(
    evaluate-commands -save-regs a %(
        set-register a %opt(scratch_unit_test_message_count) %arg(@)
        set-option -add global scratch_unit_test_message_count 1
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
