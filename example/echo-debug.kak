require-module kak-spec

kak-spec \
    -title "Smoke test: Print something to the debug buffer" \
    -input "Just some text" \
    -eval %(
        echo -debug Hello debug buffer!
    ) \
    -expect-%val(selection) "Some other text"
