# General
const Bits64 = Union{Int64, UInt64, Float64}
abstract type StaticRNG{N} end
abstract type UniformStaticRNG{N} <: StaticRNG{N} end
abstract type GaussianStaticRNG{N} <: StaticRNG{N} end
@inline Base.pointer(x::StaticRNG) = Ptr{UInt64}(Base.pointer_from_objref(x))

# SplitMix64
"""
```julia
SplitMix64([seed::Bits64])
```
Initialize the internal state of a StaticCompiler-safe (non-allocating) `SplitMix64`
deterministic pseudorandom number generator, optionally specifying a 64-bit `seed`
(which may be a `Float64`, `Int64`, or `UInt64`).

If a seed is not specified, `StaticTools.time()` will be used, which returns
the current Unix epoch time in seconds.

### See also:
`splitmix64`, `rand`

## Examples
```julia
julia> seed = StaticTools.time() # Pick a seed
1649890154

julia> rng = SplitMix64(seed) # Initialize the generator
SplitMix64{Int64}((1649890154,))

julia> splitmix64(rng) # Draw a pseudorandom `UInt64` from the generator
0xca764ac7b7ea31e8

julia> rand(rng) # Draw a `Float64` between 0 and 1
0.8704883051360292
```
"""
mutable struct SplitMix64 <: UniformStaticRNG{1}
    state::NTuple{1,UInt64}
end
@inline SplitMix64(seed::UInt64) = SplitMix64((seed,))
@inline SplitMix64(seed::Bits64=StaticTools.time()) = SplitMix64(reinterpret(UInt64, seed))

"""
```julia
splitmix64([rng::SplitMix64])
```
A StaticCompiler-safe (non-allocating) implementation of the SplitMix64
deterministic pseudorandom number generator.

### See also:
`SplitMix64`, `rand`

## Examples
```julia
julia> seed = StaticTools.time() # Pick a seed
1649890154

julia> rng = SplitMix64(seed) # Initialize the generator
SplitMix64{Int64}((1649890154,))

julia> splitmix64(rng) # Draw a pseudorandom `UInt64` from the generator
0xca764ac7b7ea31e8

julia> rand(rng) # Draw a `Float64` between 0 and 1
0.8704883051360292
```
"""
@inline splitmix64(rng::StaticRNG{1}=SplitMix64()) = GC.@preserve rng splitmix64(pointer(rng))
@inline function splitmix64(state::Ptr{UInt64})
    s = unsafe_load(state)
    s += 0x9e3779b97f4a7c15
    unsafe_store!(state, s)
    z = s
    z = (z ⊻ (z >> 30)) * 0xbf58476d1ce4e5b9
    z = (z ⊻ (z >> 27)) * 0x94d049bb133111eb
    z ⊻ (z >> 31)
end

# Xoshiro256✴︎✴︎
"""
```julia
Xoshiro256✴︎✴︎(seed::NTuple{4,Bits64})
```
Initialize the internal state of a StaticCompiler-safe (non-allocating)
`Xoshiro256✴︎✴︎` deterministic pseudorandom number generator, specifying a 256-bit
`seed`, which should be specified as an `NTuple` of four 64-bit numbers (all
either `Float64`, `Int64`, or `UInt64`).

### See also:
`xoshiro256✴︎✴︎`, `static_rng`, `rand`

## Examples
```julia
julia> seed = (0x9b134eccd2e63538, 0xd74ab64b2c3ecc9b, 0x70ba9c07628c27bf, 0x270a2eb658e6130b)
(0x9b134eccd2e63538, 0xd74ab64b2c3ecc9b, 0x70ba9c07628c27bf, 0x270a2eb658e6130b)

julia> rng = Xoshiro256✴︎✴︎(seed) # Initialize the generator
Xoshiro256✴︎✴︎{UInt64}((0x9b134eccd2e63538, 0xd74ab64b2c3ecc9b, 0x70ba9c07628c27bf, 0x270a2eb658e6130b))

julia> xoshiro256✴︎✴︎(rng) # Draw a pseudorandom `UInt64` from the generator
0x11059b6384fba06a

julia> rand(rng) # Draw a `Float64` between 0 and 1
0.9856766307398369
```
"""
mutable struct Xoshiro256✴︎✴︎ <: UniformStaticRNG{4}
    state::NTuple{4,UInt64}
