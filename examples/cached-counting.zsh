#!/usr/bin/env zsh

# source the fn-cache.zsh file
source ../fn-cache.zsh

# a random function that counts from one number to another with a
# 500ms gap between each number
function count() {
    for i in $(seq $1 $2); do
        sleep 0.5
        printf " %d" "$i"
    done
    printf "\n"

    return 0
}

# test run: count from 1 to 3 (should take 1.5 seconds)
count 1 3

# with this call, we enable caching for this function
cache_fn "count"

# this is the first call since we memoized the function so it won't be
# cached and will run normally
count 1 3

# this call is cached and will output instantaneously
count 1 3

# this time, the function is called with a new set of unseen arguments; so
# it will be uncached
count 2 5

# but the second (and every later) time we call the function with a set of
# arguments, the result will be cached and instantaneous
count 2 5

# to uncache a function (and let it run normally every time), simply call
# the `uncache_fn` function
uncache_fn "count"
