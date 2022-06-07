
rng = static_rng()
@test isa(rng, StaticTools.StaticRNG)
@test isa(rng, Xoshiro256✴︎✴︎)
r = rand(rng)
@test isa(r, Float64)
@test 0 <= r <= 1

r = rand(UInt64, rng)
@test isa(r, UInt64)

# Test SplitMix64 initialized with constant seed
rng = SplitMix64(0)
@test rand(UInt64, rng) === 0xe220a8397b1dcdaf
@test rand(Int64, rng) === 7960286522194355700
@test rand(rng) === 0.026433771592597816
bm = BoxMuller(rng)
@test randn(bm) === 0.15062167061669643
mp = MarsagliaPolar(rng)
@test randn(mp) === -0.9741485722677525

# Test Xoshiro256✴︎✴︎ initialized with constant seed
rng = Xoshiro256✴︎✴︎(0) # Initialized using SplitMix64 initizlized with seed!
@test rand(UInt64, rng) === 0x99ec5f36cb75f2b4
@test rand(Int64, rng) === -4652746763540216534
@test rand(rng) === 0.10301998939503641
bm = BoxMuller(rng)
@test randn(bm) === -1.315825649730135
mp = MarsagliaPolar(rng)
@test randn(mp) === 1.579109828558518
