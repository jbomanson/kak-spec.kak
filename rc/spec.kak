declare-option str scratch_unit_test_client %val(client)

provide-module spec %~

require-module spec-scratch-eval

# A temporary variable used to monitor the growth of the debug buffer from test to test.
declare-option -hidden int scratch_unit_test_debug_line_count 0

define-command spec \
    -params .. \
    -docstring 'spec <option>...: Define a unit test.

-title <title>
  A title to be shown if the test fails.

-input <input>
  Initial contents written to and selected in the scratch buffer where the test begins.
  The scratch buffer will always contain a newline in addition to <input>.

-eval <commands>
  Commands evaluated in the test.
  Mutually exclusive with -exec.
  Example: -eval %(set-register dquote "Hello world!"; execute-keys R)

-exec <keys>
  Keys to be executed in the buffer.
  Mutually exclusive with -eval.
  Example: -exec %(cHello world!)

-expect-<expansion> <value>
  Expects kakoune <expansion> to expand to <value> at the end of the test.
  Example: -expect-%val(selection) "Hello world!"
  Example: -expect-%val(error) "Something went wrong"

-expect-<expansion>-( <value>... )
  Expects kakoune <expansion> to expand to the given array.
  The delimiters can be (), [], {}, or <>.
  Example: -expect-%val(selections)-[ "word" "pair of words" ]
' \
%(
    spec-context "Implicit spec context" %sh(
        . "$KAK_SPEC_PRELUDE_PATH"
        # Usage:
        #   encode_comparison \
        #       comparison_explicit|comparison_implicit \
        #       <switch> <expected_value> <expression>
        encode_comparison ()
        {
            printf "%s " \
                "$1" \
                "$(kak_escape "${2#-expect-}")" \
                "$(kak_escape "$3")" \
                "$KAK_SPEC_DELIMITER" \
                "$4" \
                "$KAK_SPEC_DELIMITER"
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
            (-expect-*-[\[\{\(\<]) # Balance quotes for kak: )
                opening_symbol="${1##*-}"
                closing_symbol="$(echo "$opening_symbol" | tr '[{(<' ']})>')"
                expansion="${1%-*}"
                expansion="${expansion#-expect-}"
                comparisons="$comparisons comparison_explicit $(kak_escape "$expansion")"
                while true
                do
                    if test "$#" -eq 0; then
                        kak_escape fail Missing closing delimiter "'$closing_symbol'"
                        exit
                    fi
                    shift
                    case "$1" in
                    ("$closing_symbol")
                        break
                        ;;
                    (*)
                        comparisons="$comparisons $(kak_escape "$1")"
                        ;;
                    esac
                done
                shift
                comparisons="$comparisons $KAK_SPEC_DELIMITER $expansion $KAK_SPEC_DELIMITER"
                ;;
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
            (-exec)
                option_eval="execute-keys $(kak_escape "$2")"
                # Prettify reports by removing a trailing space produced by kak_escape.
                option_eval="${option_eval% }"
                shift 2
                ;;
            (-*)
                kak_escape fail "spec: Unknown option '$1'"
                exit 1
                ;;
            (*)
                break
                ;;
            esac
        done
        # Apply option defaults that depend on other options.
        true "${option_title:="$option_exec"}"
        true "${option_title:="$option_eval"}"
        # Skip this assert if requested to.
        for option in eval input title
        do
            eval "echo \"\$option_$option\" |
                grep -Eq \"\$KAK_SPEC_option_$option\" ||
                    exit"
        done
        # Call spec-scratch-eval with the user given command and with a <final-command> that
        # sends a message to the translator.
        kak_escape spec-scratch-eval "$option_input" "$option_eval" \
            "spec-send \
                message_assert \
                $error_comparison \
                $comparisons \
                END_OF_EXPECTATIONS \
                $(kak_escape "$option_title" "$option_input" "$option_eval")
            " \
    )
)

define-command spec-context \
    -params 2 \
    -docstring 'spec-context <context-message> <commands>:
Evaluates <commands> so that any assertions in them have context information.' \
%(
    # Save the current length of *debug*.
    evaluate-commands -buffer *debug* %(
        set-option global scratch_unit_test_debug_line_count %val(buf_line_count)
    )
    spec-send message_scope_begin %arg(1) %opt(scratch_unit_test_debug_line_count)
    try %(
        evaluate-commands %arg(2)
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
    echo -to-file %opt(spec_fifo) -quoting kakoune %arg(@)
    # Send an unquoted newline to signal the end of the message.
    # The -to-file switch disables the usual trailing newline.
    echo -to-file %opt(spec_fifo) '
'
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
