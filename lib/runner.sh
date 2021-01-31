#! /bin/sh

root_dir="$( ( cd "${0%/*}/.."; pwd ) )"

# A magic string that is used in internal communications of kak-spec.
# It is assumed that inone of the arguments passed to the kakoune kak-spec command.
KAK_SPEC_DELIMITER="bf152d0f8a1e657258d3059c47ff9625057d5ab0515eef9d6eec61592372af98"
export KAK_SPEC_DELIMITER

REPORTER="$root_dir/lib/reporter.rb"

version=0.1.5

# A grace period following shutdown after which this script kills its kak child processes.
shutdown_timeout=1s

scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/kak-spec.XXXXXXXX")

clean_up () {
    code=$?
    trap - TERM
    test -f "$scratch_dir/debug" && cat "$scratch_dir/debug"
    {
        # Kill any remaining non-kak child processes.
        if test "$reporter_pid$fifo_holder_pid_list"; then
            kill $reporter_pid $fifo_holder_pid_list
        fi
        # Kill any remaining kak child processes after a delay.
        if test "$kak_pid_list"; then
            (
                sleep "$shutdown_timeout"
                kill $kak_pid_list
            ) &
        fi
        rm -rf "$scratch_dir"
    } 2>/dev/null
    exit $code
}

trap clean_up INT TERM EXIT

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

Runs tests specified in kakoune <script> files or in files under a "spec" directory matching the pattern "*.kak-spec".

Each <script> is ran in a separate **temporary kakoune session**.
Different <script> runs may happen in any order, possibly in parallel.
However, tests defined in the same source file:
- are executed in they order they are defined,
- can use options, commands, etc defined before them in tests or on the top level, and
- may inadvertently disturb one another due to the above.

See <https://github.com/jbomanson/kak-spec> for instructions on how to write tests.

Options:
-color=(never|always|auto)
                  -- Print terminal color codes never, always, or only when the output is to a terminal.
-eval=<regex>     -- Run only tests whose eval  matches <regex>.
-input=<regex>    -- Run only tests whose input matches <regex>.
-title=<regex>    -- Run only tests whose title matches <regex>.

-h, -help, --help -- Show this help message
-version          -- Show the current version of kak-spec
EOF
}

# Names of environment variables to be passed to the reporter.
reporter_env=""
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
    -color)
        # Pass these options to the reporter as environment variables.
        variable="KAK_SPEC_REPORTER_${argument#-}"
        eval "$variable=\"\$2\""
        reporter_env="$reporter_env $variable=\"\$$variable\""
        shift 2
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
#       Apply mass argument defaults
#

if test $# -eq 0 && test -d spec; then
    find spec -type f -name "*.kak-spec" >"$scratch_dir/input-file-list"
    while read -r file
    do
        set -- "$@" "$file"
    done <"$scratch_dir/input-file-list"
fi

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
eval env -- $reporter_env '"$REPORTER" "$@" &'
reporter_pid=$!

index=0
for argument
do
    mkdir "$KAK_SPEC_DIR/$index.dir"
    env --chdir="$(dirname "$argument")" \
        kak -ui dummy -n -e "$(
            kak_escape try "
                declare-option str kak_spec_fifo $(kak_escape "$KAK_SPEC_DIR/$index.fifo")
                declare-option str kak_spec_tmp $(kak_escape "$KAK_SPEC_DIR/$index.dir")
                source $(kak_escape "$root_dir/lib/kak-spec-scratch-eval.kak-spec")
                source $(kak_escape "$root_dir/lib/kak-spec.kak-spec")
            " catch "
                buffer '*debug*'
                write $(kak_escape "$KAK_SPEC_DIR/debug")
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
wait $reporter_pid
reporter_status=$?
reporter_pid=

exit "$reporter_status"
