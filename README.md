# kak-spec

[![License](https://img.shields.io/github/license/jbomanson/kak-spec.kak)](https://opensource.org/licenses/Apache-2.0)

**kak-spec** is a unit test framework for
[Kakoune](https://github.com/mawww/kakoune) scripts and plugins.
The framework is designed to help plugin developers, but it can also be useful for studying the
behavior of the kakoune scripting language.
Using **kak-spec** is a matter of
- installing it,
- writing unit tests in kakoune script, and
- running the tests using an executable called **kak-spec**.

## Example

Example test [example/selections.kak-spec](https://github.com/jbomanson/kak-spec.kak/tree/main/example/selections.kak-spec):
```kak
kak-spec \
    -title 'Test "selections" of a substring' \
    -input 'one-two-three' \
    -exec stwo<ret> \
    -expect-%val(selections) 'two'

kak-spec \
    -title 'Test "selections" after no actions' \
    -input 'one-two-three' \
    -expect-%val(selections) 'one-two-three'

kak-spec \
    -title 'Test "selections" of many substrings using kak-spec [] syntax' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections)-[ \
        'one' 'two' 'three' \
    ]

kak-spec \
    -title 'Test "selections" of many substrings using kak-spec () syntax' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections)-( \
        'one' 'two' 'three' \
    )

kak-spec \
    -title 'Test "selections" of many substrings using kak-spec {} syntax' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections)-{ \
        'one' 'two' 'three' \
    }

kak-spec \
    -title 'Test "selections" of many substrings using kak-spec <> syntax' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections)-< \
        'one' 'two' 'three' \
    >

kak-spec \
    -title 'Test "selections" of everything (this should fail)' \
    -input 'one-two-three' \
    -exec '%H' \
    -expect-%val(selections) 'fire'

kak-spec \
    -title 'Test "selections" of many substrings against a single string (this should fail)' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections) 'fire'

kak-spec \
    -title 'Test "selections" of many substrings (this should fail)' \
    -input 'one-two-three' \
    -exec 's\w+<ret>' \
    -expect-%val(selections)-[ \
        'one' 'two' 'three' 'four' \
    ]
```

Test output produced by `kak-spec example/selections.kak-spec`:
```markdown
# kak-spec

......FFF

## Failures

### Test "selections" of everything (this should fail)

- Input:
      1|one-two-three

- Evaluated commands:
      1|execute-keys -with-hooks -with-maps '%H'

- Expected %val(selections) with 1 element:
      1:  1|fire

- Actual %val(selections) with 1 element:
      1:  1|one-two-three

- How to run this test:
      1|bin/kak-spec -title \^Test\\\ \"selections\"\\\ of\\\ everything\\\ \\\(this\\\ should\\\ fail\\\)\$ example/selections.kak-spec

### Test "selections" of many substrings against a single string (this should fail)

- Input:
      1|one-two-three

- Evaluated commands:
      1|execute-keys -with-hooks -with-maps 's\w+<ret>'

- Expected %val(selections) with 1 element:
      1:  1|fire

- Actual %val(selections) with 3 elements:
      1:  1|one
      2:  1|two
      3:  1|three

- How to run this test:
      1|bin/kak-spec -title \^Test\\\ \"selections\"\\\ of\\\ many\\\ substrings\\\ against\\\ a\\\ single\\\ string\\\ \\\(this\\\ should\\\ fail\\\)\$ example/selections.kak-spec

### Test "selections" of many substrings (this should fail)

- Input:
      1|one-two-three

- Evaluated commands:
      1|execute-keys -with-hooks -with-maps 's\w+<ret>'

- Expected %val(selections) with 4 elements:
      1:  1|one
      2:  1|two
      3:  1|three
      4:  1|four

- Actual %val(selections) with 3 elements:
      1:  1|one
      2:  1|two
      3:  1|three

- How to run this test:
      1|bin/kak-spec -title \^Test\\\ \"selections\"\\\ of\\\ many\\\ substrings\\\ \\\(this\\\ should\\\ fail\\\)\$ example/selections.kak-spec

## Summary

- Finished in 81.22 milliseconds
- 9 examples, 3 failures, 0 errors
```

More examples can be found in the
[example](https://github.com/jbomanson/kak-spec.kak/tree/main/example) directory.

## Dependencies

- ruby

- [prelude.kak](https://github.com/alexherbo2/prelude.kak)

## Installation of kak-spec and the prelude.kak dependency

The following steps install a `kak-spec` executable under
`/path/to/prefix/directory/bin`, and man pages under
`/path/to/prefix/directory/share/man/man1`.
A typical choice for `/path/to/prefix/directory` would be `~/.local`.

### Alternative #1: With plug.kak

You can install **kak-spec** using the
[plug.kak](https://github.com/robertmeta/plug.kak) plugin manager by extending
your `kakrc` with:

```kak
plug "alexherbo2/prelude.kak"
plug "jbomanson/kak-spec.kak" do %(
    make install PREFIX=/path/to/prefix/directory
)
```

Then start Kakoune and run `:plug-install`.

### Alternative #2: Manually

```sh
cd /path/to/plugins/directory
git clone --depth=1 https://github.com/alexherbo2/prelude.kak
git clone --depth=1 https://github.com/jbomanson/kak-spec.kak
cd kak-spec && make install PREFIX=/path/to/prefix/directory
# OPTIONAL: Place a soft link of the rc directory in your %val(config)/autoload directory.
```

After the installation is done, the cloned directories should stay where they are.
This is important, because the installation process makes soft links to content inside the
`kak-spec` directory and `kak-spec` expects to find `prelude.kak` from a location next to it.

## Usage

#### Defining Tests: Kakoune Command Usage

**kak-spec** _option_...:
Define a unit test.
This command is available only in kakoune scripts evaluated with the `kak-spec` executable.

- **-title** _title_

    A title to be shown if the test fails.

- **-input** _input_

    Initial contents written to and selected in the scratch buffer where the test begins.
    The scratch buffer will always contain a newline in addition to _input_.

- **-eval** _commands_

    Commands evaluated in the test.
    This is mutually exclusive with **-exec**.
    For example:

    - `-eval %(set-register dquote "Hello world!"; execute-keys R)` replaces the buffer contents with a greeting.

- **-exec** _keys_

    A shorthand for **-eval** %(**execute-keys** **-with-hooks** **-with-maps** _keys_).
    This is mutually exclusive with -eval.
    For example:

    - `-exec %(cHello world!_esc_)` replaces the buffer contents with a greeting.

- **-expect-_expansion_** _value_

    Expects kakoune _expansion_ to expand to _value_.
    For example:

    - `-expect-%val(selection) "Hello world!"`         checks that the main selection consists of exactly the string "Hello world!",

    - `-expect-%val(error)     "Something went wrong"` checks that the test results in a failure with this exact error.

    For more flexible matching, _value_ can be given in one of the following forms:

    - **bool(**_b_**)**

      Matches different string representations of the boolean _b_.
      For matching, "true" and "yes" are considered identical and "false" and "no" are considered identical.
      For example:

      - `-expect-%val(autoreload) "bool(yes)"`   checks that the autoreload value is either "true" or "yes",

      - `-expect-%val(autoreload) "bool(false)"` checks that the autoreload value is either "false" or "no".

    - **regex(**_r_**)**

      Matches strings fully matched by the regular expression _r_.
      In the expression, "." matches any character, including newlines.
      For example:

      - `-expect-%val(error)     "regex(.+)"`  checks that there was an error with a nonempty message,

      - `-expect-%val(selection) "regex(\d+)"` checks that the main selection consists of only digits.

    - **str(**_s_**)**

      Expects kakoune _expansion_ to expand to string _s_.
      This works mostly the same as a plain _value_ but with the advantage of also allowing strings _s_ that are themselves of the form _word_(...) and might be confused for a special matcher.
      For example:

      - `-expect-%val(selection) "foo(123)"` checks that the main selection consists of exactly the string "foo(123)".

- **-expect-_expansion_-(** _value_... **)**

    Expects kakoune _expansion_ to expand to an array matching the given values.
    The delimiters can be (), [], {}, or <>.
    For example:

    - `-expect-%val(selections)-[ "word" "pair of words" ]`

    - `-expect-%val(selections)-[ "word" "regex(pair.+words)" ]`

    Each _value_ can also specify a **bool**, **regex**, or **str** in the same manner as when matching single values.


### Running Tests: Command Line Usage


Usage: **kak-spec** [_option_...] _script_...

Runs tests specified in kakoune _script_ files or in files under a `spec` directory matching the pattern `*.kak-spec`.

Each _script_ is ran in a separate **temporary kakoune session**.
Different _script_ runs may happen in any order, possibly in parallel.
However, tests defined in the same source file:
- are executed in they order they are defined,
- can use options, commands, etc defined before them in tests or on the top level, and
- may inadvertently disturb one another due to the above.

See <https://github.com/jbomanson/kak-spec.kak> for instructions on how to write tests.

Options:
- **-color**=(never|always|auto)
                  **--** Print terminal color codes never, always, or only when the output is to a terminal.
- **-eval**=_regex_     **--** Run only tests whose eval  matches _regex_.
- **-input**=_regex_    **--** Run only tests whose input matches _regex_.
- **-title**=_regex_    **--** Run only tests whose title matches _regex_.

- **-h**, **-help**, **--help** **--** Show this help message
- **-version**          **--** Show the current version of **kak-spec**

## PROTIP: Rerunning tests as they change

**kak-spec** works well with file watcher programs such as
[entr](http://eradman.com/entrproject/) that rerun arbitrary commands as some files change.
For example, in a git project with test files in a directory hierarchy under `kak-spec`, one could
run:
```sh
while true; do
  git ls-files | entr -cd kak-spec
done
```
These commands would rerun kak-spec on *.kak-spec files under `kak-spec` whenever any file currently
tracked by git changes.
