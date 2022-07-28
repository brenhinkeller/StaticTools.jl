
rng = static_rng()
@test isa(rng, StaticTools.StaticRNG)
@test isa(rng, Xoshiro256✴︎✴︎)
r = rand(rng)
@test isa(r, Float64)
@test 0 <= r <= 1

r = rand(rng, UInt64)
@test isa(r, UInt64)

# Test SplitMix64 initialized with constant seed
rng = SplitMix64(0)
@test rand(rng, UInt64)::UInt64 ≈ 0xe220a8397b1dcdaf
@test rand(rng, Int64)::Int64 ≈ 7960286522194355700
@test rand(rng)::Float64 ≈ 0.026433771592597816
bm = BoxMuller(rng)
@test randn(bm)::Float64 ≈ 0.15062167061669643
mp = MarsagliaPolar(rng)
@test randn(mp)::Float64 ≈ -0.9741485722677525

# Test Xoshiro256✴︎✴︎ initialized with constant seed
rng = Xoshiro256✴︎✴︎(0) # Initialized using SplitMix64 initizlized with seed!
@test rand(rng, UInt64)::UInt64 ≈ 0x99ec5f36cb75f2b4
@test rand(rng, Int64)::Int64 ≈ -4652746763540216534
@test rand(rng)::Float64 ≈ 0.10301998939503641
bm = BoxMuller(rng)
@test randn(bm)::Float64 ≈ -1.315825649730135
mp = MarsagliaPolar(rng)
@test randn(mp)::Float64 ≈ 1.579109828558518
