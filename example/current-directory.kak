require-module kak-spec

kak-spec \
    -title "Smoke test: Print current directory outside a test" \
    -input %sh(printf "%s" "$PWD") \
    -expect-%val(selection) ""

kak-spec \
    -title "Smoke test: Print current directory inside a test" \
    -input "Some input" \
    -eval %(fail %sh(printf "%s" "$PWD"))
