#!/bin/sh
# An implementation of some basic etcdctl functionality. Depends on sh, wget, socat, and awk.
# Meant to be used in a busybox Docker image with socat.

http() {
    if [[ "$4" == "" ]]; then
        echo -e "$2 $3 HTTP/1.1\n" | socat TCP:$1 -
    else
        echo -e "$2 $3 HTTP/1.1\nContent-Length: ${#4}\nContent-Type: application/x-www-form-urlencoded\n\n$4" | socat TCP:$1 -
    fi
}
etcdctl_get() {
    # Usage: etcdctl_get key
    # We don't allow quotation marks in our value.
    wget -q -O - "http://${ETCD}/v2/keys/$1?recursive=false&sorted=false" | sed 's|.*"value":"\([^"]*\)".*|\1|'
}
etcdctl_ls() {
    # Usage: etcdctl_ls directory
    # We don't allow quotation marks in our directory names.
    wget -q -O - "http://${ETCD}/v2/keys/$1?consistent=true&recursive=false&sorted=false" \
    | cut -d "[" -f2 \
    | awk '
           BEGIN {
            RS=","
           }
           {
            FS="\"";
            if ( $2 == "key" ) {
                print $4
            }
           }
     '
}

etcdctl_rm() {
    # Usage: etcdctl_rm key [recursive]
    if [[ $2 == "recursive" ]]; then
        http ${ETCD} DELETE "/v2/keys/$1?dir=false&recursive=true" > /dev/null
    else
        http ${ETCD} DELETE "/v2/keys/$1?dir=false&recursive=false" > /dev/null
    fi
}

etcdctl_mkdir() {
    # Usage: etcdctl_mkdir directory
    http ${ETCD} PUT "/v2/keys/$1?dir=true&prevExist=false" > /dev/null
}

etcdctl_set() {
    # Usage: etcdctl_set key value
    # Does not yet do URL encoding.
    http ${ETCD} PUT /v2/keys/$1 "value=$2" > /dev/null
}