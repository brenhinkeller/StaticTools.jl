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

# On Windows, `printf` and `fprintf` are not exported by the C runtime that `fopen`, `fputs`, `fwrite` and friends come
# from (UCRT's `ucrtbase.dll`): there they are inline wrappers in the headers around `__stdio_common_vfprintf`. A
# reference to `@printf` or `@fprintf` in LLVM IR would then be resolved to the legacy `msvcrt.dll`, whose `FILE`s are not
# those of UCRT (and which has its own `stdout`), and crash. So on Windows we do what the headers do, and call
# `__stdio_common_vfprintf` ourselves: the `va_list` of Windows x64 is just a pointer to an array of 8-byte slots
function ucrt_vfprintf_ir(::Type{T}, N::Int, with_fp::Bool) where {T}
    argtypes = T.parameters
    slots = max(N, 1)
    stores = join(map(enumerate(argtypes)) do (i, A)
        slot = "%slot$i"
        conv = if A === Float64
            "  %v$i = bitcast double %a$i to i64\n"
        elseif A === Ptr{UInt8}
            "  %v$i = ptrtoint i8* %a$i to i64\n"
        elseif A === Int32 || A === UInt32
            "  %v$i = zext i32 %a$i to i64\n"
        else # Int64, UInt64
            "  %v$i = add i64 %a$i, 0\n"
        end
        conv * "  $slot = getelementptr [$slots x i64], [$slots x i64]* %buf, i32 0, i32 $(i-1)\n" *
            "  store i64 %v$i, i64* $slot\n"
    end)
    params = join((", $(llvmtype(A)) %a$i" for (i, A) in enumerate(argtypes)))
    fpparam, fpvalue = with_fp ? ("i8* %fp, ", "%fp") : ("", "%stdout")
    getfp = with_fp ? "" : "  %stdout = call i8* @__acrt_iob_func(i32 1)\n"
    return """
    declare i8* @__acrt_iob_func(i32)
    declare i32 @__stdio_common_vfprintf(i64, i8*, i8*, i8*, i8*)

    define i32 @main($(fpparam)i8* %fmt$params) #0 {
    entry:
      %buf = alloca [$slots x i64], align 16
    $stores  %ap = bitcast [$slots x i64]* %buf to i8*
    $getfp  %status = call i32 @__stdio_common_vfprintf(i64 0, i8* $fpvalue, i8* %fmt, i8* null, i8* %ap)
      ret i32 %status
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """
end

# `printf(fmt, args...)` and `fprintf(fp, fmt, args...)` of libc for arguments of the types `T`
@generated function printf_raw(fmt::Ptr{UInt8}, args::Vararg{CArgument, N}) where {N}
    params = join((", $(llvmtype(T)) %a$i" for (i, T) in enumerate(args)))
    ir = if Sys.iswindows()
        ucrt_vfprintf_ir(Tuple{args...}, N, false)
    else
        """
        declare i32 @printf(i8* noalias nocapture, ...)

        define i32 @main(i8* %fmt$params) #0 {
        entry:
          %status = call i32 (i8*, ...) @printf(i8* %fmt$params)
          ret i32 %status
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """
    end
    return :(Base.llvmcall(($ir, "main"), Int32, Tuple{Ptr{UInt8}, $(args...)}, fmt, args...))
end

@generated function fprintf_raw(fp::Ptr{FILE}, fmt::Ptr{UInt8}, args::Vararg{CArgument, N}) where {N}
    params = join((", $(llvmtype(T)) %a$i" for (i, T) in enumerate(args)))
    ir = if Sys.iswindows()
        ucrt_vfprintf_ir(Tuple{args...}, N, true)
    else
        """
        declare i32 @fprintf(i8* noalias nocapture, i8*, ...)

        define i32 @main(i8* %fp, i8* %fmt$params) #0 {
        entry:
          %status = call i32 (i8*, i8*, ...) @fprintf(i8* %fp, i8* %fmt$params)
          ret i32 %status
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """
    end
    return :(Base.llvmcall(($ir, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, $(args...)}, fp, fmt, args...))
end

# UCRT prints `%p` as 16 zero-padded hex digits, without a `0x` (and `(nil)` is `0000000000000000`), unlike glibc and
# macOS libc (`0x1000`). To print the same thing everywhere, on Windows `%p` is rewritten to `0x%llx` before the call
# (pointers are passed as 64-bit integers anyway). This doesn't allocate: the rewritten format goes in a buffer of
# `FMTBUFSIZE` bytes on the stack. `ucrt_fixfmt` returns `fmt` itself if there is no `%p` in it, or if the rewritten
# format would not fit in the buffer (then `%p` is printed the way UCRT does it), or else the pointer to the buffer `out`.
const FMTBUFSIZE = 256
@inline function ucrt_fixfmt(fmt::Ptr{UInt8}, out::Ptr{UInt8}, cap::Int)
    len, nptr = 0, 0
    while (c = unsafe_load(fmt, len+1)) != 0x00
        if c == UInt8('%') # Skip over the character after any `%`, so that `%%p` is left alone
            unsafe_load(fmt, len+2) == UInt8('p') && (nptr += 1)
            len += 1
            unsafe_load(fmt, len+1) == 0x00 && break
        end
        len += 1
    end
    (nptr == 0 || len + 4*nptr + 1 > cap) && return fmt
    i, j = 1, 1
    while i <= len
        c = unsafe_load(fmt, i)
        if c == UInt8('%') && unsafe_load(fmt, i+1) == UInt8('p')
            for x in (UInt8('0'), UInt8('x'), UInt8('%'), UInt8('l'), UInt8('l'), UInt8('x'))
                unsafe_store!(out, x, j); j += 1
            end
            i += 2
        elseif c == UInt8('%') # Copy `%` and the character after it as they are
            unsafe_store!(out, c, j); unsafe_store!(out, unsafe_load(fmt, i+1), j+1)
            i += 2; j += 2
        else
            unsafe_store!(out, c, j); i += 1; j += 1
        end
    end
    unsafe_store!(out, 0x00, j)
    return out
end

# These two are `@noinline` on purpose: they only take pointers and numbers, so the strings that are arguments of
# `printf` can stay on the stack (as they do when `printf` is inlined and C is called directly), while a stack buffer
# in the body of `printf` itself keeps the compiler from inlining it, which would make its arguments heap-allocated
@static if Sys.iswindows()
    @noinline function printf_c(fmt::Ptr{UInt8}, args::Vararg{CArgument, N}) where {N}
        buf = MemoryBuffer{FMTBUFSIZE, UInt8}(undef)
        GC.@preserve buf printf_raw(ucrt_fixfmt(fmt, pointer(buf), FMTBUFSIZE), args...)
    end
    @noinline function fprintf_c(fp::Ptr{FILE}, fmt::Ptr{UInt8}, args::Vararg{CArgument, N}) where {N}
        buf = MemoryBuffer{FMTBUFSIZE, UInt8}(undef)
        GC.@preserve buf fprintf_raw(fp, ucrt_fixfmt(fmt, pointer(buf), FMTBUFSIZE), args...)
    end
else
    const printf_c = printf_raw
    const fprintf_c = fprintf_raw
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
