declare-option -hidden str scratch_unit_test_path %sh(
    printf "%s" "${kak_source%.kak}"
)

provide-module scratch-unit-test %~

require-module scratch-commands

declare-option \
    -docstring 'The total number of expectation failures and raised errors' \
    int scratch_unit_test_failure_count 0

declare-option \
    -docstring 'The total number of tests so far' \
    int scratch_unit_test_test_count 0

# TODO.
declare-option -hidden str scratch_unit_test_suite_file

# TODO.
declare-option -hidden str scratch_unit_test_context_message

# TODO
declare-option -hidden str scratch_unit_test_fifo
declare-option -hidden str scratch_unit_test_fifo_holder_pid

declare-option -hidden str scratch_commands_sh_prelude %(
    kak_quote () {
        local delimiter=""
        local string
        for string
        do
            printf "%s" "$delimiter"
            printf "'"
            printf "%s" "$string" | sed "s/'/''/g"
            printf "'"
            delimiter=" "
        done
        printf "\n"
    }
)

evaluate-commands %sh(
    if ! test -d "$SCRATCH_UNIT_TEST_DIR"; then
        printf "%s\n" "echo -debug scratch-unit-test.kak: sourced but inactive"
        exit
    fi
    PATH="$kak_opt_scratch_unit_test_path:$PATH"
    eval "$kak_opt_scratch_commands_sh_prelude"
    if ! which "scratch_unit_test_translate" >/dev/null; then
        echo "${0##*/}: missing executable \"scratch_unit_test_translate\"";
        exit 1;
    fi >&2
    # Set up a fifo.
    mkfifo "$SCRATCH_UNIT_TEST_DIR/fifo"
    kak_quote set-option global scratch_unit_test_fifo "$SCRATCH_UNIT_TEST_DIR/fifo"
    # Keep the fifo open.
    sleep 100000d >"$SCRATCH_UNIT_TEST_DIR/fifo" 2>&1 </dev/null &
    kak_quote set-option global scratch_unit_test_fifo_holder_pid $!
    # Listen to the fifo.
    {
        scratch_unit_test_translate \
            "$SCRATCH_UNIT_TEST_DIR/fifo" \
            >"$SCRATCH_UNIT_TEST_LOG" \
            2>&1
    } >/dev/null 2>&1 </dev/null &
    printf "%s\n" "echo -debug fifo: $scratch_dir/fifo"
)

echo -debug scratch_unit_test_fifo: "%opt(scratch_unit_test_fifo)"

hook -always global KakEnd .* %(
    %sh(
        {
            if test -p "$kak_opt_scratch_unit_test_fifo"; then
                printf "%s\n" "quit" >"$kak_opt_scratch_unit_test_fifo"
            fi
            if test "$kak_opt_scratch_unit_test_fifo_holder_pid" -gt 0; then
                kill "$kak_opt_scratch_unit_test_fifo_holder_pid"
            fi
        } 2>&1 </dev/null &
    )
)

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
        evaluate-commands %sh(
            eval "$kak_opt_scratch_commands_sh_prelude"
            shift 1
            printf "%s" "scratch-commands $(kak_quote "$1") "
            shift 3
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
            if test -w "$kak_opt_scratch_unit_test_fifo"; then
                {
                    printf "%s\n" "log"
                    printf "%s\n" "$kak_quoted_reg_a" | wc -l
                    printf "%s\n" "$kak_quoted_reg_a"
                } >"$kak_opt_scratch_unit_test_fifo"
            fi
        )
    )
)

define-command scratch-unit-test-suite \
    -params 2 \
    -docstring 'scratch-unit-test-suite <file>: TODO' \
%(
    set-option global scratch_unit_test_suite_file "%arg(1)"
    evaluate-commands "%arg(2)"
    set-option global scratch_unit_test_suite_file ""
)

define-command scratch-unit-test-context \
    -params 2 \
    -docstring 'scratch-unit-test-context <context-message> <commands>:
Evaluates <commands> so that any assertions in them have context information.' \
%(
    evaluate-commands %sh(
        test "$kak_opt_scratch_unit_test_suite_file" || printf "%s" "nop"
    ) fail "scratch-unit-test-context: must be called within scratch-unit-test-suite"
    set-option global scratch_unit_test_context_message "%arg(1)"
    evaluate-commands "%arg(2)"
    set-option global scratch_unit_test_context_message ""
)

~
