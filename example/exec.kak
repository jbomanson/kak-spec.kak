require-module kak-spec

kak-spec \
    -title "Test selection length after c" \
    -input "xyz" \
    -exec cword<esc> \
    -expect-%val(selection_length) 1

kak-spec \
    -title "Smoke test: Test selection length after c" \
    -input "xyz" \
    -exec cword<esc> \
    -expect-%val(selection_length) 4

kak-spec \
    -title "Test exec with an argument containing single quotes (')" \
    -input "xyz" \
    -exec c'word'<esc>%H \
    -expect-%val(selection) "'word'"
