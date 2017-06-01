## shell-fn-cache

Ever wished Python's incredibly useful `@lru_cache` existed for shell functions? Well, now would be a good time to start. With this library, you can cache shell functions calls. With a simple one liner, you can [memoize](https://en.wikipedia.org/wiki/Memoization) your functions so that every subsequent call after the first one is near-instantaneous.

### An Example

Let's say you've written a glorious function that scrapes a URL with `curl` and `grep`s for a particular keyword. If the keyword exists, your function will print `exists`.

```sh
function keyword_search() {
    if [ -z "$(curl -s "$1" | grep -o "$2")" ]; then
        printf "does not exist\n"
    else
        printf "exists\n"
    fi
}
```

Every call to this function will take some time depending on how good your network connection is. For example,

```sh
$ keyword_search "https://httpbin.org/robots.txt" "User-agent"
exists
```

... took about 1.8 seconds on my laptop. Similarly,

```sh
$ keyword_search "https://httpbin.org/robots.txt" "this string does not exist"
does not exist
```

... took about 1.9 seconds. If you can guarantee that the response will be the same, every subsequent `keyword_search "https://httpbin.org/robots.txt" "User-agent"` will still take about 1.8 seconds.

What if I told you there's an app on the market that cached the output and return code for the function? To do this, simply source the script (I'm assuming you're using `zsh` here):

```sh
$ source fn-cache.zsh
```

Then you specify which functions you want cached:

```sh
$ cache_fn "keyword_search"
```

After this, the first call you make with a particular set of arguments will take its regular time. But every subsequent call will be near instantaneous:

```sh
$ keyword_search "https://httpbin.org/robots.txt" "User-agent"  # this will take 1.8 seconds
exists
$ keyword_search "https://httpbin.org/robots.txt" "User-agent"  # instantaneous
exists
$ keyword_search "https://httpbin.org/robots.txt" "User-agent"  # instantaenous
exists
```

And don't worry, return codes are preserved, of course (your function will still return the same return code it used to before caching, only faster now).

To see a couple of other useless examples, see the `examples/` directory.

### Supported Shells

Currently, `fn-cache` supports the following shells:

 - `zsh`

If you want to see your favorite shell supported, please open an issue. Alternatively, you can contribute code that adds support. To do so, create a new file named `fn-cache.(bash|zsh|ksh|fish)` with an API that's the same as the `zsh` one. You may also add examples in the `examples/` directory (either adapt the existing ones or create new ones altogether).

### License

This work is licensed under the MIT license. To see more, [click here](LICENSE).