end
@inline function Xoshiro256✴︎✴︎(seed::Bits64=time())
    rng = SplitMix64(seed)
    Xoshiro256✴︎✴︎((splitmix64(rng),splitmix64(rng),splitmix64(rng),splitmix64(rng)))
end

# Xoshiro256✴︎✴︎ dPRNG in Julia
"""
```julia
xoshiro256✴︎✴︎(rng::Xoshiro256✴︎✴︎)
```
A StaticCompiler-safe (non-allocating) implementation of the Xoshiro256✴︎✴︎
deterministic pseudorandom number generator, written in LLVM IR and
invoked via `llvmcall`.

### See also:
`Xoshiro256✴︎✴︎`, `static_rng`, `rand`

## Examples
```julia
julia> seed = (0x9b134eccd2e63538, 0xd74ab64b2c3ecc9b, 0x70ba9c07628c27bf, 0x270a2eb658e6130b);

julia> rng = Xoshiro256✴︎✴︎(seed) # Initialize the generator
Xoshiro256✴︎✴︎{UInt64}((0x9b134eccd2e63538, 0xd74ab64b2c3ecc9b, 0x70ba9c07628c27bf, 0x270a2eb658e6130b))

julia> xoshiro256✴︎✴︎(rng) # Draw a pseudorandom `UInt64` from the generator
0x11059b6384fba06a

julia> rand(rng) # Draw a `Float64` between 0 and 1
0.9856766307398369
```
"""
@inline xoshiro256✴︎✴︎(rng::StaticRNG{4}) = GC.@preserve rng xoshiro256✴︎✴︎(pointer(rng))
@inline function xoshiro256✴︎✴︎(state::Ptr{UInt64})
    # Retrieve state from pointer
    s1 = Base.unsafe_load(state, 1)
    s2 = Base.unsafe_load(state, 2)
    s3 = Base.unsafe_load(state, 3)
    s4 = Base.unsafe_load(state, 4)

    # Calculate the result we will return this time
    result = rotl(s2 * 5, 7) * 9

    # Prepare the next state
    t = s2 << 17
    s3 ⊻= s1
    s4 ⊻= s2
    s2 ⊻= s3
    s1 ⊻= s4
    s3 ⊻= t
    s4 = rotl(s4, 45)

    # Store state
    Base.unsafe_store!(state, s1, 1)
    Base.unsafe_store!(state, s2, 2)
    Base.unsafe_store!(state, s3, 3)
    Base.unsafe_store!(state, s4, 4)

    return result
end
@inline rotl(x::UInt64, k::Int) = (x << k) | (x >> (64 - k))

"""
```julia
static_rng([seed::Bits64])
```
Initialize a StaticCompiler-safe (non-allocating) deterministic pseudorandom
number generator, optionally specifying a 64-bit `seed` (which may be any 64-bit
primitive numeric type -- that is, `Float64`, `Int64`, or `UInt64`).

In particular, `static_rng` uses the specified `seed` value (or if not specified,
the current result of `StaticTools.time()`) to initialize a simple `SplitMix64`
generator, which is then in turn used to bootstrap the larger seed required for a
`Xoshiro256✴︎✴︎` generator.

## Examples
```julia
julia> rng = static_rng()
Xoshiro256✴︎✴︎{UInt64}((0x2d4c7aa97cc1a621, 0x63460fc58ff25249, 0x81498572d44bd2ec, 0x2d4e96d3a7e9fdd2))

julia> rand(rng) # Draw a `Float64` between 0 and 1
0.6577585429879329

julia> rand(rng)
0.4711097758403277
```
"""
@inline static_rng(seed=StaticTools.time()) = Xoshiro256✴︎✴︎(seed)

