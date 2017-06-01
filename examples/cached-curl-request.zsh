#!/usr/bin/env zsh

# source the fn-cache.zsh file
source ../fn-cache.zsh

# a function that requests a page on the internet and displays the
# response on the console using curl
function get_response() {
    curl -s $1
    return $?  # return the same exit code as curl
}

# let's cache the function
cache_fn "get_response"

# this is the first call, so it'll take time to complete (depending
# on how fast your network is)
get_response "https://httpbin.org/robots.txt"

# this call is cached and will output instantaneously
get_response "https://httpbin.org/robots.txt"

# an URL that returns 404 so that we can test if the exit code is properly cached
get_response "https://httpbin.org/status/404"
first_ret_code=$?

# the same URL again, but this time it'll be cached
get_response "https://httpbin.org/status/404"
second_ret_code=$?

if [ $first_ret_code -eq $second_ret_code ]; then
    printf "not horribly broken :)"
else
    printf "oh gawd everything is broken"
fi
