require-module spec

spec \
    -expect-%val(selection_length) 1 \
    -title "c" \
    -input "xyz" \
    -eval %(
        execute-keys cword<esc>
    )

spec \
    -expect-%val(selection_length) 4 \
    -title "Test selection length after c" \
    -input "xyz" \
    -eval %(
        execute-keys cword<esc>
    )

spec \
    -expect-%val(selection_length) 4 \
    -expect-%val(error) "This is an error" \
    -title "Test an error" \
    -input "xyz" \
    -eval %(
        execute-keys cword<esc>
        fail "This is an error"
    )
