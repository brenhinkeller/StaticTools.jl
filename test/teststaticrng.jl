
rng = static_rng()
@test isa(rng, StaticRNG{Xoshiro256✴︎✴︎})
@test isa(rand(rng), Float64)
@test 0 <= rand(rng) <= 1
