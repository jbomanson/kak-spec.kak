#! /bin/sh

root_dir="$( ( cd "${0%/*}/.."; pwd ) )"

# A magic string that is used in internal communications of kak-spec.
# It is assumed that inone of the arguments passed to the kakoune kak-spec command.
KAK_SPEC_DELIMITER="bf152d0f8a1e657258d3059c47ff9625057d5ab0515eef9d6eec61592372af98"
export KAK_SPEC_DELIMITER

REPORTER="$root_dir/lib/reporter.rb"

version=0.1.0

scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/kak-spec.XXXXXXXX")

clean_up () {
    code=$?
    test "$(printf "%s" $reporter_pid $kak_pid_list $fifo_holder_pid_list)" &&
        kill $reporter_pid $kak_pid_list $fifo_holder_pid_list
    rm -r "$scratch_dir"
    exit $code
}

trap "trap - TERM && clean_up" INT TERM EXIT

KAK_SPEC_DIR="$scratch_dir"
export KAK_SPEC_DIR

#
#	Locate the prelude.kak plugin
#

for candidate_plugin_dir in "$root_dir/.." "$HOME/.config/kak/plugins"
do
    candidate="$candidate_plugin_dir/prelude.kak/rc/prelude.sh"
    if test -f "$candidate"; then
        KAK_SPEC_PRELUDE_PATH="$candidate"
        break
    fi
done

if ! test "$KAK_SPEC_PRELUDE_PATH"; then
    echo "${0##*/}: missing dependency \"prelude.kak\""
    exit 1
fi >&2
export KAK_SPEC_PRELUDE_PATH
. "$KAK_SPEC_PRELUDE_PATH"

#
#       Parse Command Line Arguments
#

usage ()
{
    cat <<EOF
Usage: kak-spec [<option>...] <script>...

Runs tests kak-specified in given kakoune <script> files.

Each <script> is ran in a separate **temporary kakoune session**.
Different <script> runs may happen in any order, possibly in parallel.
However, tests defined in the same source file:
- are executed in they order they are defined,
- can use options, commands, etc defined before them in tests or on the top level, and
- may inadvertently disturb one another due to the above.

See <https://github.com/jbomanson/kak-spec> for instructions on how to write tests.

Options:
-eval=<regex>     -- Run only tests whose eval  matches <regex>.
-input=<regex>    -- Run only tests whose input matches <regex>.
-title=<regex>    -- Run only tests whose title matches <regex>.

-h, -help, --help -- Show this help message
-version          -- Show the current version of kak-spec
EOF
}

while true
do
    argument="$1"
    case "$argument" in
    --?*)
        # Normalize double dashes into single dashes and try again.
        shift
        set -- "${argument#-}" "$@"
        ;;
    -*=*)
        # Normalize assignment style arguments into pairs of arguments.
        shift
        set -- "${argument%%=*}" "${argument#*=}" "$@"
        ;;
    -eval | -input | -title)
        # Take these options as environment variable switches.
        eval "export KAK_SPEC_option_${argument#-}=\"\$2\""
        shift 2
        ;;
    -h | -help | help)
        usage
        exit
        ;;
    -version)
        echo "kak-spec $version"
        exit
        ;;
    -*)
        {
            echo "$0: Unknown argument '$argument'"
            echo
            usage
        } >&2
        exit 1
        ;;
    *)
        break
        ;;
    esac
done

#
#       Act
#

if ! test -x "$REPORTER" >/dev/null; then
    echo "${0##*/}: missing executable \"$REPORTER\"";
    exit 1;
fi >&2

# Make one fifo per argument.
index=0
for argument
do
    mkfifo "$KAK_SPEC_DIR/$index.fifo"
    # Keep the fifo open.
    sleep 100000d >"$KAK_SPEC_DIR/$index.fifo" 2>&1 </dev/null &
    fifo_holder_pid_list="$fifo_holder_pid_list $!"
    index="$(expr "$index" + 1)"
done

# Listen to all of the fifos and report test results to standard output.
"$REPORTER" "$@" &
reporter_pid=$!

index=0
for argument
do
    mkdir "$KAK_SPEC_DIR/$index.dir"
    env --chdir="$(dirname "$argument")" \
        kak -ui dummy -n -e "$(
            kak_escape try "
                source $(kak_escape "$root_dir/rc/kak-spec.kak")
                source $(kak_escape "$root_dir/rc/kak-spec-scratch-eval.kak")
                declare-option str kak_spec_fifo $(kak_escape "$KAK_SPEC_DIR/$index.fifo")
                declare-option str kak_spec_tmp $(kak_escape "$KAK_SPEC_DIR/$index.dir")
                buffer '*debug*'
                require-module kak-spec
            " catch "
                quit! 1
            "
            kak_escape try "$(kak_escape kak-spec-context "$argument" "$(
                # Source the absolute path of the argument.
                kak_escape source "${argument##*/}"
            )")"
            kak_escape kak-spec-quit-begin
        )" &
    kak_pid_list="$kak_pid_list $!"
    index="$(expr "$index" + 1)"
done

# Wait for all kak processes and the reporter process.
wait $reporter_pid $kak_pid_list
wait_status=$?
reporter_pid=
kak_pid_list=

test "$fifo_holder_pid_list" && kill $fifo_holder_pid_list
fifo_holder_pid_list=

exit "$wait_status"