require-module spec

spec \
    -title "Test a failure inside a test" \
    -input "Just some input" \
    -eval %(
        fail "This is a failure inside a test"
    ) \
    -expect-%val(error) "This is a failure inside a test"

spec \
    -title "Smoke test: Test a failure inside a test" \
    -input "Just some input" \
    -eval %(
        fail "This is a failing failure inside a test"
    ) \
    -expect-%val(error) "This is a failure inside a test"
