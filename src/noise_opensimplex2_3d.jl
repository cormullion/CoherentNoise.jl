const OS2_SEED_FLIP_3D = -0x52d547b2e96ed629
const OS2_FALLBACK_ROTATE_3D = 2 / 3
const OS2_ROTATE_3D_ORTHONORMALIZER = OS2_UNSKEW_2D
const OS2_R²3D = 0.6
const OS2_NUM_GRADIENTS_EXP_3D = 8
const OS2_NUM_GRADIENTS_3D = 1 << OS2_NUM_GRADIENTS_EXP_3D
const OS2_GRADIENTS_NORMALIZED_3D = [
    2.22474487139, 2.22474487139, -1.0, 0.0,
    2.22474487139, 2.22474487139, 1.0, 0.0,
    3.0862664687972017, 1.1721513422464978, 0.0, 0.0,
    1.1721513422464978, 3.0862664687972017, 0.0, 0.0,
    -2.22474487139, 2.22474487139, -1.0, 0.0,
    -2.22474487139, 2.22474487139, 1.0, 0.0,
    -1.1721513422464978, 3.0862664687972017, 0.0, 0.0,
    -3.0862664687972017, 1.1721513422464978, 0.0, 0.0,
    -1.0, -2.22474487139, -2.22474487139, 0.0,
    1.0, -2.22474487139, -2.22474487139, 0.0,
    0.0, -3.0862664687972017, -1.1721513422464978, 0.0,
    0.0, -1.1721513422464978, -3.0862664687972017, 0.0,
    -1.0, -2.22474487139, 2.22474487139, 0.0,
    1.0, -2.22474487139, 2.22474487139, 0.0,
    0.0, -1.1721513422464978, 3.0862664687972017, 0.0,
    0.0, -3.0862664687972017, 1.1721513422464978, 0.0,
    -2.22474487139, -2.22474487139, -1.0, 0.0,
    -2.22474487139, -2.22474487139, 1.0, 0.0,
    -3.0862664687972017, -1.1721513422464978, 0.0, 0.0,
    -1.1721513422464978, -3.0862664687972017, 0.0, 0.0,
    -2.22474487139, -1.0, -2.22474487139, 0.0,
    -2.22474487139, 1.0, -2.22474487139, 0.0,
    -1.1721513422464978, 0.0, -3.0862664687972017, 0.0,
    -3.0862664687972017, 0.0, -1.1721513422464978, 0.0,
    -2.22474487139, -1.0, 2.22474487139, 0.0,
    -2.22474487139, 1.0, 2.22474487139, 0.0,
    -3.0862664687972017, 0.0, 1.1721513422464978, 0.0,
    -1.1721513422464978, 0.0, 3.0862664687972017, 0.0,
    -1.0, 2.22474487139, -2.22474487139, 0.0,
    1.0, 2.22474487139, -2.22474487139, 0.0,
    0.0, 1.1721513422464978, -3.0862664687972017, 0.0,
    0.0, 3.0862664687972017, -1.1721513422464978, 0.0,
    -1.0, 2.22474487139, 2.22474487139, 0.0,
    1.0, 2.22474487139, 2.22474487139, 0.0,
    0.0, 3.0862664687972017, 1.1721513422464978, 0.0,
    0.0, 1.1721513422464978, 3.0862664687972017, 0.0,
    2.22474487139, -2.22474487139, -1.0, 0.0,
    2.22474487139, -2.22474487139, 1.0, 0.0,
    1.1721513422464978, -3.0862664687972017, 0.0, 0.0,
    3.0862664687972017, -1.1721513422464978, 0.0, 0.0,
    2.22474487139, -1.0, -2.22474487139, 0.0,
    2.22474487139, 1.0, -2.22474487139, 0.0,
    3.0862664687972017, 0.0, -1.1721513422464978, 0.0,
    1.1721513422464978, 0.0, -3.0862664687972017, 0.0,
    2.22474487139, -1.0, 2.22474487139, 0.0,
    2.22474487139, 1.0, 2.22474487139, 0.0,
    1.1721513422464978, 0.0, 3.0862664687972017, 0.0,
    3.0862664687972017, 0.0, 1.1721513422464978, 0.0]
