## --- `printf` with a format and any number of arguments

# `printf(fmt, a, ...)` and `printf(fp, fmt, a, ...)`: libc's variadic `printf` and `fprintf`, with a format and any
# number of arguments (`printformats.jl` prints several things without a format, and arrays and numbers with one).

# What can be an argument of `printf`
const PrintfArgument = Union{Number, Ptr, AbstractStaticString, String}
# The format string
const PrintfFormat = Union{StaticString, MallocString, String, Ptr{UInt8}}

# C passes arguments of the variadic part of a function by the "default argument promotions": integers
# smaller than an `int` are an `int`, and a `float` is a `double`
const CArgument = Union{Int32, UInt32, Int64, UInt64, Float64, Ptr{UInt8}}
@inline cvalue(x::Union{Int8, Int16, Int32, UInt8, UInt16, Bool}) = Int32(x)
@inline cvalue(x::Union{UInt32, Int64, UInt64}) = x
@inline cvalue(x::Union{Float16, Float32, Float64}) = Float64(x)
@inline cvalue(x::Ptr) = Ptr{UInt8}(x)
# strings: the pointer to the characters, valid as long as the string is kept alive (see `withcvalues`)
@inline cvalue(x::Union{StaticString, MallocString, AbstractStaticString, String}) = pointer(x)

# The type of an argument in LLVM IR
llvmtype(::Type{Int32}) = "i32"
llvmtype(::Type{UInt32}) = "i32"
llvmtype(::Type{Int64}) = "i64"
llvmtype(::Type{UInt64}) = "i64"
llvmtype(::Type{Float64}) = "double"
llvmtype(::Type{Ptr{UInt8}}) = "i8*"

# `printf(fmt, args...)` and `fprintf(fp, fmt, args...)` of libc for arguments of the types `T`
@generated function printf_c(fmt::Ptr{UInt8}, args::Vararg{CArgument, N}) where {N}
    params = join((", $(llvmtype(T)) %a$i" for (i, T) in enumerate(args)))
    ir = """
    declare i32 @printf(i8* noalias nocapture, ...)

    define i32 @main(i8* %fmt$params) #0 {
    entry:
      %status = call i32 (i8*, ...) @printf(i8* %fmt$params)
      ret i32 %status
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """
    return :(Base.llvmcall(($ir, "main"), Int32, Tuple{Ptr{UInt8}, $(args...)}, fmt, args...))
end

@generated function fprintf_c(fp::Ptr{FILE}, fmt::Ptr{UInt8}, args::Vararg{CArgument, N}) where {N}
    params = join((", $(llvmtype(T)) %a$i" for (i, T) in enumerate(args)))
    ir = """
    declare i32 @fprintf(i8* noalias nocapture, i8*, ...)

    define i32 @main(i8* %fp, i8* %fmt$params) #0 {
    entry:
      %status = call i32 (i8*, i8*, ...) @fprintf(i8* %fp, i8* %fmt$params)
      ret i32 %status
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """
    return :(Base.llvmcall(($ir, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, $(args...)}, fp, fmt, args...))
end

# The call of `printf_c` (or `fprintf_c`) with the arguments converted to what C takes: a string is its pointer,
# which only stays valid if the string is kept alive (`GC.@preserve`) while C uses it. Written out for the types of the
# arguments (as a recursion over the arguments that builds the converted ones is not inferred for more than a few
# arguments of different types, and then allocates), with the arguments in local variables to preserve.
function printf_expr(cfunction, prefix, argtypes, sources)
    names = [Symbol(:x, i) for i in eachindex(argtypes)]
    assigns = [:($name = $source) for (name, source) in zip(names, sources)]
    isstring(T) = T <: Union{StaticString, MallocString, AbstractStaticString, String}
    preserved = [name for (name, T) in zip(names, argtypes) if isstring(T)]
    return quote
        $(assigns...)
        GC.@preserve $(preserved...) $cfunction($(prefix...), $([:(cvalue($name)) for name in names]...))
    end
end

"""
```julia
printf([fp::Ptr{FILE}], fmt, a, ...)
```
Libc `printf` (or `fprintf`, with a file pointer `fp`) function, accessed by direct `llvmcall`, with
a C-style format `fmt` (a `c"..."` string, a `MallocString`, a `String`, or a `Ptr{UInt8}`) and any number of
arguments: integers, floating-point numbers, pointers, and, for `%s`, strings (`StaticString`s,
`MallocString`s, and `String`s).

This is C's `printf`, with its format specifiers: unlike Julia's `@printf`, an `Int64` is `%lld` (or
`%ld` where `long` is 64 bits), as `%d` is for a 32-bit `int`; `%u` and `%x` are `unsigned`,
`%llu` and `%llx` the 64-bit ones, `%f`, `%e` and `%g` are for floating-point numbers (any size), `%s` is for
a string, and `%p` for a pointer. Smaller integers and `Bool` are promoted to `int` as in C.

Returns the number of characters written, or a negative number if there was an error.

## Examples
```julia
julia> printf(c"%d + %d = %d\\n", 1, 2, 1 + 2);
1 + 2 = 3

julia> printf(c"%s has %5.2f%% of %lld\\n", c"x", 12.345, 10^12);
x has 12.35% of 1000000000000

julia> printf(stderrp(), c"%s: %d\\n", c"error", 3);
error: 3
```

See also: `puts`, `fwrite`
"""
@generated function printf(fmt::PrintfFormat, a::PrintfArgument, args::Vararg{PrintfArgument})
    sources = [:fmt, :a, (:(args[$i]) for i in eachindex(args))...]
    return printf_expr(:printf_c, (), (fmt, a, args...), sources)
end
@generated function printf(fp::Ptr{FILE}, fmt::PrintfFormat, a::PrintfArgument, args::Vararg{PrintfArgument})
    sources = [:fmt, :a, (:(args[$i]) for i in eachindex(args))...]
    return :(fp == C_NULL ? Int32(-1) : $(printf_expr(:fprintf_c, (:fp,), (fmt, a, args...), sources)))
end
