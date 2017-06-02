#!/usr/bin/env bash

declare -A __output_cache
declare -A __exit_cache

export __exit_cache
export __output_cache

# cache_fn:
#     :param $1: the function that you want cached
cache_fn() {

  # make sure the user provides input
  if (( $# != 1 )); then
    printf "cache_fn: requires a function name as argument\n" >&2
    return 1
  fi
  fn_name="$1"

  # make sure what they gave is a function
  if ! [[ $(type -t "$fn_name") == function ]]; then
    printf "cache_fn: %s is not a function\n" "$fn_name"
    return 1
  fi

  if [[ -z ${__output_cache[$@]} ]]; then

    eval "$(
      # save the old function
      printf "%s%s" \
        "__no_cache_${fn_name}()" \
        "$(type "$fn_name" | tail -n +3)"

      # create the memoized function
      printf "
        function %s() {
            if [[ -n \"\${__exit_cache[\$@]}\" ]]; then
                echo \"\${__output_cache[\$@]}\"
                return \${__exit_cache[\$@]}
            fi
            if [[ -z \"\${__exit_cache[\$@]}\" ]]; then
                exec 5>&1
                __output_cache[\$@]=\"\$(__no_cache_%s \$@ 2>&1 | tee /dev/fd/5; exit \${PIPESTATUS[0]})\"
                __exit_cache[\$@]=\$?
                return \${__exit_cache[\$@]}
            fi
        }
      " "$fn_name" "$fn_name"
    )"
  fi
}

# uncache_fn:
#     :param $1: the function you don't want cached anymore
uncache_fn() {

  # make sure the user gives us a function
  if (( "$#" != 1 )); then
    printf "uncache_fn: requires a function name as argument\n" >&2
    exit 1
  fi
  uncached_fn_name="$1"
  cached_fn_name="__no_cache_$1"

  # make sure that we have cached this function in the past
  if ! [[ $(type -t "$cached_fn_name") == function ]]; then
    printf "uncache_fn: %s has not been cached yet\n" "$uncached_fn_name"
    exit 1
  fi

  # make sure the original function exists
  if ! [[ $(type -t "$uncached_fn_name") == function ]]; then
      printf "uncache_fn: %s's original function does not exist anymore\n" "$cached_fn_name"
      exit 1
  fi

  # restore the original function
  eval "$(
    printf "%s%s" \
      "${uncached_fn_name}()" \
      "$(type "$cached_fn_name" | tail -n +3)"
  )"

  # remove the other function
  unset -f "$cached_fn_name"
}
