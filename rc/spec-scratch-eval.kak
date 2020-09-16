provide-module spec-scratch-eval %~

declare-option \
    -docstring 'The most recent output of spec-scratch-eval' \
    str scratch_commands_output

# An increasing number used in naming temporary scratch buffers.
declare-option -hidden int scratch_commands_id 0

# A temporary variable used to hold caught errors.
declare-option -hidden str scratch_commands_error

define-command spec-scratch-eval \
    -params 3 \
    -docstring "spec-scratch-eval <input> <command> <final-command>:
TODO: Describe." \
%(
    evaluate-commands -save-regs 't' %(
        # Open a temporary scratch buffer with a unique name.
        set-option -add global scratch_commands_id 1
        set-register t "*spec-scratch-eval-%opt(scratch_commands_id)*"
        edit! -scratch "%reg(t)"
        try %(
            # Initialize the buffer with <input>.
            evaluate-commands -save-regs '"' %(
                set-register dquote %arg(1)
                execute-keys '<a-P>'
            )
            # Evaluate <command>... and save any raised error.
            set-option global scratch_commands_error ""
            set-option global scratch_commands_output ""
            evaluate-commands -save-regs t %arg(2)
            # TODO: Ensure that we are in normal mode.
            # Check whether the command changed the current buffer.
            evaluate-commands %sh(
                eval "$KAK_SPEC_PRELUDE_SH"
                if test "$kak_buffile" != "$kak_reg_t"; then
                    kak_quote fail "temporary buffer changed to $kak_buffile"
                fi
            )
            # Extract the output of the command.
            execute-keys '%H'
            set-option global scratch_commands_output "%val(selection)"
        ) catch %(
            # Swallow any raised error, but save it for use in <final-command>.
            set-option global scratch_commands_error "%val(error)"
        )
        evaluate-commands -save-regs t %arg(3)
        delete-buffer "%reg(t)"
    )
)

~
