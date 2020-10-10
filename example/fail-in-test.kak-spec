require-module kak-spec

kak-spec \
    -title "Test a failure inside a test" \
    -input "Just some input" \
    -eval %(
        fail "This is a failure inside a test"
    ) \
    -expect-%val(error) "This is a failure inside a test"

kak-spec \
    -title "Smoke test: Test a failure inside a test" \
    -input "Just some input" \
    -eval %(
        fail "This is a failing failure inside a test"
    ) \
    -expect-%val(error) "This is a failure inside a test"
