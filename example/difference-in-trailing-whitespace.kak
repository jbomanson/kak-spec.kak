require-module spec

spec \
    -title "Smoke test: Difference in trailing whitespace" \
    -input "Some input" \
    -eval %(
        execute-keys 'sinput<ret>coutput <esc>%H'
    ) \
    -expect-%val(selection) "Some output"
