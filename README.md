# StaticTools

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://brenhinkeller.github.io/StaticTools.jl/dev) [![CI](https://github.com/brenhinkeller/StaticTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/brenhinkeller/StaticTools.jl/actions/workflows/CI.yml)
[![CI (Integration)](https://github.com/brenhinkeller/StaticTools.jl/workflows/CI%20(Integration)/badge.svg)](https://github.com/brenhinkeller/StaticTools.jl/actions/workflows/CI-integration.yml)
[![CI (Julia nightly)](https://github.com/brenhinkeller/StaticTools.jl/workflows/CI%20(Julia%20nightly)/badge.svg)](https://github.com/brenhinkeller/StaticTools.jl/actions/workflows/CI-julia-nightly.yml)
[![CI (Integration nightly)](https://github.com/brenhinkeller/StaticTools.jl/workflows/CI%20(Integration%20nightly)/badge.svg)](https://github.com/brenhinkeller/StaticTools.jl/actions/workflows/CI-integration-nightly.yml)
[![Coverage](https://codecov.io/gh/brenhinkeller/StaticTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/brenhinkeller/StaticTools.jl)

Tools to enable [StaticCompiler.jl](https://github.com/tshort/StaticCompiler.jl)-based static compilation of Julia code (or more accurately, a subset of Julia which we might call "unsafe Julia") to standalone native binaries by avoiding GC allocations and `llvmcall`-ing all the things. Warning: experimental! 🐛

This package currently requires Julia 1.8 for best results (in particular, 1.8.0-beta3 is known to work). Integration tests against StaticCompiler.jl and LoopVectorization.jl are currently run with Julia 1.8 on x86-64 linux and mac; other platforms and versions may or may not work but will depend on StaticCompiler.jl support.

While we'll do our best to keep things working, this package should still be considered experimental at present, and necessarily involves a lot of juggling of pointers and such (i.e., "unsafe Julia"). If I've made errors in any of the `llvmcall`s (which we have to use instead of simpler `ccall`s for things to statically compile smoothly), there could be serious bugs or even undefined behavior. PRs welcome!

The stack-allocated statically-sized `StaticString`s in this package are heavily inspired by the techniques used in [JuliaSIMD/ManualMemory.jl](https://github.com/JuliaSIMD/ManualMemory.jl); you can use that package via [StrideArraysCore.jl](https://github.com/JuliaSIMD/StrideArraysCore.jl) or [StrideArrays.jl](https://github.com/chriselrod/StrideArrays.jl) to obtain fast stack-allocated statically-sized arrays which should also be StaticCompiler-friendly.

In addition to the exported names, Julia `Base` functions extended for StaticTools types (`StaticString`, `MallocString`, and `MallocArray`) include:
* `print`, `println`, `error`,
* `parse`,
* `rand` (when using an `rng` initialied with `static_rng()`, `SplitMix64()`, or `Xoshiro256✴︎✴︎()` )
* and much or all of the `AbstractArray` and `AbstractString` interfaces where relevant.

[![Mandelbrot Set in the terminal with compiled Julia](docs/mandelcompilemov.jpg)](http://www.youtube.com/watch?v=YsNC4oO0rLA)

### Limitations:
In order to be standalone-compileable without linking to libjulia, you need to avoid (among probably other things):
* GC allocations. Manual heap-allocation (`malloc`, `calloc`) and stack allocation (by convincing the Julia compiler to use `alloca` and put your object on the stack) are all fine though.
* Non-`const`ant global variables
* Type instability.
* Anything that could cause an `InexactError` or `OverflowError` -- so `x % Int32` may work in some cases when `Int32(x)` may not.
* Anything that could cause a `BoundsError` -- so `@inbounds` (or else `julia --check-bounds=no`) is mandatory.
* Functions that don't want to inline (can cause sneaky allocations) -- feel free to use `@inline` liberally to avoid.
* Multithreading

This package can help you with avoiding some of the above, but you'll still need to be quite careful in how you write your code! I'd recommend starting small and adding features slowly.

On the other hand, a surprising range of higher-order language features _will_ work (e.g., multiple dispatch, metaprogramming) as long as they can happen before compile-time.

While, as noted above, manually allocating your own memory on the heap with `malloc` or `calloc` and operating on that memory via pointers will work just fine (as is done in `MallocArray`s and `MallocString`s), by doing this we have effectively stepped into a subset of Julia which we might call "unsafe Julia" -- the same subset you step into when you interact with C objects in Julia, but also one which means you're dealing with objects that don't follow the normal Julia object model. 👻

Fortunately, going to all this trouble does have some side benefits besides compileability:
* Type instability is one of the biggest sources of unnecessarily bad performance in naive Julia code, especially when you're new to multiple dispatch -- well, won't be able to make that mistake by accident here!
* No GC means no GC pauses
* Since we're only including what we need, binaries can be quite small (e.g. 8.4K for Hello World)

## Examples

#### Simple command-line executable with variable arguments:
```julia
# This is all StaticCompiler-friendly
using StaticTools

function print_args(argc::Int, argv::Ptr{Ptr{UInt8}})
    # c"..." lets you construct statically-sized, stack allocated `StaticString`s
    # We also have m"..." and MallocString if you want the same thing but on the heap
    printf(c"Argument count is %d:\n", argc)
    for i=1:argc
        # iᵗʰ input argument string
        pᵢ = unsafe_load(argv, i) # Get pointer
        strᵢ = MallocString(pᵢ) # Can wrap to get high-level interface
        println(strᵢ)
        # No need to `free` since we didn't allocate this memory
    end
    println(c"That was fun, see you next time!")
    return 0
end

# Compile executable
using StaticCompiler
filepath = compile_executable(print_args, (Int64, Ptr{Ptr{UInt8}}), "./")
```
and...
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

shell> hyperfine './print_args hello there'
Benchmark 1: ./print_args hello there
  Time (mean ± σ):       2.6 ms ±   0.5 ms    [User: 0.9 ms, System: 0.0 ms]
  Range (min … max):     1.8 ms …   5.9 ms    542 runs

  Warning: Command took less than 5 ms to complete. Results might be inaccurate.

shell> ls -lh $filepath
  -rwxr-xr-x  1 user  staff   8.4K May 22 13:58 print_args
```
Note that the resulting executable is only 8.4 kilobytes in size!

#### MallocArrays with size determined at runtime:
```julia
using StaticTools
function times_table(argc::Int, argv::Ptr{Ptr{UInt8}})
    argc == 3 || return printf(c"Incorrect number of command-line arguments\n")
    rows = parse(Int64, argv, 2)            # First command-line argument
    cols = parse(Int64, argv, 3)            # Second command-line argument

    M = MallocArray{Int64}(undef, rows, cols)
    @inbounds for i=1:rows
        for j=1:cols
            M[i,j] = i*j
        end
    end
    printf(M)
    free(M)
end

using StaticCompiler
filepath = compile_executable(times_table, (Int64, Ptr{Ptr{UInt8}}), "./")
```
which gives us...
```
shell> ls -lh $filepath
-rwxr-xr-x  1 user  staff   8.6K May 22 14:00 times_table

shell> ./times_table 12, 7
1   2   3   4   5   6   7
2   4   6   8   10  12  14
3   6   9   12  15  18  21
4   8   12  16  20  24  28
5   10  15  20  25  30  35
6   12  18  24  30  36  42
7   14  21  28  35  42  49
8   16  24  32  40  48  56
9   18  27  36  45  54  63
10  20  30  40  50  60  70
11  22  33  44  55  66  77
12  24  36  48  60  72  84
```

These `MallocArray`s can be `reshape`d and `reinterpret`ed  without causing any new allocations. Unlike base `Array`s, `getindex` produces fast views by default when indexing memory-contiguous slices.
```julia
julia> function times_table(argc::Int, argv::Ptr{Ptr{UInt8}})
           argc == 3 || return printf(c"Incorrect number of command-line arguments\n")
           rows = parse(Int64, argv, 2)            # First command-line argument
           cols = parse(Int64, argv, 3)            # Second command-line argument

           M = MallocArray{Int64}(undef, rows, cols)
           @inbounds for i=1:rows
               for j=1:cols
                   M[i,j] = i*j
               end
           end
           printf(M)
           M = reinterpret(Int32, M)
           println(c"\n\nThe same array, reinterpreted as Int32:")
           printf(M)
           free(M)
       end
times_table (generic function with 1 method)

julia> filepath = compile_executable(times_table, (Int64, Ptr{Ptr{UInt8}}), "./")
"/Users/user/times_table"

shell> ./times_table 3 3
1	2	3
2	4	6
3	6	9


The same array, reinterpreted as Int32:
1	2	3
0	0	0
2	4	6
0	0	0
3	6	9
0	0	0
```

#### Random number generation:
```julia
julia> function rand_matrix(argc::Int, argv::Ptr{Ptr{UInt8}})
          argc == 3 || return printf(stderrp(), c"Incorrect number of command-line arguments\n")
          rows = parse(Int64, argv, 2)            # First command-line argument
          cols = parse(Int64, argv, 3)            # Second command-line argument

          M = MallocArray{Float64}(undef, rows, cols)
          rng = static_rng()
          @inbounds for i=1:rows
              for j=1:cols
                  M[i,j] = rand(rng)
              end
          end
          printf(M)
          free(M)
       end
rand_matrix (generic function with 1 method)

julia> compile_executable(rand_matrix, (Int64, Ptr{Ptr{UInt8}}), "./")
"/Users/user/rand_matrix"

shell> ./rand_matrix 5 5
7.890932e-01    7.532989e-01    8.593202e-01    4.790301e-01    6.464508e-01
5.619692e-01    9.800402e-02    8.545220e-02    5.545224e-02    2.966089e-01
7.021460e-01    4.587692e-01    9.316740e-01    8.736913e-01    8.271038e-01
8.098993e-01    5.368138e-01    3.055373e-02    3.972266e-01    8.146640e-01
8.241520e-01    7.532375e-01    2.969434e-01    9.436580e-01    2.819992e-01

shell> hyperfine './rand_matrix 5 5'
Benchmark 1: ./rand_matrix 5 5
  Time (mean ± σ):       2.6 ms ±   0.4 ms    [User: 0.9 ms, System: 0.0 ms]
  Range (min … max):     1.8 ms …   4.2 ms    501 runs

  Warning: Command took less than 5 ms to complete. Results might be inaccurate.

shell> ls -alh rand_matrix
  -rwxr-xr-x  1 user  staff   8.8K May 22 14:02 rand_matrix
```

#### LoopVectoriztion.jl compatibility!
```julia
using StaticCompiler
using StaticTools
using LoopVectorization

@inline function mul!(C::MallocArray, A::MallocArray, B::MallocArray)
    @turbo for n ∈ indices((C,B), 2), m ∈ indices((C,A), 1)
        Cmn = zero(eltype(C))
        for k ∈ indices((A,B), (2,1))
            Cmn += A[m,k] * B[k,n]
        end
        C[m,n] = Cmn
    end
    return C
end

function loopvec_matrix(argc::Int, argv::Ptr{Ptr{UInt8}})
    argc == 3 || return printf(stderrp(), c"Incorrect number of command-line arguments\n")
    rows = parse(Int64, argv, 2)            # First command-line argument
    cols = parse(Int64, argv, 3)            # Second command-line argument

    # LHS
    A = MallocArray{Float64}(undef, rows, cols)
    @turbo for i ∈ axes(A, 1)
        for j ∈ axes(A, 2)
           A[i,j] = i*j
        end
    end

    # RHS
    B = MallocArray{Float64}(undef, cols, rows)
    @turbo for i ∈ axes(B, 1)
        for j ∈ axes(B, 2)
           B[i,j] = i*j
        end
    end

    # # Matrix multiplication
    C = MallocArray{Float64}(undef, cols, cols)
    mul!(C, B, A)

    # Print to stdout
    printf(C)

    # Clean up matrices
    free(A)
    free(B)
    free(C)
end

# Attempt to compile
path = compile_executable(loopvec_matrix, (Int64, Ptr{Ptr{UInt8}}), "./")
```
which gives us a 21k executable that allocates, fills, multiplies two 100x100
matrices and prints results in 6.3 ms singlethreaded
```
shell> ./loopvec_matrix 10 3
3.850000e+02	7.700000e+02	1.155000e+03
7.700000e+02	1.540000e+03	2.310000e+03
1.155000e+03	2.310000e+03	3.465000e+03

shell> hyperfine './loopvec_matrix 100 100'
Benchmark 1: ./loopvec_matrix 100 100
  Time (mean ± σ):       6.2 ms ±   0.6 ms    [User: 4.1 ms, System: 0.0 ms]
  Range (min … max):     5.2 ms …   8.5 ms    337 runs

shell> ls -alh loopvec_matrix
-rwxr-xr-x  1 cbkeller  staff    21K May 22 14:11 loopvec_matrix
```
