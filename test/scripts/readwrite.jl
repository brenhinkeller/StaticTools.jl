using StaticCompiler
using StaticTools

function readwrite(argc::Int, argv::Ptr{Ptr{UInt8}})
    argc == 3 || return printf(stderrp(), c"Incorrect number of command-line arguments\n")
    rows = argparse(Int64, argv, 2)            # First command-line argument
    cols = argparse(Int64, argv, 3)            # Second command-line argument

    M = MallocArray{Int64}(undef, rows, cols)
    @inbounds for i=1:rows
        for j=1:cols
           M[i,j] = i*j
        end
    end
    # Print to file
    fwrite(c"table.b", M)
    printdlm(c"table.tsv", M)


    Mb = read(c"table.b", MallocArray{Int64})
    Mbv = ArrayView{Int64,2}(pointer(Mb), rows*cols, (rows, cols))
    printf(Mbv)

    Ms = read(c"table.b", MallocString)
    Msv = ArrayView{Int64,2}(pointer(Ms), rows*cols, (rows, cols))
    printf(Msv)

    Mts = read(c"table.tsv", MallocString)
    printf(Mts)

    # Mt = parsedlm(Int64, c"table.tsv")

    match = Mb == Mbv == Msv

    # Clean up
    free(M), free(Mb), free(Ms), free(Mts)

    return !match % Int32
end

# Attempt to compile
path = compile_executable(readwrite, (Int64, Ptr{Ptr{UInt8}}), "./")
