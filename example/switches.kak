require-module scratch-unit-test

scratch-unit-test-assert \
    -expect-%val(selection_length) 1 \
    "c" \
    "xyz" %(
        execute-keys cword<esc>
    )

scratch-unit-test-assert \
    -expect-%val(selection_length) 4 \
    "Test selection length after c" "xyz" %(
        execute-keys cword<esc>
    )

scratch-unit-test-assert \
    -expect-%val(selection_length) 4 \
    -expect-%val(error) \
    "This is an error" \
    "Test an error" \
    "xyz" %(
        execute-keys cword<esc>
        fail "This is an error"
    )
