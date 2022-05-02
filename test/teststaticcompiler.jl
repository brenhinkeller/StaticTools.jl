## --- Times table:

# Attempt to compile
status = run(`julia -i times_table.jl`)
@test isa(status, Base.Process)
@test status.exitcode == 0

# Attempt to run
println("5x5 times table:")
status = run(`./times_table 5 5`)
@test isa(status, Base.Process)
@test status.exitcode == 0

## --- Random number generation

# Attempt to compile
status = run(`julia -i rand_matrix.jl`)
@test isa(status, Base.Process)
@test status.exitcode == 0

# Attempt to run
println("5x5 random matrix:")
status = run(`./rand_matrix 5 5`)
@test isa(status, Base.Process)
@test status.exitcode == 0

## ---
