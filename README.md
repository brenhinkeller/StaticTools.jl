# StaticTools

[![Docs][docs-dev-img]][docs-dev-url]
[![CI][ci-img]][ci-url]
[![CI (Integration)][ci-integration-img]][ci-integration-url]
[![CI (Julia nightly)][ci-nightly-img]][ci-nightly-url]
[![CI (Integration nightly)][ci-integration-nightly-img]][ci-integration-nightly-url]
[![Coverage][codecov-img]][codecov-url]


Tools to enable [StaticCompiler.jl](https://github.com/tshort/StaticCompiler.jl)-based static compilation of Julia code (or more accurately, a subset of Julia which we might call "unsafe Julia") to standalone native binaries by avoiding GC allocations and `llvmcall`-ing all the things! (Experimental! 🐛)

This package currently requires Julia 1.8 or greater for best results (if in doubt, check [which versions are passing CI](https://github.com/brenhinkeller/StaticTools.jl/actions?query=workflow%3ACI++)). Integration tests against StaticCompiler.jl and LoopVectorization.jl are currently run with Julia 1.8 and 1.9 on x86-64 linux and mac; other platforms and versions may or may not work but will depend on StaticCompiler.jl support.

While we'll do our best to keep things working, this package should still be considered experimental at present, and necessarily involves a lot of juggling of pointers and such (i.e., "unsafe Julia"). If there are errors in any of the `llvmcall`s (which we have to use instead of simpler `ccall`s for things to statically compile smoothly), there could be serious bugs or even undefined behavior. Please report any unexpected bugs you find, and PRs are welcome!

In addition to the exported names, Julia `Base` functions extended for StaticTools types (i.e., `StaticString`/ `MallocString` and `StackArray`/`MallocArray`) include:
* `print`, `println`, `error`,
* `parse`, `read`, `write`
* `rand`/`rand!` (when using an `rng` initialied with `static_rng`, `SplitMix64`, or `Xoshiro256✴︎✴︎` )
* `randn`/`randn!` (when using an `rng` initialied with `MarsagliaPolar`, `BoxMuller`, or `Ziggurat` )
* and much or all of the `AbstractArray` and `AbstractString` interfaces where relevant.

The stack-allocated statically-sized `StaticString`s and `StackArray`s in this package are heavily inspired by the techniques used in [JuliaSIMD/ManualMemory.jl](https://github.com/JuliaSIMD/ManualMemory.jl); you can use that package via [StrideArraysCore.jl](https://github.com/JuliaSIMD/StrideArraysCore.jl) or [StrideArrays.jl](https://github.com/chriselrod/StrideArrays.jl) to obtain fast stack-allocated statically-sized arrays which should also be StaticCompiler-friendly, up to the stack limit size. For larger arrays, space must be allocated with `malloc`, as in `MallocArray`s. However, as in any other language, any memory `malloc`ed must be freed once and only once. If you want `malloc`-backed StaticCompiler-able arrays without taking on this risk and responsibility, you may consider a bump allocator like [Bumper.jl](https://github.com/MasonProtter/Bumper.jl)

[![Mandelbrot Set in the terminal with compiled Julia](docs/mandelcompilemov.jpg)](http://www.youtube.com/watch?v=YsNC4oO0rLA)
[printmandel.jl](https://gist.github.com/brenhinkeller/ca2246ab0928e109e281a4d540010b2d)

### Limitations:
In order to be standalone-compileable without linking to libjulia, you need to avoid (among probably other things):
* GC allocations. Manual heap-allocation (`malloc`, `calloc`) and stack allocation (by convincing the Julia compiler to use `alloca` and put your object on the stack) are all fine though.
* Non-`const`ant global variables
* Type instability.
* Anything that could cause an `InexactError` or `OverflowError` -- so `x % Int32` may work in some cases when `Int32(x)` may not.
* Anything that could cause a `BoundsError` -- so `@inbounds` (or else `julia --check-bounds=no`) is mandatory. Consequently, `@inbounds` is _always on_ for `MallocArray`s and `StackArray`s; be sure to treat them accordingly when indexing!
* Functions that don't want to inline (can cause sneaky allocations due to boxing) -- feel free to use `@inline` liberally to avoid.
* Multithreading
* Microsoft Windows (not supported by StaticCompiler yet), except via WSL

This package can help you with avoiding some of the above, but you'll still need to be quite careful in how you write your code! I'd recommend starting small and adding features slowly.

On the other hand, a surprising range of higher-order language features _will_ work (e.g., multiple dispatch, metaprogramming) as long as they can happen before compile-time.

While, as noted above, manually allocating your own memory on the heap with `malloc` or `calloc` and operating on that memory via pointers will work just fine (as is done in `MallocArray`s and `MallocString`s), by doing this we have effectively stepped into a subset of Julia which we might call "unsafe Julia" -- the same subset you step into when you interact with C objects in Julia, but also one which means you're dealing with objects that don't follow the normal Julia object model. 👻

Fortunately, going to all this trouble does have some side benefits besides compileability:
* Type instability is one of the biggest sources of unnecessarily bad performance in naive Julia code, especially when you're new to multiple dispatch -- well, won't be able to make that mistake by accident here!
* No GC means no GC pauses
* Since we're only including what we need, binaries can be quite small (e.g. 8.4K for Hello World)

### Utilities

The utilities `static_type` and `static_type_contents` are utilities to help convert an object to something similar with fields and type parameters that are amenable to static compilation.  

`static_type` is mainly useful for converting objects that are heavily paramaterized. The SciML infrastructure has a lot of this. The main objects like a `DiffEq.Integrator` has many type parameters, and by default, some are not amenable to static compilation. `static_type` can be used to convert them to forms that can help numerical code to be statically compiled.

For the default rules, `Array`s are converted to `MallocArray`s, and `String`s are converted to `MallocString`s. The default rules can be extended or redefined by using multiple dispatch and a context variable. Note however that these `MallocArray`s and `MallocString`s must be `free`d when you are done with them.

## Examples

### Compiled command-line executables

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
If we want to have dynamically-sized arrays, we'll have to allocate them ourselves.
The `MallocArray` type is one way to do that.
```julia
using StaticTools
function times_table(argc::Int, argv::Ptr{Ptr{UInt8}})
    argc == 3 || return printf(c"Incorrect number of command-line arguments\n")
    rows = argparse(Int64, argv, 2)            # First command-line argument
    cols = argparse(Int64, argv, 3)            # Second command-line argument

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
           rows = argparse(Int64, argv, 2)            # First command-line argument
           cols = argparse(Int64, argv, 3)            # Second command-line argument

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

#### StackArrays with size determined at compile-time:
If we know the size of an array at compile-time, we can avoid the `malloc` and
keep the array on the stack instead (as long as it's small enough to fit on the
stack) with the `StackArray` type:
```
julia> function stack_times_table()
           a = StackArray{Int64}(undef, 5, 5)
           for i ∈ axes(a,1)
               for j ∈ axes(a,2)
                   a[i,j] = i*j
               end
           end
           print(a)
       end

julia> filepath = compile_executable(stack_times_table, (), "./")
"/Users/user/stack_times_table"

shell> ./stack_times_table
1   2   3   4   5
2   4   6   8   10
3   6   9   12  15
4   8   12  16  20
5   10  15  20  25
```

#### Random number generation:
```julia
julia> function rand_matrix(argc::Int, argv::Ptr{Ptr{UInt8}})
          argc == 3 || return printf(stderrp(), c"Incorrect number of command-line arguments\n")
          rows = argparse(Int64, argv, 2)            # First command-line argument
          cols = argparse(Int64, argv, 3)            # Second command-line argument

          rng = static_rng()

          M = MallocArray{Float64}(undef, rows, cols)
          rand!(rng, M)         # rand(rng) to generate a single number instead
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
    rows = argparse(Int64, argv, 2)            # First command-line argument
    cols = argparse(Int64, argv, 3)            # Second command-line argument

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
```julia-repl
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

### Compiled `.so`/`.dylib` shared libraries

#### Calling compiled Julia library from Python
Say we were to take the example above, but we wanted to compile it into a shared
library to, say, call from another language. For example, let's say we wanted to
be able to call our nice fast `LoopVectorization.jl`-based `mul!` function from
Python...

##### Julia:
```julia
using StaticCompiler
using StaticTools
using LoopVectorization
using Base: RefValue

@inline function mul!(C::MallocArray, A::MallocArray, B::MallocArray)
    @turbo for n ∈ indices((C,B), 2), m ∈ indices((C,A), 1)
        Cmn = zero(eltype(C))
        for k ∈ indices((A,B), (2,1))
            Cmn += A[m,k] * B[k,n]
        end
        C[m,n] = Cmn
    end
    return 0
end

# this will let us accept pointers to MallocArrays
mul!(C::Ref,A::Ref,B::Ref) = mul!(C[], A[], B[])

# Note that we have to specify a contrete type for each argument when compiling!
# So not just any MallocArra but in this case specifically MallocArray{Float64,2}
# (AKA MallocMatrix{Float64})
tt = (RefValue{MallocMatrix{Float64}}, RefValue{MallocMatrix{Float64}}, RefValue{MallocMatrix{Float64}})
compile_shlib(mul!, tt, "./", "mul_inplace", filename="libmul")
```
Note that with shared libraries, we're no longer limited to just `argc::Int, argv::Ptr{Ptr{UInt8}}`.
In principle, we can pass just about anything we want! However, it's usually easiest
to pass either plain native number types or else pointers to more complicated objects.
`MallocArray`s would qualify as the latter, hence passing pointers to refs

##### Python side:
```python
import ctypes as ct
import numpy as np

class MallocMatrix(ct.Structure):
    _fields_ = [("pointer", ct.c_void_p),
                ("length", ct.c_int64),
                ("s1", ct.c_int64),
                ("s2", ct.c_int64)]

def mmptr(A):
    ptr = A.ctypes.data_as(ct.c_void_p)
    a = MallocMatrix(ptr, ct.c_int64(A.size), ct.c_int64(A.shape[1]), ct.c_int64(A.shape[0]))
    return ct.byref(a)

lib = ct.CDLL("./libmul.dylib")

A = np.ones((10,10))
B = np.ones((10,10))
C = np.ones((10,10))

Aptr = mmptr(A)
Bptr = mmptr(B)
Cptr = mmptr(C)

lib.julia_mul_inplace(Cptr, Bptr, Aptr)
```
Note that here we have basically just mimiced the structure of the `MallocArray` Julia `struct`
```julia
struct MallocArray{T,N}
    pointer::Ptr{T}
    length::Int
    size::NTuple{N, Int}
end
```
with a python `class`
```python
class MallocMatrix(ct.Structure):
    _fields_ = [("pointer", ct.c_void_p),
                ("length", ct.c_int64),
                ("s1", ct.c_int64),
                ("s2", ct.c_int64)]
```
In particular, we can use two integers `s1` and `s2` for the two integers in `size`,
which in this case is specifically an `Ntuple{2, Int}`, because we're talking
about a 2d array -- but note that we have to flip the order, because Python is
row-major in contrast to Julia which is column-major!

Then, wrap that in a ref with `ct.byref` before passing that to our shared library...

##### Results:
```python
lib.julia_mul_inplace(Cptr, Bptr, Aptr)
Out[2]: 0

C
Out[3]:
array([[10., 10., 10., 10., 10., 10., 10., 10., 10., 10.],
       [10., 10., 10., 10., 10., 10., 10., 10., 10., 10.],
       [10., 10., 10., 10., 10., 10., 10., 10., 10., 10.],
       [10., 10., 10., 10., 10., 10., 10., 10., 10., 10.],
       [10., 10., 10., 10., 10., 10., 10., 10., 10., 10.],
       [10., 10., 10., 10., 10., 10., 10., 10., 10., 10.],
       [10., 10., 10., 10., 10., 10., 10., 10., 10., 10.],
       [10., 10., 10., 10., 10., 10., 10., 10., 10., 10.],
       [10., 10., 10., 10., 10., 10., 10., 10., 10., 10.],
       [10., 10., 10., 10., 10., 10., 10., 10., 10., 10.]])

%timeit lib.julia_mul_inplace(Cptr, Bptr, Aptr)
549 ns ± 6.78 ns per loop (mean ± std. dev. of 7 runs, 1000000 loops each)

%timeit np.matmul(A,B)
2.24 µs ± 39.9 ns per loop (mean ± std. dev. of 7 runs, 100000 loops each)
```
so about 4x faster than numpy.matmul for a 10x10 matrix, not counting the time to obtain the pointers.

#### Calling compiled Julia library from Julia
That said, if we were to go back to Julia...
```julia
using Libdl
lib = Libdl.dlopen("./libmul.$(Libdl.dlext)", Libdl.RTLD_LOCAL)
mul_inplace = Libdl.dlsym(lib, "julia_mul_inplace")

A = MallocArray{Float64}(undef, 10, 10); A .= 1
B = MallocArray{Float64}(undef, 10, 10); B .= 1
C = MallocArray{Float64}(undef, 10, 10); C .= 0

ra, rb, rc = Ref(A), Ref(B), Ref(C)
pa, pb, pc = pointer_from_objref(ra), pointer_from_objref(rb), pointer_from_objref(rc)

ccall(mul_inplace, Int, (Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), pc, pa, pb)

Libdl.dlclose(lib)
```

there would seem to be still about another 5x on the table:
```julia-repl
julia> ccall(mul_inplace, Int, (Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), pc, pa, pb)
0

julia> C
10×10 MallocMatrix{Float64}:
 10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0
 10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0
 10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0
 10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0
 10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0
 10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0
 10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0
 10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0
 10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0
 10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0  10.0

julia> using BenchmarkTools

julia> @benchmark ccall($mul_inplace, Int, (Ptr{nothing}, Ptr{nothing}, Ptr{nothing}), $pc, $pa, $pb)
BenchmarkTools.Trial: 10000 samples with 956 evaluations.
 Range (min … max):  90.455 ns … 285.144 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     93.046 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   99.250 ns ±  16.589 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  ▄█▅▁▁▃▂▂▂   ▂▁       ▁                                       ▁
  ██████████████████▇▇▇██▇▇▇▇▇▆▇▇▇▆▆▆▆▆▆▆▅▅▆▆▅▅▅▄▅▅▅▅▅▅▅▆▄▄▄▅▅ █
  90.5 ns       Histogram: log(frequency) by time       178 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```

#### Calling compiled Julia library from compiled Julia
And of course if we want to bring this full-circle:
```julia
using StaticTools, StaticCompiler

function dlmul()
    lib = StaticTools.dlopen(c"./libmul.dylib")
    mul_inplace = StaticTools.dlsym(lib, c"julia_mul_inplace")

    A = MallocArray{Float64}(undef, 5, 5); fill!(A, 1)
    B = MallocArray{Float64}(undef, 5, 5); fill!(B, 1)
    C = MallocArray{Float64}(undef, 5, 5); fill!(C, 0)

    ra, rb, rc = Ref(A), Ref(B), Ref(C)
    GC.@preserve ra rb rc begin
        pa, pb, pc = pointer_from_objref(ra), pointer_from_objref(rb), pointer_from_objref(rc)
        @ptrcall mul_inplace(pc::Ptr{Nothing}, pa::Ptr{Nothing}, pb::Ptr{Nothing})::Int
    end
    StaticTools.dlclose(lib)
    printf(C)
end

compile_executable(dlmul, (), "./")
```
```julia-repl
shell> ./dlmul
5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00
5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00
5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00
5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00
5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00
```
### Linking against existing libraries during compilation:
Existing shared libraries can also be linked against by specifying the
relevant compiler flags during compilation, just as you would with GCC or clang.
For example, the following is equivalent to the above example where we explicitly
`dlopen`ed our `libmul`:
```julia
using StaticTools, StaticCompiler

function dlmul()
    A = MallocArray{Float64}(undef, 5, 5); fill!(A, 1)
    B = MallocArray{Float64}(undef, 5, 5); fill!(B, 1)
    C = MallocArray{Float64}(undef, 5, 5); fill!(C, 0)

    ra, rb, rc = Ref(A), Ref(B), Ref(C)
    GC.@preserve ra rb rc begin
        pa, pb, pc = pointer_from_objref(ra), pointer_from_objref(rb), pointer_from_objref(rc)
        @symbolcall julia_mul_inplace(pc::Ptr{Nothing}, pa::Ptr{Nothing}, pb::Ptr{Nothing})::Int
    end
    printf(C)
end

compile_executable(dlmul, (), "./", cflags=`-lmul -L./`)
```
```julia
shell> ./dlmul
5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00
5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00
5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00
5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00
5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00    5.000000e+00
```

For a more complicated example, here we link at compile time against
[MPI](https://en.wikipedia.org/wiki/Message_Passing_Interface),
the Message Passing Interface used in high-performance computing -- in this
case via [StaticMPI.jl](https://github.com/brenhinkeller/StaticMPI.jl), which
merely provides convenience functions to `@symbolcall` the relevant functions
from `libmpi.dylib`:
```julia
julia> using StaticCompiler, StaticTools, StaticMPI

julia> function mpihello(argc, argv)
           MPI_Init(argc, argv)

           comm = MPI_COMM_WORLD
           world_size, world_rank = MPI_Comm_size(comm), MPI_Comm_rank(comm)

           printf((c"Hello from ", world_rank, c" of ", world_size, c" processors!\n"))
           MPI_Finalize()
       end
mpihello (generic function with 1 method)

julia> compile_executable(mpihello, (Int, Ptr{Ptr{UInt8}}), "./";
           cflags=`-lmpi -L/opt/local/lib/mpich-mp/`
           # -lmpi instructs compiler to link against libmpi.so / libmpi.dylib
           # -L/opt/local/lib/mpich-mp/ provides path to my local MPICH installation where libmpi can be found
       )

ld: warning: object file (./mpihello.o) was built for newer OSX version (12.0) than being linked (10.13)
"/Users/me/code/StaticTools.jl/mpihello"

shell> mpiexec -np 4 ./mpihello
Hello from 1 of 4 processors!
Hello from 3 of 4 processors!
Hello from 2 of 4 processors!
Hello from 0 of 4 processors!
```

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://brenhinkeller.github.io/StaticTools.jl/dev/
[ci-img]: https://github.com/brenhinkeller/StaticTools.jl/workflows/CI/badge.svg
[ci-url]: https://github.com/brenhinkeller/StaticTools.jl/actions/workflows/CI.yml
[ci-nightly-img]: https://github.com/brenhinkeller/StaticTools.jl/workflows/CI%20(Julia%20nightly)/badge.svg
[ci-nightly-url]: https://github.com/brenhinkeller/StaticTools.jl/actions/workflows/CI-julia-nightly.yml
[ci-integration-img]: https://github.com/brenhinkeller/StaticTools.jl/workflows/CI%20(Integration)/badge.svg
[ci-integration-url]: https://github.com/brenhinkeller/StaticTools.jl/actions/workflows/CI-integration.yml
[ci-integration-nightly-img]: https://github.com/brenhinkeller/StaticTools.jl/workflows/CI%20(Integration%20nightly)/badge.svg
[ci-integration-nightly-url]: https://github.com/brenhinkeller/StaticTools.jl/actions/workflows/CI-integration-nightly.yml
[codecov-img]: http://codecov.io/github/brenhinkeller/StaticTools.jl/coverage.svg?branch=main
[codecov-url]: http://app.codecov.io/github/brenhinkeller/StaticTools.jl?branch=main
