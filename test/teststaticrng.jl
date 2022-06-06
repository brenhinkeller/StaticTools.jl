
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

# Test Xoshiro256✴︎✴︎ initialized with constant seed
rng = Xoshiro256✴︎✴︎((1,1,1,1))
@test rand(UInt64, rng) === 0x0000000000001680
@test rand(Int64, rng) === 5760
@test rand(rng) === 4.092726157978177e-11
