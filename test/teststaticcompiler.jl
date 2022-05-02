# Setup
testpath = pwd()
scratch = tempdir()
cd(scratch)

## --- Times table:

# Attempt to compile
# We have to start a new Julia process to get around the fact that Pkg.test
# disables `@inbounds`, but ironically we can use `--compile=min` to make that
# faster.
status = run(`julia --compile=min $testpath/times_table.jl`)
@test isa(status, Base.Process)
@test status.exitcode == 0

# Attempt to run
println("5x5 times table:")
status = run(`./times_table 5 5`)
@test isa(status, Base.Process)
@test status.exitcode == 0

## --- Random number generation

# Attempt to compile
# We have to start a new Julia process to get around the fact that Pkg.test
# disables `@inbounds`, but ironically we can use `--compile=min` to make that
# faster.
status = run(`julia --compile=min $testpath/rand_matrix.jl`)
@test isa(status, Base.Process)
@test status.exitcode == 0

# Attempt to run
println("5x5 random matrix:")
status = run(`./rand_matrix 5 5`)
@test isa(status, Base.Process)
@test status.exitcode == 0

## ---

cd(testpath)
