require-module spec

spec-assert \
    -title 'Test "selections" of a substring' \
    -input 'one-two-three' \
    -exec stwo<ret> \
    -expect-%val(selections) 'two'

spec-assert \
    -title 'Test "selections" after no actions' \
    -input 'one-two-three' \
    -expect-%val(selections) 'one-two-three'

spec-assert \
    -title 'Smoke test: Test "selections" of everything' \
    -input 'one-two-three' \
    -exec '%H' \
    -expect-%val(selections) 'fire'

spec-assert \
    -title 'Smoke test: Test "selections" of many substrings' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections) 'fire'
