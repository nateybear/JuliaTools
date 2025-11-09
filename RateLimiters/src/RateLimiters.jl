module RateLimiters

export RateLimiter

using Reexport
@reexport using Unitful: @u_str, d, hr, minute, s

using Dates: DateTime, now, Millisecond
using HTTP
using Unitful

const 𝐓⁻¹ = Unitful.Dimensions{(Unitful.Dimension{:Time}(-1//1),)}()
const Rate = Unitful.Quantity{Int64, 𝐓⁻¹, <:Any}

mutable struct TokenBucket
    last::DateTime
    count::Int64
    rate::Rate
    TokenBucket(rate::Rate) = new(now(), 0, rate)
end

function ask(bucket::TokenBucket)
    update_window = bucket.rate.val / bucket.rate
    if now() - bucket.last > update_window
        prev_last = bucket.last
        bucket.count = 1
        bucket.last = now()
        true, prev_last
    elseif bucket.count < bucket.rate.val
        bucket.count += 1
        true, bucket.last
    else
        false, bucket.last + update_window
    end
end

struct RateLimiter{N}
    buckets::NTuple{N, TokenBucket}
    function RateLimiter(buckets::Vararg{Rate})
        return new{length(buckets)}(Tuple(TokenBucket(b) for b in buckets))
    end
end

function ask(limiter::RateLimiter)
    reponded_ok, prev_last = zip(ask.(limiter.buckets)...)
    if !all(reponded_ok)
        for idx_to_reset in findall(reponded_ok)
            b = limiter.buckets[idx_to_reset]
            b.count -= 1
            b.last = prev_last[idx_to_reset]
        end
        false, maximum(prev_last[findall(.!reponded_ok)])
    else
        true, nothing
    end
end

backoff(limiter) =
    while true
        can_i, must_wait = ask(limiter)
        can_i && break
        jitter = Millisecond(round(Int64, 1000rand()))
        sleep(abs(must_wait - now()) + jitter)  # add some jitter to avoid thundering herd problem
    end

function HTTP.get(limiter::RateLimiter, args...; kwargs...)
    backoff(limiter)
    return HTTP.get(args...; kwargs...)
end

function HTTP.post(limiter::RateLimiter, args...; kwargs...)
    backoff(limiter)
    return HTTP.post(args...; kwargs...)
end

end