# Extend Base.rand
@inline Base.rand(rng::StaticRNG) = rand(rng, Float64)
@inline Base.rand(rng::StaticRNG{1}, ::Type{UInt64}) = splitmix64(rng)
@inline Base.rand(rng::StaticRNG{4}, ::Type{UInt64}) = xoshiro256✴︎✴︎(rng)
@inline Base.rand(rng::StaticRNG, ::Type{Int64}) = rand(rng, UInt64) % Int64
@inline Base.rand(rng::StaticRNG, ::Type{Float64}) = rand(rng, UInt64) / typemax(UInt64)
@inline Base.rand(rng::StaticRNG, ::Type{UInt32}) = rand(rng, UInt64) >> 32 % UInt32
@inline Base.rand(rng::StaticRNG, ::Type{UInt16}) = rand(rng, UInt64) >> 48 % UInt16
@inline Base.rand(rng::StaticRNG, ::Type{Int64}) = rand(rng, UInt64) % Int64
@inline Base.rand(rng::StaticRNG, ::Type{Int32}) = rand(rng, UInt64) >> 32 % Int32
@inline Base.rand(rng::StaticRNG, ::Type{Int16}) = rand(rng, UInt64) >> 48 % Int16
@inline Base.rand(rng::StaticRNG, ::Type{Float64}) = (rand(rng, UInt64) >> 11) * 0x1p-53
@inline Base.rand(rng::StaticRNG, ::Type{Float32}) = (rand(rng, UInt32) >> 8) * Float32(0x1p-24)
@inline Base.rand(rng::StaticRNG, ::Type{Float16}) = (rand(rng, UInt16) >> 5) * Float16(0x1p-11)

# Types for Gaussian random number generators
mutable struct BoxMuller{T<:UniformStaticRNG, N} <: GaussianStaticRNG{N}
    state::NTuple{N, UInt64}
    z₁::Float64
    n::Int64
end
@inline BoxMuller(rng::T) where T<:UniformStaticRNG{N} where N = BoxMuller{T,N}(rng.state, 0.0, 0)
@inline BoxMuller(seed::Bits64=StaticTools.time()) = BoxMuller(static_rng(seed))
mutable struct MarsagliaPolar{T<:UniformStaticRNG, N} <: GaussianStaticRNG{N}
    state::NTuple{N, UInt64}
    z₁::Float64
    n::Int64
end
@inline MarsagliaPolar(rng::T) where T<:UniformStaticRNG{N} where N = MarsagliaPolar{T,N}(rng.state, 0.0, 0)
@inline MarsagliaPolar(seed::Bits64=StaticTools.time()) = MarsagliaPolar(static_rng(seed))


# Utility functions for gaussian random number generation
@inline upm1(rng) = (rand(rng, UInt64) >> 11) * 0x2p-53 - 1.0
@inline lsqrt(x::Float64) = @symbolcall llvm.sqrt.f64(x::Float64)::Float64
@inline llog(x::Float64) = @symbolcall log(x::Float64)::Float64
@inline lsin(x::Float64) = @symbolcall llvm.sin.f64(x::Float64)::Float64
@inline lcos(x::Float64) = @symbolcall llvm.cos.f64(x::Float64)::Float64


# Extend Base.randn
@inline Base.randn(rng::StaticRNG) = randn(rng, Float64)
@inline function Base.randn(rng::BoxMuller, ::Type{Float64})
    if rng.n == 0
        rng.n = 1
        u₁, u₂ = rand(rng), rand(rng)
        R = lsqrt(-2*llog(u₁))
        Θ = 2pi*u₂
        rng.z₁ = R * lcos(Θ)
        z₂ = R * lsin(Θ)
    else
        rng.n = 0
        rng.z₁
    end
end
@inline function Base.randn(rng::MarsagliaPolar, ::Type{Float64})
    if rng.n == 0
        rng.n = 1
        u₁, u₂ = upm1(rng), upm1(rng)
        s = u₁*u₁ + u₂*u₂
        while s > 1.0
            u₁, u₂ = upm1(rng), upm1(rng)
            s = u₁*u₁ + u₂*u₂
        end
        r = lsqrt(-2*llog(s)/s)
        rng.z₁ = u₁*r
        z₂ = u₂*r
    else
        rng.n = 0
        rng.z₁
    end
