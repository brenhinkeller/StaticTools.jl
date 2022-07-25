using StaticCompiler
using StaticTools

function withmallocarray(argc::Int, argv::Ptr{Ptr{UInt8}})
    argc == 3 || return printf(stderrp(), c"Incorrect number of command-line arguments\n")
    rows = parse(Int64, argv, 2)            # First command-line argument
    cols = parse(Int64, argv, 3)            # Second command-line argument

    mzeros(rows, cols) do A
        printf(A)
    end
    mones(Int, rows, cols) do A
        printf(A)
    end
    mfill(3.141592, rows, cols) do A
        printf(A)
    end
end

# Attempt to compile
path = compile_executable(withmallocarray, (Int64, Ptr{Ptr{UInt8}}), "./")
