
rng = static_rng()
@test isa(rng, StaticRNG)
@test isa(rng, Xoshiro256✴︎✴︎)
@test isa(rand(rng), Float64)
@test 0 <= rand(rng) <= 1
