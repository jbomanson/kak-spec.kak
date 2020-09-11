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
    -docstring "scratch-unit-test-assert [<switches>] <title> <input> <matcher> <expected-value> <command>
Runs <command> in a temporary scratch buffer initialized with a string that
contains <input> and where that <input> is selected, and then compares the
result against <expected-output>.
The <matcher> argument controls the comparison:
- 'output' compares the final contents of the buffer to <expected-value>
- 'error'  matches any raised error or '' against regex <expected-value>" \
%(
    try %(
        evaluate-commands %sh(
            eval "$SCRATCH_UNIT_TEST_PRELUDE_SH"
            encode_comparison ()
            {
                printf "%s " \
                    "$(kak_quote "${1#-expect-}")" \
                    "$(kak_quote "$2")" \
                    "$3"
            }
            error_comparison="$(encode_comparison \
                '-expect-%val(error)' \
                '' \
                '%opt(scratch_commands_error)'
            )"
            # Parse [<switches>].
            comparisons=""
            while true
            do
                case "$1" in
                ('-expect-%val(error)')
                    error_comparison="$(encode_comparison \
                        "$1" "$2" '%opt(scratch_commands_error)'
                    )"
                    shift 2
                    ;;
                (-expect-*)
                    comparisons="$comparisons $(encode_comparison \
                        "$1" "$2" "${1#-expect-}"
                    )"
                    shift 2
                    ;;
                (-*)
                    kak_quote fail "scratch-unit-test-assert: Unknown option '$1'"
                    exit 1
                    ;;
                (*)
                    break
                    ;;
                esac
            done
            # Call scratch-commands with the user given command and with a <final-command> that
            # sends a message to the translator.
            kak_quote scratch-commands "$2" "$5" \
                "scratch-unit-test-send \
                    message_assert \
                    $error_comparison \
                    $comparisons \
                    END_OF_EXPECTATIONS \
                    %opt(scratch_commands_output) \
                    %opt(scratch_commands_error) \
                    $(kak_quote "$@")"
        )
    ) catch %(
        scratch-unit-test-send message_non_assertion_error %val(error)
    )
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
    scratch-unit-test-send message_scope_begin %arg(2)
    try %(
        set-option global %arg(1) %arg(2)
        evaluate-commands %arg(3) %arg(4)
    ) catch %(
        # Send the error as a command to the translator.
        scratch-unit-test-send message_non_assertion_error %val(error)
        scratch-unit-test-send message_scope_end %arg(2)
        set-option global %arg(1) UNDEFINED
        # Re-raise the caught error.
        fail "%val(error)"
    )
    scratch-unit-test-send message_scope_end %arg(2)
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
