require-module scratch-unit-test

scratch-unit-test-assert \
    -expect-%val(selection_length) 1 \
    -title "c" \
    -input "xyz" \
    -eval %(
        execute-keys cword<esc>
    )

scratch-unit-test-assert \
    -expect-%val(selection_length) 4 \
    -title "Test selection length after c" \
    -input "xyz" \
    -eval %(
        execute-keys cword<esc>
    )

scratch-unit-test-assert \
    -expect-%val(selection_length) 4 \
    -expect-%val(error) "This is an error" \
    -title "Test an error" \
    -input "xyz" \
    -eval %(
        execute-keys cword<esc>
        fail "This is an error"
    )
