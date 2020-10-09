require-module kak-spec

kak-spec \
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

kak-spec \
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
