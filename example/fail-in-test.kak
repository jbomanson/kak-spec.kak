require-module spec

spec-assert \
    -title "Test a failure inside a test" \
    -input "Just some input" \
    -eval %(
        fail "This is a failure inside a test"
    ) \
    -expect-%val(error) "This is a failure inside a test"

spec-assert \
    -title "Smoke test: Test a failure inside a test" \
    -input "Just some input" \
    -eval %(
        fail "This is a failing failure inside a test"
    ) \
    -expect-%val(error) "This is a failure inside a test"
