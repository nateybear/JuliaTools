# Nate's Julia Packages

These are things that I find myself re-using, but I don't think they're significant enough to publish to Julia's General registry (and I don't have time to be an active maintainer). If you want to use them yourself, you can add them as a Julia registry:

```
pkg> registry add https://github.com/nateybear/JuliaTools.git
pkg> registry add General
```

You want to re-add the General registry because Julia will not default to using it once you start using your own registries.

### Snakemake

My more-modular way of calling Snakemake by serializing config as JSON to stdin. Snakemake does this a bad way (IMO) natively, by creating a new script with a weird name in a weird directory, and hence it's harder to debug script failures.

On the Julia side, it exposes a `snakemake` object with dicts for input, output, wildcards, etc. Use like this:

```Julia
using Snakemake

function (@main)(_)
  with_logging() do
    # do things with the snakemake object...
  end
  return nothing
end
```

On the Python side, you will have to import my script runner. Just call `Snakemake.write_pyfile()` once in Julia and it will write the Python code to a file called `julia.py` in your directory. Then in your Snakefile:

```Snakemake
from julia import julia

rule test:
  input:
    # ...
  output:
    # ...
  log:
    # ...
  run:
    julia(
      "myscript.jl",
      input=input,
      output=output,
      log=log,
      wildcards=wildcards,
    )
```

### RateLimiters

Simple token bucket rate limiter for HTTP requests. Uses jitter backoff right now, which is faster but more stressful than exponential. Exports the `Unitful.jl` symbols for time, so you create limiters using them as rates.

The easiest application is with Julia's `asyncmap`, which implement cooperative multi-tasking:

```Julia
using RateLimiters
using HTTP

# limit three per second and 10k / day
limiter = RateLimiter(3 / s, 10_000 / d)

collection = 1:100 # what you're mapping over

results = asyncmap(collection) do i
  HTTP.get(limiter, "https://httpbin.org/stream/$i")
end
```
