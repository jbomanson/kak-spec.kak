require-module spec

spec \
    -title 'Test "selections" of a substring' \
    -input 'one-two-three' \
    -exec stwo<ret> \
    -expect-%val(selections) 'two'

spec \
    -title 'Test "selections" after no actions' \
    -input 'one-two-three' \
    -expect-%val(selections) 'one-two-three'

spec \
    -title 'Test "selections" of many substrings using kak-spec [] syntax' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections)-[ \
        'one' 'two' 'three' \
    ]

spec \
    -title 'Test "selections" of many substrings using kak-spec () syntax' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections)-( \
        'one' 'two' 'three' \
    )

spec \
    -title 'Test "selections" of many substrings using kak-spec {} syntax' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections)-{ \
        'one' 'two' 'three' \
    }

spec \
    -title 'Test "selections" of many substrings using kak-spec <> syntax' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections)-< \
        'one' 'two' 'three' \
    >

spec \
    -title 'Smoke test: Test "selections" of everything' \
    -input 'one-two-three' \
    -exec '%H' \
    -expect-%val(selections) 'fire'

spec \
    -title 'Smoke test: Test "selections" of many substrings against a single string' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections) 'fire'

spec \
    -title 'Smoke test: Test "selections" of many substrings' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections)-[ \
        'one' 'two' 'three' 'four' \
    ]
