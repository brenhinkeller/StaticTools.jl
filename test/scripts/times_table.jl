using StaticCompiler
using StaticTools

function times_table(argc::Int, argv::Ptr{Ptr{UInt8}})
    argc == 3 || return printf(stderrp(), c"Incorrect number of command-line arguments\n")
    rows = argparse(Int64, argv, 2)            # First command-line argument
    cols = argparse(Int64, argv, 3)            # Second command-line argument

    M = MallocArray{Int64}(undef, rows, cols)
    @inbounds for i=1:rows
        for j=1:cols
           M[i,j] = i*j
        end
    end
    # Print to stdout
    print(M)
    # Also print to file
    fwrite(c"table.b", M)
    printdlm(c"table.tsv", M)

    # Test reinterpreting
    Mr = reinterpret(Int32, M)
    println(c"\nThe same array, reinterpreted as Int32:")
    print(Mr)

    # Clean up matrix
    free(M)
end

# Attempt to compile
path = compile_executable(times_table, (Int64, Ptr{Ptr{UInt8}}), "./")