const OS2_GRADIENTS_3D = OS2_GRADIENTS_NORMALIZED_3D ./ 0.07969837668935331 |> CircularVector

"""
    opensimplex2_3d(; kwargs...)

Construct a sampler that outputs 3-dimensional OpenSimplex2 noise when it is sampled from.

# Arguments

  - `seed=0`: An integer used to seed the random number generator for this sampler.

  - `orient=nothing`: One of the following symbols or the value `nothing`:

      + `:x`: The noise space will be re-oriented with the Y axis pointing down the main diagonal to
        improve visual isotropy.

      + `:xy`: Re-orient the noise space to have better visual isotropy in the XY plane.

      + `:xz`: Re-orient the noise space to have better visual isotropy in the XZ plane.

      + `nothing`: Use the standard orientation.
"""
opensimplex2_3d(; seed=0, orient=nothing) = opensimplex2(3, seed, orient)

@inline function grad(table, seed, X, Y, Z, x, y, z)
    hash = ((seed ⊻ X) ⊻ (Y ⊻ Z)) * HASH_MULTIPLIER
    hash ⊻= hash >> (64 - OS2_NUM_GRADIENTS_EXP_3D + 2)
    i = trunc(hash) & ((OS2_NUM_GRADIENTS_3D - 1) << 2)
    t = (table[i+1], table[(i|1)+1], table[(i|2)+1])
    sum((t .* (x, y, z)))
end

@inline @fastpow function os2_contribute1(seed, a, X, Y, Z, x1, y1, z1, x2, y2, z2, xs, ys, zs)
    result = 0.0
    if a > 0
        result += a^4 * grad(OS2_GRADIENTS_3D, seed, X, Y, Z, x1, y1, z1)
    end
    if x2 ≥ y2 && x2 ≥ z2
        result += os2_contribute2(seed, a + 2x2, X - xs * PRIME_X, Y, Z, x1 + xs, y1, z1)
    elseif y2 ≥ x2 && y2 ≥ z2
        result += os2_contribute2(seed, a + 2y2, X, Y - ys * PRIME_Y, Z, x1, y1 + ys, z1)
    else
        result += os2_contribute2(seed, a + 2z2, X, Y, Z - zs * PRIME_Z, x1, y1, z1 + zs)
    end
    result
end

@inline @fastpow function os2_contribute2(seed, a, args...)
    a > 1 ? (a - 1)^4 * grad(OS2_GRADIENTS_3D, seed, args...) : 0.0
end

@inline function transform(::OpenSimplex2{3,OrientStandard}, x, y, z)
    OS2_FALLBACK_ROTATE_3D * (x + y + z) .- (x, y, z)
end

@inline function transform(::OpenSimplex2{3,OrientXY}, x, y, z)
    xy = x + y
    zz = z * ROOT_3_OVER_3
    xr, yr = (x, y) .+ xy .* OS2_ROTATE_3D_ORTHONORMALIZER .+ zz
    zr = xy * -ROOT_3_OVER_3 + zz
    (xr, yr, zr)
end

@inline transform(::OpenSimplex2{3,OrientXZ}, x, y, z) = transform(OrientXY, x, z, y)

function sample(sampler::OpenSimplex2{3}, x::T, y::T, z::T) where {T<:Real}
    seed = sampler.seed
    primes = (PRIME_X, PRIME_Y, PRIME_Z)
    tr = transform(sampler, x, y, z)
    V = round.(Int, tr)
    XYZ = V .* primes
    x1, y1, z1 = tr .- V
    s = trunc.(Int, -1 .- (x1, y1, z1)) .| 1
    XYZ2 = XYZ .+ s .>> 1 .& primes
    xyz2 = s .* .-((x1, y1, z1))
    x4, y4, z4 = 0.5 .- xyz2
    xyz3 = s .* (x4, y4, z4)
    a1 = OS2_R²3D - x1^2 - (y1^2 + z1^2)
    c1 = os2_contribute1(seed, a1, XYZ..., x1, y1, z1, xyz2..., s...)
    a2 = a1 + 0.75 - x4 - (y4 + z4)
    c2 = os2_contribute1(seed ⊻ OS2_SEED_FLIP_3D, a2, XYZ2..., xyz3..., x4, y4, z4, .-s...)
    c1 + c2
end
