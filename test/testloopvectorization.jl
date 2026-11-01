# Setup
cd(scratch)

## --- Test LoopVectorization integration

@static if Bool(LoopVectorization.VectorizationBase.has_feature(Val{:x86_64_avx2}))
    let
        # Compile...
        cleanup("loopvec_product")
        status = -1
        try
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
    cleanup("loopvec_matrix")
    status = -1
    try
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
    @test parsedlm(c"table.tsv",'\t') == A' * A
    # Check binary output
    @test fread!(szeros(5,5), c"table.b") == A' * A
end

let
    # Compile...
    cleanup("loopvec_matrix_stack")
    status = -1
    try
        status = run(`$jlpath --startup=no --compile=min $testpath/scripts/loopvec_matrix_stack.jl`)
    catch e
        @warn "Could not compile $testpath/scripts/loopvec_matrix_stack.jl"
        println(e)
    end
    @test isa(status, Base.Process)
    @test isa(status, Base.Process) && status.exitcode == 0

    # Run...
    cleanup("table.tsv")
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
    @test parsedlm(c"table.tsv",'\t') == A' * A
end

## --- Clean up

cd(testpath)
