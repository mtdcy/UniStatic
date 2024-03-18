#!/bin/bash

cd "$(dirname "$0")"

. ulib.sh

_upkg_env || true

env

for x in "$@"; do
    # binaries ?
    ulog info "Search binaries ..."
    find "$PREFIX/bin" -name "$x*" 2>/dev/null  | sed "s%^$UPKG_ROOT/%%"

    # libraries?
    ulog info "Search libraries ..."
    find "$PREFIX/lib" -name "$x*" -o -name "lib$x*" 2>/dev/null  | sed "s%^$UPKG_ROOT/%%"

    # headers?
    ulog info "Search headers ..."
    find "$PREFIX/include" -name "$x*" -o -name "lib$x*" 2>/dev/null  | sed "s%^$UPKG_ROOT/%%"

    # pkg-config?
    ulog info "Search pkgconfig ..."
    if $PKG_CONFIG --exists "$x"; then
        ulog info ".Found $x @ $($PKG_CONFIG --modversion "$x")"
        echo "PREFIX : $($PKG_CONFIG --variable=prefix "$x" | sed "s%^$UPKG_ROOT/%%")"
        echo "CFLAGS : $($PKG_CONFIG --static --cflags "$x" | sed "s%^$UPKG_ROOT/%%")"
        echo "LDFLAGS: $($PKG_CONFIG --static --libs "$x"   | sed "s%^$UPKG_ROOT/%%")"
        # TODO: add a sanity check here
    fi

    x=lib$x
    if $PKG_CONFIG --exists "$x"; then
        ulog info ".Found $x @ $($PKG_CONFIG --modversion "$x")"
        echo "PREFIX : $($PKG_CONFIG --variable=prefix "$x" | sed "s%^$UPKG_ROOT/%%")"
        echo "CFLAGS : $($PKG_CONFIG --static --cflags "$x" | sed "s%^$UPKG_ROOT/%%")"
        echo "LDFLAGS: $($PKG_CONFIG --static --libs "$x"   | sed "s%^$UPKG_ROOT/%%")"
        # TODO: add a sanity check here
    fi
done

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
