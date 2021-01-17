#!/bin/sh

sed -n '/\.ini\.case[0-9]\+$/{
    h
    :a
    n
    /^case/!ba
    /^case failed:/ {
        x
        s/\(.*\)\.\(case[0-9]\+\)$/\1\t\2/g
        p
    }

}' ${1:-result.txt} | awk '{n++;printf "%-50s %s\n", $1, $2}END{print "Total failed: "n}'
