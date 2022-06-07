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
    return z ⊻ (z >> 31)
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

# Xoshiro256✴︎✴︎ PRNG implemented in LLVM IR
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
    Base.llvmcall(("""
    ; Function Attrs: noinline nounwind ssp uwtable
    define i64 @next(i64) #0 {
      %ptr = inttoptr i64 %0 to i64*
      %2 = alloca i64*, align 8
      %3 = alloca i64, align 8
      %4 = alloca i64, align 8
      store i64* %ptr, i64** %2, align 8
      %5 = load i64*, i64** %2, align 8
      %6 = getelementptr inbounds i64, i64* %5, i64 1
      %7 = load i64, i64* %6, align 8
      %8 = mul i64 %7, 5
      %9 = call i64 @rotl(i64 %8, i32 7)
      %10 = mul i64 %9, 9
      store i64 %10, i64* %3, align 8
      %11 = load i64*, i64** %2, align 8
      %12 = getelementptr inbounds i64, i64* %11, i64 1
      %13 = load i64, i64* %12, align 8
      %14 = shl i64 %13, 17
      store i64 %14, i64* %4, align 8
      %15 = load i64*, i64** %2, align 8
      %16 = getelementptr inbounds i64, i64* %15, i64 0
      %17 = load i64, i64* %16, align 8
      %18 = load i64*, i64** %2, align 8
      %19 = getelementptr inbounds i64, i64* %18, i64 2
      %20 = load i64, i64* %19, align 8
      %21 = xor i64 %20, %17
      store i64 %21, i64* %19, align 8
      %22 = load i64*, i64** %2, align 8
      %23 = getelementptr inbounds i64, i64* %22, i64 1
      %24 = load i64, i64* %23, align 8
      %25 = load i64*, i64** %2, align 8
      %26 = getelementptr inbounds i64, i64* %25, i64 3
      %27 = load i64, i64* %26, align 8
      %28 = xor i64 %27, %24
      store i64 %28, i64* %26, align 8
      %29 = load i64*, i64** %2, align 8
      %30 = getelementptr inbounds i64, i64* %29, i64 2
      %31 = load i64, i64* %30, align 8
      %32 = load i64*, i64** %2, align 8
      %33 = getelementptr inbounds i64, i64* %32, i64 1
      %34 = load i64, i64* %33, align 8
      %35 = xor i64 %34, %31
      store i64 %35, i64* %33, align 8
      %36 = load i64*, i64** %2, align 8
      %37 = getelementptr inbounds i64, i64* %36, i64 3
      %38 = load i64, i64* %37, align 8
      %39 = load i64*, i64** %2, align 8
      %40 = getelementptr inbounds i64, i64* %39, i64 0
      %41 = load i64, i64* %40, align 8
      %42 = xor i64 %41, %38
      store i64 %42, i64* %40, align 8
      %43 = load i64, i64* %4, align 8
      %44 = load i64*, i64** %2, align 8
      %45 = getelementptr inbounds i64, i64* %44, i64 2
      %46 = load i64, i64* %45, align 8
      %47 = xor i64 %46, %43
      store i64 %47, i64* %45, align 8
      %48 = load i64*, i64** %2, align 8
      %49 = getelementptr inbounds i64, i64* %48, i64 3
      %50 = load i64, i64* %49, align 8
      %51 = call i64 @rotl(i64 %50, i32 45)
      %52 = load i64*, i64** %2, align 8
      %53 = getelementptr inbounds i64, i64* %52, i64 3
      store i64 %51, i64* %53, align 8
      %54 = load i64, i64* %3, align 8
      ret i64 %54
    }

    ; Function Attrs: noinline nounwind ssp uwtable
    define internal i64 @rotl(i64, i32) #0 {
      %3 = alloca i64, align 8
      %4 = alloca i32, align 4
      store i64 %0, i64* %3, align 8
      store i32 %1, i32* %4, align 4
      %5 = load i64, i64* %3, align 8
      %6 = load i32, i32* %4, align 4
      %7 = zext i32 %6 to i64
      %8 = shl i64 %5, %7
      %9 = load i64, i64* %3, align 8
      %10 = load i32, i32* %4, align 4
      %11 = sub nsw i32 64, %10
      %12 = zext i32 %11 to i64
      %13 = lshr i64 %9, %12
      %14 = or i64 %8, %13
      ret i64 %14
    }

    attributes #0 = { noinline nounwind ssp uwtable }
    """, "next"), UInt64, Tuple{Ptr{UInt64}}, state)
end


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
@inline Base.rand(rng::StaticRNG) = rand(Float64, rng)
@inline Base.rand(::Type{Int64}, rng::StaticRNG) = reinterpret(Int64, rand(UInt64, rng))
@inline Base.rand(::Type{Float64}, rng::StaticRNG) = rand(UInt64, rng) / typemax(UInt64)
@inline Base.rand(::Type{UInt64}, rng::StaticRNG{1}) = splitmix64(rng)
@inline Base.rand(::Type{UInt64}, rng::StaticRNG{4}) = xoshiro256✴︎✴︎(rng)


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
@inline upm1(rng) = rand(UInt64, rng)/(typemax(UInt64)/2) - 1.0
@inline lsqrt(x::Float64) = @symbolcall llvm.sqrt.f64(x::Float64)::Float64
@inline llog(x::Float64) = @symbolcall log(x::Float64)::Float64
@inline lsin(x::Float64) = @symbolcall llvm.sin.f64(x::Float64)::Float64
@inline lcos(x::Float64) = @symbolcall llvm.cos.f64(x::Float64)::Float64


# Extend Base.randn
@inline function Base.randn(rng::BoxMuller)
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
@inline function Base.randn(rng::MarsagliaPolar)
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
@inline function Base.randn(rng::StaticRNG)
    u₁, u₂ = rand(rng), rand(rng)
    R = lsqrt(-2*llog(u₁))
    Θ = 2pi*u₂
    z₁ = R * lcos(Θ)
end
