require-module scratch-unit-test

scratch-unit-test-suite "this string is not the name of an existing file" %(
    fail "This failure should not be reached"
)
