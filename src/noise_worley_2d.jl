"""
    worley_2d(; kwargs...)

Construct a sampler that outputs 2-dimensional Worley noise when it is sampled from.

# Arguments

  - `seed=0`: An integer used to seed the random number generator for this sampler.

  - `jitter=1.0`: A `Real` number between 0.0 and 1.0, with values closer to one randomly
    distributing cells away from their grid alignment.

  - `metric=:euclidean`: One of the following symbols:

      + `:manhattan`: Use the Manhattan distance to the next cell (Minkowski metric ``p = 2^0``).

      + `:euclidean`: Use the Euclidean distance to the next cell (Minkowski metric ``p = 2^1``).

      + `:euclidean²`: Same as `:euclidean` but slighter faster due to no ``\\sqrt{}``.

      + `:minkowski4`: Use Minkowski metric with ``p = 2^4`` for the distance to the next cell.

      + `:chebyshev`: Use the Chebyshev distance to the next cell (Minkowski metric ``p =
        2^\\infty``).

  - `output=:f1`: One of the following symbols:

      + `:f1`: Calculate the distance to the nearest cell as the output.

      + `:f2`: Calculate the distance to the second-nearest cell as the output.

      + `:+`: Calculate `:f1` + `:f2` as the output.

      + `:-`: Calculate `:f2` - `:f1` as the output.

      + `:*`: Calculate `:f1` * `:f2` as the output.

      + `:/`: Calculate `:f1` / `:f2` as the output.

      + `:value`: Use the cell's hash value as the output.
"""
function worley_2d(; seed=0, metric=:euclidean, output=:f1, jitter=1.0)
    worley(2, seed, metric, output, jitter)
end

function sample(sampler::Worley{2,M,F}, x::T, y::T) where {M,F,T<:Real}
    seed = sampler.seed
    table = sampler.table
    jitter = sampler.jitter * WORLEY_JITTER1
    r = round.(Int, (x, y)) .- 1
    xr, yr = r .- (x, y)
    xp, yp_base = r .* (PRIME_X, PRIME_Y)
    minf = floatmax(Float64)
    maxf = minf
    closest_hash::UInt32 = 0
    @inbounds for xi in 0:2
        xri = xr + xi
        yp = yp_base
        sxp = seed ⊻ xp * HASH1
        for yi in 0:2
            hash = (sxp ⊻ yp) % UInt32
            vx = table[(hash+1)&511] * jitter + xri
            vy = table[((hash|1)+1)&511] * jitter + yr + yi
            d = cell_distance(M, vx, vy)
            maxf = clamp(d, minf, maxf)
            if d < minf
                minf = d
                closest_hash = hash
            end
            yp += PRIME_Y
        end
        xp += PRIME_X
    end
    cell_value(F, M, closest_hash, minf, maxf) - 1
end
