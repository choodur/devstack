#!/usr/bin/env bash

# Tests for DevStack INI functions

TOP=$(cd $(dirname "$0")/.. && pwd)

# Import config functions
source $TOP/inc/ini-config

source $TOP/tests/unittest.sh

set -e

echo "Testing INI functions"

cat >test.ini <<EOF
[default]
# comment an option
#log_file=./log.conf
log_file=/etc/log.conf
handlers=do not disturb

[aaa]
# the commented option should not change
#handlers=cc,dd
handlers = aa, bb

[bbb]
handlers=ee,ff

[ ccc ]
spaces  =  yes

[ddd]
empty =

[eee]
multi = foo1
multi = foo2

# inidelete(a)
[del_separate_options]
a=b
b=c

# inidelete(a)
[del_same_option]
a=b
a=c

# inidelete(a)
[del_missing_option]
b=c

# inidelete(a)
[del_missing_option_multi]
b=c
b=d

# inidelete(a)
[del_no_options]

# inidelete(a)
# no section - del_no_section

EOF

# Test with missing arguments

BEFORE=$(cat test.ini)

echo -n "iniset: test missing attribute argument: "
iniset test.ini aaa
NO_ATTRIBUTE=$(cat test.ini)
if [[ "$BEFORE" == "$NO_ATTRIBUTE" ]]; then
    passed
else
    failed "failed"
fi

echo -n "iniset: test missing section argument: "
iniset test.ini
NO_SECTION=$(cat test.ini)
if [[ "$BEFORE" == "$NO_SECTION" ]]; then
    passed
else
    failed "failed"
fi

# Test with spaces

VAL=$(iniget test.ini aaa handlers)
if [[ "$VAL" == "aa, bb" ]]; then
    passed "OK: $VAL"
else
    failed "iniget failed: $VAL"
fi

iniset test.ini aaa handlers "11, 22"

VAL=$(iniget test.ini aaa handlers)
if [[ "$VAL" == "11, 22" ]]; then
    passed "OK: $VAL"
else
    failed "iniget failed: $VAL"
fi

# Test with spaces in section header

VAL=$(iniget test.ini " ccc " spaces)
if [[ "$VAL" == "yes" ]]; then
    passed "OK: $VAL"
else
    failed "iniget failed: $VAL"
fi

iniset test.ini "b b" opt_ion 42

VAL=$(iniget test.ini "b b" opt_ion)
if [[ "$VAL" == "42" ]]; then
    passed "OK: $VAL"
else
    failed "iniget failed: $VAL"
fi

# Test without spaces, end of file

VAL=$(iniget test.ini bbb handlers)
if [[ "$VAL" == "ee,ff" ]]; then
    passed "OK: $VAL"
else
    failed "iniget failed: $VAL"
fi

iniset test.ini bbb handlers "33,44"

VAL=$(iniget test.ini bbb handlers)
if [[ "$VAL" == "33,44" ]]; then
    passed "OK: $VAL"
else
    failed "iniget failed: $VAL"
fi

# test empty option
if ini_has_option test.ini ddd empty; then
    passed "OK: ddd.empty present"
else
    failed "ini_has_option failed: ddd.empty not found"
fi

# test non-empty option
if ini_has_option test.ini bbb handlers; then
    passed "OK: bbb.handlers present"
else
    failed "ini_has_option failed: bbb.handlers not found"
fi

# test changing empty option
iniset test.ini ddd empty "42"

VAL=$(iniget test.ini ddd empty)
if [[ "$VAL" == "42" ]]; then
    passed "OK: $VAL"
else
    failed "iniget failed: $VAL"
fi

# test pipe in option
iniset test.ini aaa handlers "a|b"

VAL=$(iniget test.ini aaa handlers)
if [[ "$VAL" == "a|b" ]]; then
    passed "OK: $VAL"
else
    failed "iniget failed: $VAL"
fi

# test space in option
iniset test.ini aaa handlers "a b"

VAL="$(iniget test.ini aaa handlers)"
if [[ "$VAL" == "a b" ]]; then
    passed "OK: $VAL"
else
    failed "iniget failed: $VAL"
fi

# Test section not exist

VAL=$(iniget test.ini zzz handlers)
if [[ -z "$VAL" ]]; then
    passed "OK: zzz not present"
else
    failed "iniget failed: $VAL"
fi

iniset test.ini zzz handlers "999"

VAL=$(iniget test.ini zzz handlers)
if [[ -n "$VAL" ]]; then
    passed "OK: zzz not present"
else
    failed "iniget failed: $VAL"
fi

# Test option not exist

VAL=$(iniget test.ini aaa debug)
if [[ -z "$VAL" ]]; then
    passed "OK aaa.debug not present"
else
    failed "iniget failed: $VAL"
fi

if ! ini_has_option test.ini aaa debug; then
    passed "OK aaa.debug not present"
else
    failed "ini_has_option failed: aaa.debug"
fi

iniset test.ini aaa debug "999"

VAL=$(iniget test.ini aaa debug)
if [[ -n "$VAL" ]]; then
    passed "OK aaa.debug present"
else
    failed "iniget failed: $VAL"
fi

# Test comments

inicomment test.ini aaa handlers

VAL=$(iniget test.ini aaa handlers)
if [[ -z "$VAL" ]]; then
    passed "OK"
else
    failed "inicomment failed: $VAL"
fi

# Test multiple line iniset/iniget
iniset_multiline test.ini eee multi bar1 bar2

VAL=$(iniget_multiline test.ini eee multi)
if [[ "$VAL" == "bar1 bar2" ]]; then
    echo "OK: iniset_multiline"
else
    failed "iniset_multiline failed: $VAL"
fi

# Test iniadd with exiting values
iniadd test.ini eee multi bar3
VAL=$(iniget_multiline test.ini eee multi)
if [[ "$VAL" == "bar1 bar2 bar3" ]]; then
    passed "OK: iniadd"
else
    failed "iniadd failed: $VAL"
fi

# Test iniadd with non-exiting values
iniadd test.ini eee non-multi foobar1 foobar2
VAL=$(iniget_multiline test.ini eee non-multi)
if [[ "$VAL" == "foobar1 foobar2" ]]; then
    passed "OK: iniadd with non-exiting value"
else
    failed "iniadd with non-exsting failed: $VAL"
fi

# Test inidelete
del_cases="
    del_separate_options
    del_same_option
    del_missing_option
    del_missing_option_multi
    del_no_options
    del_no_section"

for x in $del_cases; do
    inidelete test.ini $x a
    VAL=$(iniget_multiline test.ini $x a)
    if [ -z "$VAL" ]; then
        passed "OK: inidelete $x"
    else
        failed "inidelete $x failed: $VAL"
    fi
    if [ "$x" = "del_separate_options" -o \
        "$x" = "del_missing_option" -o \
        "$x" = "del_missing_option_multi" ]; then
        VAL=$(iniget_multiline test.ini $x b)
        if [ "$VAL" = "c" -o "$VAL" = "c d" ]; then
            passed "OK: inidelete other_options $x"
        else
            failed "inidelete other_option $x failed: $VAL"
        fi
    fi
done

rm test.ini

report_results
