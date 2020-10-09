# kak-spec

[![License](https://img.shields.io/github/license/jbomanson/kak-spec)](https://opensource.org/licenses/Apache-2.0)

**kak-spec** is a unit test framework for
[Kakoune](https://github.com/mawww/kakoune) scripts and plugins.
The framework is designed to help plugin developers, but it can also be useful for studying the
behavior of the kakoune scripting language.
Using **kak-spec** is a matter of
- installing **kak-spec**
- writing unit tests in kakoune script using the provided **spec** module, and
- running the tests form the command line using **kak-spec**.

## Dependencies

- ruby

- [prelude.kak](https://github.com/alexherbo2/prelude.kak)

## Installation of kak-spec and the prelude.kak dependency

The following alternative steps will install a `kak-spec` executable under
`/path/to/prefix/directory/bin`, and man pages under
`/path/to/prefix/directory/share/man/man1`.
A typical choice for `/path/to/prefix/directory` would be `~/.local`.

### Alternative #1: With plug.kak

You can install **kak-spec** using the
[plug.kak](https://github.com/andreyorst/plug.kak) plugin manager by extending
your `kakrc` with:

```kak
plug "alexherbo2/prelude.kak"
plug "jbomanson/kak-spec" noload do %(
    make install PREFIX=/path/to/prefix/directory
)
```

Then start Kakoune and run `:plug-install`.

### Alternative #2: Manually

```sh
cd /path/to/plugins/directory
git clone --depth=1 https://github.com/alexherbo2/prelude.kak
git clone --depth=1 https://github.com/jbomanson/kak-spec
cd kak-spec && make install PREFIX=/path/to/prefix/directory
```

After the installation is done, the cloned directories should stay where they are.
This is important, because the installation process makes soft links to content inside the
`kak-spec` directory and `kak-spec` expects to find `prelude.kak` from a location next to it.

## Usage

### Writing tests

Tests are written in kakoune source files that call `require-module spec` and then use the
provided kakoune command **spec** to define tests.
Here is an example test file:
```kak
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
```

More examples can be found in the
[example](https://github.com/jbomanson/kak-spec/example) directory.

#### Kakoune Command Usage

**spec** _option_...: Define a unit test.

- **-title** _title_
  A title to be shown if the test fails.

- **-input** _input_
  Initial contents written to and selected in the scratch buffer where the test begins.
  The scratch buffer will always contain a newline in addition to _input_.

- **-eval** _commands_
  Commands evaluated in the test.
  Mutually exclusive with **-exec**.
  - Example: **-eval** %(set**-register** dquote "Hello world!"; execute**-keys** R)

- **-exec** _keys_
  Keys to be executed in the buffer.
  Mutually exclusive with **-eval**.
  - Example: **-exec** %(cHello world!)

- **-expect-_expansion_** _value_
  Expects kakoune _expansion_ to expand to _value_ at the end of the test.
  - Example: **-expect-%val(selection)** "Hello world!"
  - Example: **-expect-%val(error)** "Something went wrong"

- **-expect-_expansion_-(** _value_... **)**
  Expects kakoune _expansion_ to expand to the given array.
  The delimiters can be (), [], {}, or <>.
  - Example: **-expect-%val(selections)-[** "word" "pair of words" **]**

### Running Tests: Command Line Usage


Usage: **kak-spec** [_option_...] _script_...

Runs tests specified in given kakoune _script_ files.

Each _script_ is ran in a separate **temporary kakoune session**.
Different _script_ runs may happen in any order, possibly in parallel.
However, tests defined in the same source file:
- are executed in they order they are defined,
- can use options, commands, etc defined before them in tests or on the top level, and
- may inadvertently disturb one another due to the above.

See <https://github.com/jbomanson/**kak-spec**> for instructions on how to write tests.

Options:
- **-eval**=_regex_     **--** Run only tests whose eval  matches _regex_.
- **-input**=_regex_    **--** Run only tests whose input matches _regex_.
- **-title**=_regex_    **--** Run only tests whose title matches _regex_.

- **-h**, **-help**, **--help** **--** Show this help message
- **-version**          **--** Show the current version of **kak-spec**

## PROTIP: Rerunning tests as they change

**kak-spec** works well with file watcher programs such as
[entr](http://eradman.com/entrproject/) that rerun arbitrary commands as some files change.
For example, in a git project with test files in a directory hierarchy under `spec`, one could
run:
```sh
while true; do
  git ls-files | entr -cd kak-spec spec/**/*.kak
done
```
These commands would rerun kak-spec on *.kak files under `spec` whenever any file currently
tracked by git changes.
