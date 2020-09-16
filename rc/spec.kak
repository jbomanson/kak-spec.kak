declare-option str scratch_unit_test_client %val(client)

provide-module spec %~

require-module spec-scratch-eval

# A temporary variable used to monitor the growth of the debug buffer from test to test.
declare-option -hidden int scratch_unit_test_debug_line_count 0

# A monotonically increasing counter that is used to stamp messages sent internally to #
# reporter.
declare-option -hidden int scratch_unit_test_message_count 0

define-command spec-assert \
    -params .. \
    -docstring "spec-assert [<switches>]
Runs <command> in a temporary scratch buffer initialized with a string that
contains <input> and where that <input> is selected, and then compares the
result against <expected-output>.
The <matcher> argument controls the comparison:
- 'output' compares the final contents of the buffer to <expected-value>
- 'error'  matches any raised error or '' against regex <expected-value>" \
%(
    spec-scope "Implicit spec-assert scope" %sh(
        eval "$KAK_SPEC_PRELUDE_SH"
        # Usage:
        #   encode_comparison explicit|implicit <switch> <expected_value> <expression>
        encode_comparison ()
        {
            printf "%s " \
                "$1" \
                "$(kak_quote "${2#-expect-}")" \
                "$(kak_quote "$3")" \
                "$4"
        }
        error_comparison="$(encode_comparison \
            'comparison_implicit' \
            '-expect-%val(error)' \
            '' \
            '%opt(scratch_commands_error)'
        )"
        # Parse [<switches>].
        comparisons=""
        option_eval=""
        option_input=""
        option_title=""
        while true
        do
            case "$1" in
            ('-expect-%val(error)')
                error_comparison="$(encode_comparison \
                    comparison_explicit "$1" "$2" '%opt(scratch_commands_error)'
                )"
                shift 2
                ;;
            (-expect-*)
                comparisons="$comparisons $(encode_comparison \
                    comparison_explicit "$1" "$2" "${1#-expect-}"
                )"
                shift 2
                ;;
            (-eval | -input | -title)
                eval "option_${1#-}=\$2"
                shift 2
                ;;
            (-*)
                kak_quote fail "spec-assert: Unknown option '$1'"
                exit 1
                ;;
            (*)
                break
                ;;
            esac
        done
        true "${option_title:="$option_eval"}"
        # Call spec-scratch-eval with the user given command and with a <final-command> that
        # sends a message to the translator.
        kak_quote spec-scratch-eval "$option_input" "$option_eval" \
            "spec-send \
                message_assert \
                $error_comparison \
                $comparisons \
                END_OF_EXPECTATIONS \
                $(kak_quote "$option_title" "$option_input" "$option_eval")
            " \
    )
)

define-command spec-source \
    -params 1 \
    -docstring 'spec-source <filename>:
Define a test suite source file.' \
%(
    spec-scope %arg(1) source %arg(1)
)

define-command spec-context \
    -params 2 \
    -docstring 'spec-context <context-message> <commands>:
Evaluates <commands> so that any assertions in them have context information.' \
%(
    spec-scope %arg(@)
)

define-command spec-scope \
    -hidden \
    -params 2..3 \
    -docstring 'spec-scope <description> <command> [<argument>]:
Evaluates <commands> so that any assertions in them have scope information.' \
%(
    # Save the current length of *debug*.
    evaluate-commands -buffer *debug* %(
        set-option global scratch_unit_test_debug_line_count %val(buf_line_count)
    )
    spec-send message_scope_begin %arg(1) %opt(scratch_unit_test_debug_line_count)
    try %(
        evaluate-commands %arg(2) %arg(3)
    ) catch %(
        # Send the error as a command to the translator.
        spec-send message_non_assertion_error %val(error)
        # Save the current length of *debug*.
        evaluate-commands -buffer *debug* %(
            set-option global scratch_unit_test_debug_line_count %val(buf_line_count)
        )
        spec-send message_scope_end %arg(1) %opt(scratch_unit_test_debug_line_count)
        # Re-raise the caught error.
        fail "%val(error)"
    )
    # Save the current length of *debug*.
    evaluate-commands -buffer *debug* %(
        set-option global scratch_unit_test_debug_line_count %val(buf_line_count)
    )
    spec-send message_scope_end %arg(1) %opt(scratch_unit_test_debug_line_count)
)

define-command spec-send \
    -hidden \
    -params 1.. \
    -docstring 'spec-send <message-name> [<argument>]+:
send a message to reporter' \
%(
    evaluate-commands -save-regs a %(
        set-register a %opt(scratch_unit_test_message_count) %arg(@)
        set-option -add global scratch_unit_test_message_count 1
        nop %sh(
            eval "$KAK_SPEC_SEND_MESSAGE"
            send_message "$kak_quoted_reg_a"
        )
    )
)

define-command spec-quit-begin \
    -hidden \
    -docstring 'spec-quit-begin: begin quitting kak-spec and kakoune' \
%(
    buffer *debug*
    execute-keys '%'
    spec-send message_quit %val(selection)
)

define-command spec-quit-end \
    -hidden \
    -docstring 'spec-quit-end: finish quitting kak-spec and kakoune' \
%(
    quit!
)

spec-send message_init %val(session) %opt(scratch_unit_test_client)

~
