require-module kak-spec

kak-spec \
    -title "Test selection of a substring" \
    -input "one-two-three" \
    -exec stwo<ret> \
    -expect-%val(selection) "two"

kak-spec \
    -title "Test selection after no actions" \
    -input "one-two-three" \
    -expect-%val(selection) "one-two-three"

kak-spec \
    -title "Test selection of everything" \
    -input "one-two-three" \
    -exec '%H' \
    -expect-%val(selection) "one-two-three"

kak-spec \
    -title "Test selection of many substrings" \
    -input "one-two-three" \
    -exec 's\w+<ret>' \
    -expect-%val(selection) "three"
