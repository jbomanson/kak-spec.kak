require-module scratch-unit-test

scratch-unit-test-assert \
    -title "Smoke test: Difference in trailing whitespace" \
    -input "Some input" \
    -eval %(
        execute-keys 'sinput<ret>coutput <esc>%'
    ) \
    -expect-%val(selection) "Some output"
