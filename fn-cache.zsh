#!/usr/bin/env zsh

typeset -A __output_cache
typeset -A __exit_cache

# cache_fn:
#     :param $1: the function that you want cached
function cache_fn() {
    # make sure the user gives us a function
    if [ "$#" -ne 1 ]; then
        printf "cache_fn: requires a function name as argument\n" >&2
        exit 1
    fi
    fn_name="$1"

    # make sure what they gave is a function
    what=$(whence -w "$fn_name" | cut -d ' ' -f 2)
    if [ "$what" != "function" ]; then
        printf "cache_fn: %s is not a function\n" "$fn_name"
        exit 1
    fi

    # this where the magic happens: we replace their function with a
    # wrapper function of our own that will basically check whether we have
    # seen this set of arguments before. If we have, we'll simply return the
    # previous output. If we haven't, run the original function and store the
    # output for later use
    eval "$(
        printf "
        function __no_cache_%s() {
        " "$fn_name"

        whence -f "$fn_name" | tail -n +2

        printf "
        function %s() {
            if [ -n \"\${__exit_cache[\$@]}\" ]; then
                echo \"\${__output_cache[\$@]}\"
                return \${__exit_cache[\$@]}
            fi
            if [ -z \"\${__exit_cache[\$@]}\" ]; then
                exec 5>&1
                __output_cache[\$@]=\"\$(__no_cache_%s \$@ 2>&1 | tee /dev/fd/5; exit \$pipestatus[1])\"
                __exit_cache[\$@]=\$?
                return \$__exit_cache[\$@]
            fi
        }
        " "$fn_name" "$fn_name"
    )"
}

# uncache_fn:
#     :param $1: the function you don't want cached anymore
function uncache_fn() {
    # make sure the user gives us a function
    if [ "$#" -lt 1 ]; then
        printf "uncache_fn: requires a function name as argument\n" >&2
        exit 1
    fi
    uncached_fn_name="$1"
    cached_fn_name="__no_cache_$1"

    # make sure that we have cached this function in the past
    what=$(whence -w "$cached_fn_name" | cut -d ' ' -f 2)
    if [ "$what" != "function" ]; then
        printf "uncache_fn: %s has not been cached yet\n" "$uncached_fn_name"
        exit 1
    fi

    # make sure the original function exists
    what=$(whence -w "$uncached_fn_name" | cut -d ' ' -f 2)
    if [ "$what" != "function" ]; then
        printf "uncache_fn: %s's original function does not exist anymore\n" "$cached_fn_name"
        exit 1
    fi

    # restore the original function
    eval "$(
        printf "
        function %s() {
        " "$uncached_fn_name"

        whence -f "$cached_fn_name" | tail -n +2
    )"

    # remove the other function
    unset -f "$cached_fn_name"
}
