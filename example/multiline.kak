require-module scratch-unit-test

scratch-unit-test-assert \
    -title "Change multiple output lines" \
    -input "First input line
Second input line
Third input line" \
    -eval %(
        execute-keys 'sinput<ret>coutput<esc>%'
    ) \
    -expect-%val(selection) "First output line
Second output line
Third output line"

scratch-unit-test-assert \
    -title "Smoke test: Change multiple output lines" \
    -input "First input line
Second input line
Third input line" \
    -eval %(
        execute-keys 'sinput<ret>coutput<esc>%'
    ) \
    -expect-%val(selection) "First line
Second line
Third line"
