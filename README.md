# StaticTools

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://brenhinkeller.github.io/StaticTools.jl/dev)
[![Build Status](https://github.com/brenhinkeller/StaticTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/brenhinkeller/StaticTools.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/brenhinkeller/StaticTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/brenhinkeller/StaticTools.jl)

Tools to enable [StaticCompiler.jl](https://github.com/tshort/StaticCompiler.jl)-based static compilation of Julia code to standalone native binaries by eliding GC allocations and `llvmcall`-ing all the things.

### Examples
```julia
# This is all StaticCompiler-friendly
using StaticTools

function print_args(argc::Int, argv::Ptr{Ptr{UInt8}})
    # c"..." lets you construct statically-sized, stack allocated `StaticString`s
    printf(c"Argument count is %d:\n", argc)
    for i=1:argc
        # Get pointer of iᵗʰ input argument string
        pᵢ = unsafe_load(argv, i)
        # Copy that to a dynamically-sized MallocString, just for fun
        str = unsafe_mallocstring(pᵢ)
        println(str) # s::MallocString
        free(str)
    end
    println(c"That was fun, see you next time!")
    return 0
end
```
This API is liable to change, but for an example:
```julia
# Compile executable
using StaticCompiler: generate_executable # to get this branch: ] add https://github.com/brenhinkeller/StaticCompiler.jl#executables
path, name = generate_executable(print_args, Tuple{Int64, Ptr{Ptr{UInt8}}}, "./")
```
shell> ./print_args 1 2 3 4 5.0 foo
Argument count is 7:
./print_args
1
2
3
4
5.0
foo
That was fun, see you next time!
```
