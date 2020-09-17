require-module spec

spec-assert \
    -title "Change multiple output lines" \
    -input "First input line
Second input line
Third input line" \
    -eval %(
        execute-keys 'sinput<ret>coutput<esc>%H'
    ) \
    -expect-%val(selection) "First output line
Second output line
Third output line"

spec-assert \
    -title "Smoke test: Change multiple output lines" \
    -input "First input line
Second input line
Third input line" \
    -eval %(
        execute-keys 'sinput<ret>coutput<esc>%H'
    ) \
    -expect-%val(selection) "First line
Second line
Third line"
