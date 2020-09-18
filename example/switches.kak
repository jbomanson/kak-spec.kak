require-module spec

spec \
    -expect-%val(selection_length) 1 \
    -title "c" \
    -input "xyz" \
    -eval %(
        execute-keys cword<esc>
    )

spec \
    -expect-%val(selection_length) 100 \
    -title "Smoke test: Test selection length after c" \
    -input "xyz" \
    -eval %(
        execute-keys cword<esc>
    )

spec \
    -expect-%val(selection_length) 4 \
    -expect-%val(error) "This is an error" \
    -title "Smoke test: Fail in test" \
    -input "xyz" \
    -eval %(
        execute-keys cword<esc>
        fail "This is an error"
    )
