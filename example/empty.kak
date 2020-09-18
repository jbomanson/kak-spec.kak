require-module spec

spec \
    -title 'Test set-register with many arguments' \
    -eval %(
        set-register dquote one two three
    ) \
    -expect-%reg(dquote)-( \
        'one' 'two' 'three' \
    )

spec \
    -title 'Test set-register with zero arguments' \
    -eval %(
        set-register dquote
    ) \
    -expect-%reg(dquote)-( '' )

spec \
    -title 'Smoke test: Test set-register with zero arguments' \
    -eval %(
        set-register dquote
    ) \
    -expect-%reg(dquote)-( )

spec \
    -title 'Test set-register with some empty arguments' \
    -eval %(
        set-register dquote 'one' '' 'three' '' 'five'
    ) \
    -expect-%reg(dquote)-( 'one' '' 'three' '' 'five' )

spec \
    -title 'Smoke test: Test set-register with some empty arguments' \
    -eval %(
        set-register dquote 'one' '' '' '' 'five'
    ) \
    -expect-%reg(dquote)-( 'one' '' 'three' '' 'five' )
