#!/usr/bin/env bash
#
# Thanks https://github.com/dylanaraps/pure-bash-bible/blob/master/test.sh

test_transactions_stdout() {
    expected="$(cat "fixtures/result.stdout.csv")"
    result="$(../vba fixtures/transactions.csv 2>/dev/null)"
    assert_equals "$expected" "$result"
}

test_transactions_stderr() {
    expected="$(cat "fixtures/result.stderr.csv")"
    result="$(../vba fixtures/transactions.csv 2>&1 >/dev/null)"
    assert_equals "$expected" "$result"
}

test_newlines_stderr() {
    expected="$(cat "fixtures/newlines.stderr.csv")"
    result="$(../vba fixtures/newlines.csv 2>&1 >/dev/null)"
    assert_equals "$expected" "$result"
}

assert_equals() {
    if [[ "$1" == "$2" ]]; then
        ((pass+=1))
        status=$'\e[32m✔'
    else
        ((fail+=1))
        status=$'\e[31m✖'
        local err="(\"$1\" != \"$2\")"
    fi

    printf ' %s\e[m | %s\n' "$status" "${FUNCNAME[1]/test_} $err"
}

main() {
    # Run shellcheck.
    shellcheck -s bash ../vba || exit 1

    head="-> Running tests on vba"
    printf '\n%s\n%s\n' "$head" "${head//?/-}"

    # Generate the list of tests to run.
    IFS=$'\n' read -d "" -ra funcs < <(declare -F)
    for func in "${funcs[@]//declare -f }"; do
        [[ "$func" == test_* ]] && "$func";
    done

    comp="$((fail+pass)) tests: ${pass:-0} passed, ${fail:-0} failed"
    printf '%s\n%s\n\n' "${comp//?/-}" "$comp"

    # If a test failed, exit with '1'.
    ((fail>0)) || exit 0 && exit 1
}

main "$@"
