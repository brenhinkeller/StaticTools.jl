
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
@test rand(rng, UInt64)::UInt64 == 0xe220a8397b1dcdaf
@test rand(rng, Int64)::Int64 == 7960286522194355700
@test rand(rng)::Float64 ≈ 0.026433771592597816
bm = BoxMuller(rng)
@test randn(bm)::Float64 ≈ 0.15062167061669643
mp = MarsagliaPolar(rng)
@test randn(mp)::Float64 ≈ -0.9741485722677525

# Test Xoshiro256✴︎✴︎ initialized with constant seed
rng = Xoshiro256✴︎✴︎(0) # Initialized using SplitMix64 initizlized with seed!
@test rand(rng, UInt64)::UInt64 == 0x99ec5f36cb75f2b4
@test rand(rng, Int64)::Int64 == -4652746763540216534
@test rand(rng, UInt32)::UInt32 == 0x1a5f849d
@test rand(rng, Int32)::Int32 == 1789236465
@test rand(rng, UInt16)::UInt16 == 0xbba5
@test rand(rng, Int16)::Int16 == -17
@test rand(rng)::Float64 ≈ 0.4222115238253156
@test rand(rng, Float32)::Float32 ≈ 0.53565484f0
@test rand(rng, Float16)::Float16 ≈ Float16(0.8555)

# Test Gaussian RNG backed by Xoshiro256✴︎✴︎
bm = BoxMuller(rng)
@test randn(bm)::Float64 ≈ 0.2706967696867094
mp = MarsagliaPolar(rng)
@test randn(mp)::Float64 ≈ -0.055103387336872575
zig = Ziggurat(rng)
@test randn(zig)::Float64 ≈ -0.5164601817068389

# Test non-scalar methods

A = sfill(10.0, 10,10)
randn!(bm, A)
@test isapprox(sum(A)/length(A), 0.0, atol = 0.5)

A .= 10
randn!(mp, A)
@test isapprox(sum(A)/length(A), 0.0, atol = 0.5)

A .= 10
randn!(zig, A)
@test isapprox(sum(A)/length(A), 0.0, atol = 0.5)

# A .= 10
# randn!(rng, A)
# @test isapprox(sum(A)/length(A), 0.0, atol = 1)
