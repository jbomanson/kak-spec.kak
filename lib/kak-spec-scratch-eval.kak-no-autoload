provide-module kak-spec-scratch-eval %~

# An increasing number used in naming temporary scratch buffers.
declare-option -hidden int scratch_commands_id 0

# A temporary variable used to hold caught errors.
declare-option -hidden str scratch_commands_error

define-command kak-spec-scratch-eval \
    -params 3 \
    -docstring "kak-spec-scratch-eval <input> <command> <final-command>:
TODO: Describe." \
%(
    evaluate-commands -save-regs '' %(
        # Open a temporary scratch buffer with a unique name.
        set-option -add global scratch_commands_id 1
        edit! -scratch "*kak-spec-scratch-eval-%opt(scratch_commands_id)*"
        try %(
            # Initialize the buffer with <input>.
            evaluate-commands -save-regs '"' %(
                set-register dquote %arg(1)
                execute-keys '<a-P>'
            )
            # Evaluate <command>... and save any raised error.
            set-option global scratch_commands_error ""
            evaluate-commands -save-regs '' %arg(2)
            # TODO: Ensure that we are in normal mode.
        ) catch %(
            # Swallow any raised error, but save it for use in <final-command>.
            set-option global scratch_commands_error "%val(error)"
        )
        evaluate-commands -save-regs '' %arg(3)
        delete-buffer "*kak-spec-scratch-eval-%opt(scratch_commands_id)*"
    )
)

~
