# Setup
testpath = pwd()
scratch = tempdir()
cd(scratch)

## --- Times table, file IO, mallocarray

# Attempt to compile
# We have to start a new Julia process to get around the fact that Pkg.test
# disables `@inbounds`, but ironically we can use `--compile=min` to make that
# faster.
status = run(`julia --compile=min $testpath/scripts/times_table.jl`)
@test isa(status, Base.Process)
@test status.exitcode == 0

# Attempt to run
println("5x5 times table:")
status = run(`./times_table 5 5`)
@test isa(status, Base.Process)
@test status.exitcode == 0
@test parsedlm(Int64, c"table.tsv", '\t') == (1:5)*(1:5)'

## --- Random number generation

# Compile...
# We have to start a new Julia process to get around the fact that Pkg.test
# disables `@inbounds`, but ironically we can use `--compile=min` to make that
# faster.
status = run(`julia --compile=min $testpath/scripts/rand_matrix.jl`)
@test isa(status, Base.Process)
@test status.exitcode == 0

# Run...
println("5x5 random matrix:")
status = run(`./rand_matrix 5 5`)
@test isa(status, Base.Process)
@test status.exitcode == 0

## --- Test LoopVectorization integration

if Bool(LoopVectorization.VectorizationBase.has_feature(Val{:x86_64_avx2}))
    # Compile...
    status = run(`julia --compile=min $testpath/scripts/loopvec_product.jl`)
    @test isa(status, Base.Process)
    @test status.exitcode == 0

    # Run...
    println("10x10 table sum:")
    status = run(`./loopvec_product 10 10`)
    @test isa(status, Base.Process)
    @test status.exitcode == 0
    @test parsedlm(c"product.tsv",'\t')[] == 3025
end

# Compile...
status = run(`julia --compile=min $testpath/scripts/loopvec_matrix.jl`)
@test isa(status, Base.Process)
@test status.exitcode == 0

# Run...
println("10x5 matrix product:")
status = run(`./loopvec_matrix 10 5`)
@test isa(status, Base.Process)
@test status.exitcode == 0
A = (1:10) * (1:5)'
@test parsedlm(c"table.tsv",'\t') == A' * A

## --- Test string handling

# Compile...
status = run(`julia --compile=min $testpath/scripts/print_args.jl`)
@test isa(status, Base.Process)
@test status.exitcode == 0

# Run...
println("String indexing and handling:")
status = run(`./print_args foo bar`)
@test isa(status, Base.Process)
@test status.exitcode == 0

## --- Clean up

cd(testpath)

## ---