end
@inline function Base.randn(rng::StaticRNG, ::Type{Float64})
    u₁, u₂ = rand(rng), rand(rng)
    R = lsqrt(-2*llog(u₁))
    Θ = 2pi*u₂
    z₁ = R * lcos(Θ)
end


# Extend Random.rand! and Random.randn!?
@inline function Random.rand!(rng::StaticRNG, A::AbstractArray{T}) where T
    for i ∈ eachindex(A)
        A[i] = rand(rng, T)
    end
    A
end

@inline function Random.randn!(rng::StaticRNG, A::AbstractArray{T}) where T
    for i ∈ eachindex(A)
        A[i] = randn(rng, T)
    end
    A
end
@inline function Random.randn!(rng::StaticRNG, A::DenseArray{T}) where T
    for n ∈ 1:length(A)÷2
        u₁, u₂ = upm1(rng), upm1(rng)
        s = u₁*u₁ + u₂*u₂
        while s > 1.0
            u₁, u₂ = upm1(rng), upm1(rng)
            s = u₁*u₁ + u₂*u₂
        end
        r = lsqrt(-2*llog(s)/s)
        i = 2n
        A[i] = u₂*r
        A[i-1] = u₁*r
    end
    (length(A) % Bool) || (A[end] = randn(rng, T))
    A
end
@inline function Random.randn!(rng::BoxMuller, A::DenseArray{T}) where T
    for n ∈ 1:length(A)÷2
        u₁, u₂ = rand(rng), rand(rng)
        R = lsqrt(-2*llog(u₁))
        Θ = 2pi*u₂
        i = 2n
        A[i] = R * lcos(Θ)
        A[i-1] = R * lsin(Θ)
    end
    (length(A) % Bool) || (A[end] = randn(rng, T))
    A
end


## --- Constructors for other types

# StackArrays
@inline srand(rng::StaticRNG, dims::Vararg{Int}) = srand(rng, Float64, dims)
@inline srand(rng::StaticRNG, T::Type, dims::Vararg{Int}) = srand(rng, T, dims)
@inline function srand(rng::StaticRNG, ::Type{T}, dims::Dims{N}) where {T,N}
    A = StackArray{T,N,prod(dims),dims}(undef)
    rand!(rng, A)
end

@inline srandn(rng::GaussianStaticRNG, dims::Vararg{Int}) = srandn(rng, Float64, dims)
@inline srandn(rng::GaussianStaticRNG, T::Type, dims::Vararg{Int}) = srandn(rng, T, dims)
@inline function srandn(rng::GaussianStaticRNG, ::Type{T}, dims::Dims{N}) where {T,N}
    A = StackArray{T,N,prod(dims),dims}(undef)
    randn!(rng, A)
end

# MallocArrays
@inline mrand(rng::StaticRNG, dims::Vararg{Int}) = mrand(rng, Float64, dims)
@inline mrand(rng::StaticRNG, T::Type, dims::Vararg{Int}) = mrand(rng, T, dims)
@inline function mrand(rng::StaticRNG, ::Type{T}, dims::Dims{N}) where {T,N}
    A = MallocArray{T,N}(undef, dims)
    rand!(rng, A)
end
@inline function mrand(f::Function, args...)
    M = mrand(args...)
    y = f(M)
    free(M)
    y
end


@inline mrandn(rng::GaussianStaticRNG, dims::Vararg{Int}) = mrandn(rng, Float64, dims)
@inline mrandn(rng::GaussianStaticRNG, T::Type, dims::Vararg{Int}) = mrandn(rng, T, dims)
@inline function mrandn(rng::GaussianStaticRNG, ::Type{T}, dims::Dims{N}) where {T,N}
    A = MallocArray{T,N}(undef, dims)
    randn!(rng, A)
end
@inline function mrandn(f::Function, args...)
    M = mrandn(args...)
    y = f(M)
    free(M)
    y
end
