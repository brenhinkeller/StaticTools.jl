# Setup
testpath = pwd()
scratch = tempdir()
cd(scratch)
jlpath = joinpath(Sys.BINDIR, Base.julia_exename()) # Get path to julia executable

## --- Times table, file IO, mallocarray
let
    # Attempt to compile
    # We have to start a new Julia process to get around the fact that Pkg.test
    # disables `@inbounds`, but ironically we can use `--compile=min` to make that
    # faster.
    status = -1
    try
        isfile("times_table") && rm("times_table")
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/times_table.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/times_table.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Attempt to run
    println("4x4 times table (MallocArray):")
    status = -1
    try
        status = run(`./times_table 4 4`)
    catch e
        @warn "Could not run $(scratch)/times_table"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0
    # Test ascii output
    @test parsedlm(Int, c"table.tsv", '\t') == (1:4)*(1:4)' broken=(Sys.ARCH===:aarch64)
    # Test binary output
    @test fread!(szeros(Int, 4,4), c"table.b") == (1:4)*(1:4)'
end

## --- As above but with staticarray

let
    # Compile...
    status = -1
    try
        isfile("stack_times_table") && rm("stack_times_table")
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/stack_times_table.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/stack_times_table.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Run..
    println("5x5 times table (StackArray):")
    status = -1
    try
        status = run(`./stack_times_table`)
    catch e
        @warn "Could not run $(scratch)/stack_times_table"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0
    # Test ascii output
    @test parsedlm(Int, c"table.tsv", '\t') == (1:5)*(1:5)'  broken=(Sys.ARCH===:aarch64)
    # Test binary output
    @test fread!(szeros(Int, 5,5), c"table.b") == (1:5)*(1:5)'
end


## --- Reading from written files

let
    # Compile...
    status = -1
    try
        isfile("readwrite") && rm("readwrite")
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/readwrite.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/readwrite.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Run...
    println("5x5 times table, read from file:")
    status = -1
    try
        status = run(`./readwrite 5 5`)
    catch e
        @warn "Could not run $(scratch)/readwrite"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0
    # Test binary output
    @test fread!(szeros(Int, 5,5), c"table.b") == (1:5)*(1:5)'
    # Test ascii output
    @test parsedlm(Int, c"table.tsv", '\t') == (1:5)*(1:5)'  broken=(Sys.ARCH===:aarch64)
    @test parsedlm(Int, c"tableb.tsv", '\t') == (1:5)*(1:5)'  broken=(Sys.ARCH===:aarch64)
    @test parsedlm(Int, c"tables.tsv", '\t') == (1:5)*(1:5)'  broken=(Sys.ARCH===:aarch64)
    @test parsedlm(Int, c"tablets.tsv", '\t') == (1:5)*(1:5)'  broken=(Sys.ARCH===:aarch64)

end


## --- "withmallocarray"-type do-block pattern
let
    # Compile...
    status = -1
    try
        isfile("withmallocarray") && rm("withmallocarray")
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/withmallocarray.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/withmallocarray.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Run...
    println("3x3 malloc arrays via do-block syntax:")
    status = -1
    try
        status = run(`./withmallocarray 3 3`)
    catch e
        @warn "Could not run $(scratch)/withmallocarray"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0
end

## --- Random number generation
let
    # Compile...
    status = -1
    try
        isfile("rand_matrix") && rm("rand_matrix")
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/rand_matrix.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/rand_matrix.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Run...
    println("5x5 uniform random matrix:")
    status = -1
    try
        status = run(`./rand_matrix 5 5`)
    catch e
        @warn "Could not run $(scratch)/rand_matrix"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0
end

let
    # Compile...
    status = -1
    try
        isfile("randn_matrix") && rm("randn_matrix")
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/randn_matrix.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/randn_matrix.jl"
        println(e)
    end
    @static if Sys.isbsd()
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0
    end

    # Run...
    println("5x5 Normal random matrix:")
    status = -1
    try
        status = run(`./randn_matrix 5 5`)
    catch e
        @warn "Could not run $(scratch)/randn_matrix"
        println(e)
    end
    @static if Sys.isbsd()
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0
    end
end

## --- Test LoopVectorization integration
@static if Bool(LoopVectorization.VectorizationBase.has_feature(Val{:x86_64_avx2}))
    let
        # Compile...
        status = -1
        try
            isfile("loopvec_product") && rm("loopvec_product")
            status = run(`$jlpath --startup=no --compile=min $testpath/scripts/loopvec_product.jl`)
        catch e
            @warn "Could not compile $testpath/scripts/loopvec_product.jl"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0

        # Run...
        println("10x10 table sum:")
        status = -1
        try
            status = run(`./loopvec_product 10 10`)
        catch e
            @warn "Could not run $(scratch)/loopvec_product"
            println(e)
        end
        @test isa(status, Base.Process)
        @test isa(status, Base.Process) && status.exitcode == 0
        @test parsedlm(c"product.tsv",'\t')[] == 3025
    end
