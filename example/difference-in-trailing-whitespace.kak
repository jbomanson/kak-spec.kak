require-module spec

spec-assert \
    -title "Smoke test: Difference in trailing whitespace" \
    -input "Some input" \
    -eval %(
        execute-keys 'sinput<ret>coutput <esc>%'
    ) \
    -expect-%val(selection) "Some output"
