provide-module scratch-commands %~

# TODO: Unit test
# TODO: Remove redundant -save-regs "" arguments to evaluate-commands
# TODO: Fix this to work with dquote

declare-option \
    -docstring 'The most recent output of scratch-commands' \
    str-list scratch_commands_output

# An increasing number used in naming temporary scratch buffers.
declare-option -hidden int scratch_commands_id 0

# A temporary variable used to hold caught errors.
declare-option -hidden str scratch_commands_error

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

define-command scratch-commands \
    -params .. \
    -docstring "scratch-commands <input> <command>...:
TODO: Describe." \
%(
    # Ensure that at least some input is given.
    evaluate-commands %sh(
        test "$1" && printf "%s" "nop"
    ) fail "scratch-commands: expected a non-empty <input>"
    evaluate-commands -save-regs 't' %(
        # Open a temporary scratch buffer with a unique name.
        set-option -add global scratch_commands_id 1
        set-register t "*scratch-commands-%opt(scratch_commands_id)*"
        edit! -scratch "%reg(t)"
        try %(
            # Initialize the buffer with <input>.
            evaluate-commands -save-regs '"' %(
                set-register dquote %arg(1)
                execute-keys '<a-P>'
            )
            # Evaluate <command>... and save any raised error.
            set-option global scratch_commands_error ""
            set-option global scratch_commands_output
            evaluate-commands -save-regs t %sh(
                eval "$kak_opt_scratch_commands_sh_prelude"
                shift 1
                printf "%s" "evaluate-commands "
                kak_quote "$@"
            )
            # TODO: Ensure that we are in normal mode.
            # Check whether the command changed the current buffer.
            evaluate-commands %sh(
                eval "$kak_opt_scratch_commands_sh_prelude"
                if test "$kak_buffile" != "$kak_reg_t"; then
                    kak_quote fail "temporary buffer changed to $kak_buffile"
                fi
            )
            # Extract the output of the command.
            execute-keys '%H'
            set-option global scratch_commands_output "%val(selection)"
        ) catch %(
            set-option global scratch_commands_error "%val(error)"
        )
        delete-buffer "%reg(t)"
        # Present any error caught when evaluating user commands.
        evaluate-commands %sh(
            test "$kak_opt_scratch_commands_error" || printf "%s" "nop"
        ) fail "scratch-commands: %opt(scratch_commands_error)"
        set-option global scratch_commands_error ""
    )
)

~