end

let
    # Compile...
    status = -1
    try
        isfile("loopvec_matrix") && rm("loopvec_matrix")
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/loopvec_matrix.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/loopvec_matrix.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Run...
    println("10x5 MallocMatrix product, manual LoopVec:")
    status = -1
    try
        status = run(`./loopvec_matrix 10 5`)
    catch e
        @warn "Could not run $(scratch)/loopvec_matrix"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0
    A = (1:10) * (1:5)'
    # Check ascii output
    @test parsedlm(c"table.tsv",'\t') == A' * A  broken=(Sys.ARCH===:aarch64)
    # Check binary output
    @test fread!(szeros(5,5), c"table.b") == A' * A
end

let
    # Compile...
    status = -1
    try
        isfile("loopvec_matrix_stack") && rm("loopvec_matrix_stack")
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/loopvec_matrix_stack.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/loopvec_matrix_stack.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Run...
    println("10x5 StackMatrix product, manual LoopVec:")
    status = -1
    try
        status = run(`./loopvec_matrix_stack`)
    catch e
        @warn "Could not run $(scratch)/loopvec_matrix_stack"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0
    A = (1:10) * (1:5)'
    @test parsedlm(c"table.tsv",'\t') == A' * A  broken=(Sys.ARCH===:aarch64)
end

## --- Test standard matrix multiplication
let
    # Compile...
    status = -1
    try
        isfile("matmul") && rm("matmul")
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/matmul.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/matmul.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Run...
    println("10x5 MallocMatrix product:")
    status = -1
    try
        status = run(`./matmul 10 5`)
    catch e
        @warn "Could not run $(scratch)/matmul"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0
    A = (1:10) * (1:5)'
    # Check ascii output
    @test parsedlm(c"table.tsv",'\t') == A' * A  broken=(Sys.ARCH===:aarch64)
    # Check binary output
    @test fread!(szeros(5,5), c"table.b") == A' * A
end

let
    # Compile...
    status = -1
    try
        isfile("matmul_stack") && rm("matmul_stack")
        status = run(`$jlpath --compile=min $testpath/scripts/matmul_stack.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/matmul_stack.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Run...
    println("10x5 StackMatrix product:")
    status = -1
    try
        status = run(`./matmul_stack`)
    catch e
        @warn "Could not run $(scratch)/matmul_stack"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0
    A = (1:10) * (1:5)'
    # Check ascii output
    @test parsedlm(c"table.tsv",'\t') == A' * A  broken=(Sys.ARCH===:aarch64)
    # Check binary output
    @test fread!(szeros(5,5), c"table.b") == A' * A
end

## --- Test string handling

let
    # Compile...
    status = -1
    try
        isfile("print_args") && rm("print_args")
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/print_args.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/print_args.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Run...
    println("String indexing and handling:")
    status = -1
    try
        status = run(`./print_args foo bar`)
    catch e
        @warn "Could not run $(scratch)/print_args"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0
end

## --- Test string iteration

# let
#     # Compile...
#     status = -1
#     try
#         isfile("iterate") && rm("iterate")
#         status = run(`$jlpath --startup=no $testpath/scripts/iterate.jl`)
#     catch e
#         @warn "Could not compile $testpath/scripts/iterate.jl"
#         println(e)
#     end
#     @test isa(status, Base.Process)
#     @test isa(status, Base.Process) && status.exitcode == 0
#
#     # Run...
#     println("Iteration:")
#     status = -1
#     try
#         status = run(`./iterate`)
#     catch e
#         @warn "Could not run $(scratch)/iterate"
#         println(e)
#     end
#     @test isa(status, Base.Process)
#     @test isa(status, Base.Process) && status.exitcode == 0
# end

## --- Test error throwing

let
    # Compile...
    status = -1
    try
        isfile("maybe_throw") && rm("maybe_throw")
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/throw_errors.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/throw_errors.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Run...
    println("Error handling:")
    status = -1
    try
        status = run(`./maybe_throw 10`)
    catch e
        @warn "Could not run $(scratch)/maybe_throw"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0
    status = -1
    try
        status = run(`./maybe_throw -10`)
    catch e
        @info "maybe_throw: task failed sucessfully!"
    end
    @test status === -1
end

## --- Test interop

@static if Sys.isbsd()
let
    # Compile...
    status = -1
    try
        isfile("interop") && rm("interop")
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/interop.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/interop.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Run...
    println("Interop:")
    status = -1
    try
        status = run(`./interop`)
    catch e
        @warn "Could not run $(scratch)/interop"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0
end
end

## --- Clean up

cd(testpath)
