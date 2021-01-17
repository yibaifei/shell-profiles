#!/bin/sh

## 配对测试

awk -F '\\]\\[' '
    $10 == "PSVIN" {
        match($0, "/api/trade/[^,]*")
        url = substr($0, RSTART, RLENGTH)
        tmp[$8] = url
    }
    /cost stage:/ {
        match($0, "WAIT:.*")
        arr[tmp[$8]][$8] = substr($0, RSTART, RLENGTH)
    }
    END {
        for (v1 in arr) {
            print v1":"
            for (v2 in arr[v1]) {
                print "\t"v2" -> " arr[v1][v2]
            }
        }
    }
' $@
