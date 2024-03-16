#!/bin/bash

#exec > >(logger -t $(basename $0))
#exec 2> >(logger -t $(basename $0) -p user.error)
echo "=="

set -e

cd "$(dirname "$0")"

#make test-tty

test -t 0 && echo "with tty ..0" || echo "without tty ..0"

test -t 1 && echo "with tty ..1" || echo "without tty ..1"

test -t 2 && echo "with tty ..2" || echo "without tty ..2"

echo "=="
