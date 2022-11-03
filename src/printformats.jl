## --- Auto-formatted `printf` methods for Julia types

# Pick a printf format string depending on the type
@inline printfmt(::Type{<:AbstractFloat}) = c"%e"
@inline printfmt(::Type{<:Integer}) = c"%d"
@inline printfmt(::Type{<:Ptr})  = c"Ptr @0x%016x" # Assume 64-bit pointers
@inline printfmt(::Type{UInt64}) = c"0x%016x"
@inline printfmt(::Type{UInt32}) = c"0x%08x"
@inline printfmt(::Type{UInt16}) = c"0x%04x"
@inline printfmt(::Type{UInt8})  = c"0x%02x"
@inline printfmt(::Type{<:Union{MallocString, StaticString}}) = c"\"%s\"" # Can I offer you a string in this trying time?

# Top-level formats, single numbers
"""
```julia
printf([fp::Ptr{FILE}], [fmt], n::Number)
```
Libc `printf` function, accessed by direct `llvmcall`.

Prints a number `n` to a filestream specified by the file pointer `fp`,
defaulting to the current standard output `stdout` if not specified.

Optionally, a C-style format specifier string `fmt` may be provided as well.

Returns `0` on success.

## Examples
```julia
julia> printf(1)
1
0

julia> printf(1/3)
3.333333e-01
0

julia> printf(c"%f\n", 1/3)
0.333333
0
```
"""
@inline function printf(n::T) where T <: Union{Number, Ptr}
    printf(printfmt(T), n)
    return zero(Int32)
end
# Print a vector
"""
```julia
printf([fp::Ptr{FILE}], a::AbstractArray{<:Number})
```
Print a matrix or vector of numbers `a` to a filestream specified by the file
pointer `fp`, defaulting to the current standard output `stdout` if not specified.

Returns `0` on success.

## Examples
```julia
julia> printf(rand(5,5))
5.500186e-02    8.425572e-01    3.871220e-01    5.442254e-01    5.990694e-02
5.848425e-01    6.714915e-01    5.616896e-01    6.668248e-01    2.643873e-01
9.156712e-01    1.276033e-01    3.350369e-01    6.513146e-01    9.999104e-01
3.301038e-01    6.027120e-01    5.139433e-01    2.219796e-01    4.057417e-01
2.821340e-01    9.258760e-01    7.950481e-01    1.152236e-01    7.949463e-01
0
```
"""
@inline function printf(v::AbstractVector{T}) where T <: Union{Number, Ptr, StaticString}
    fmt = printfmt(T)
    p = pointer(fmt)
    @inbounds GC.@preserve fmt for i ∈ eachindex(v)
        printf(p, v[i])
        newline()
    end
    return zero(Int32)
end

# Print a tuple
@inline function printf(v::NTuple{N, T} where N) where T <: Union{Number, Ptr}
    fmt = printfmt(T)
    p = pointer(fmt)
    putchar(0x28) # open paren
    @inbounds GC.@preserve fmt for i ∈ eachindex(v)
        printf(p, v[i])
        putchar(0x2c) # comma
        putchar(0x20) # space
    end
    putchar(0x29) # close paren
    newline()
end

# Print a 2d matrix
@inline function printf(m::AbstractMatrix{T}) where T <: Union{Number, Ptr, StaticString}
    fmt = printfmt(T)
    p = pointer(fmt)
    @inbounds GC.@preserve fmt for i ∈ axes(m,1)
        for j ∈ axes(m,2)
            printf(p, m[i,j])
            putchar(0x09) # tab
        end
        newline()
    end
    return zero(Int32)
end


## --- Printing to file

# Top-level formats, single numbers
@inline function printf(fp::Ptr{FILE}, n::T) where T <: Union{Number, Ptr}
    printf(fp, printfmt(T), n)
    return zero(Int32)
end


# Print a vector
@inline function printf(fp::Ptr{FILE}, v::AbstractVector{T}) where T <: Union{Number, Ptr, StaticString}
    fmt = printfmt(T)
    p = pointer(fmt)
    @inbounds GC.@preserve fmt for i ∈ eachindex(v)
        printf(fp, p, v[i])
        newline(fp)
    end
    return zero(Int32)
end

# Print a tuple
@inline function printf(fp::Ptr{FILE}, v::NTuple{N, T} where N) where T <: Union{Number, Ptr}
    fmt = printfmt(T)
    p = pointer(fmt)
    putchar(fp, 0x28) # open paren
    @inbounds GC.@preserve fmt for i ∈ eachindex(v)
        printf(fp, p, v[i])
        putchar(fp, 0x2c) # comma
        putchar(fp, 0x20) # space
    end
    putchar(fp, 0x29) # close paren
    newline(fp)
end


# Print a 2d matrix
@inline function printf(fp::Ptr{FILE}, m::AbstractMatrix{T}) where T <: Union{Number, Ptr, StaticString}
    fmt = printfmt(T)
    p = pointer(fmt)
    @inbounds GC.@preserve fmt for i ∈ axes(m,1)
        for j ∈ axes(m,2)
            printf(fp, p, m[i,j])
            putchar(fp, 0x09) # tab
        end
        newline(fp)
    end
    return zero(Int32)
end

## -- Printing a long string of things -- encourage type inference to work a bit harder

"""
```julia
printf([fp::Ptr{FILE}], things::Tuple)
```
Print any number of things, optionally to a file specified by `fp`.

## Examples
```julia
julia> printf((c"Sphinx ", c"of ", c"black ", c"quartz, ", c"judge ", c"my ", c"vow!\n"))
Sphinx of black quartz, judge my vow!
0

julia> x = 1
1

julia> printf((c"The value of x is currently ", x, c"\n"))
The value of x is currently 1
0
```
"""
@inline function printf(args::Tuple{T1, T2}) where {T1, T2}
    Base.Cartesian.@nexprs 2 i->printf(args[i])
    return zero(Int32)
end
@inline function printf(args::Tuple{T1, T2, T3}) where {T1, T2, T3}
    Base.Cartesian.@nexprs 3 i->printf(args[i])
    return zero(Int32)
end
@inline function printf(args::Tuple{T1, T2, T3, T4}) where {T1, T2, T3, T4}
    Base.Cartesian.@nexprs 4 i->printf(args[i])
    return zero(Int32)
end
@inline function printf(args::Tuple{T1, T2, T3, T4, T5}) where {T1, T2, T3, T4, T5}
    Base.Cartesian.@nexprs 5 i->printf(args[i])
    return zero(Int32)
end
@inline function printf(args::Tuple{T1, T2, T3, T4, T5, T6}) where {T1, T2, T3, T4, T5, T6}
    Base.Cartesian.@nexprs 6 i->printf(args[i])
    return zero(Int32)
end
@inline function printf(args::Tuple{T1, T2, T3, T4, T5, T6, T7}) where {T1, T2, T3, T4, T5, T6, T7}
    Base.Cartesian.@nexprs 7 i->printf(args[i])
    return zero(Int32)
end
@inline function printf(args::Tuple{T1, T2, T3, T4, T5, T6, T7, T8}) where {T1, T2, T3, T4, T5, T6, T7, T8}
    Base.Cartesian.@nexprs 8 i->printf(args[i])
    return zero(Int32)
end
# Print to file
@inline function printf(fp::Ptr{FILE}, args::Tuple{T1, T2}) where {T1, T2}
    Base.Cartesian.@nexprs 2 i->printf(fp, args[i])
    return zero(Int32)
end
@inline function printf(fp::Ptr{FILE}, args::Tuple{T1, T2, T3}) where {T1, T2, T3}
    Base.Cartesian.@nexprs 3 i->printf(fp, args[i])
    return zero(Int32)
end
@inline function printf(fp::Ptr{FILE}, args::Tuple{T1, T2, T3, T4}) where {T1, T2, T3, T4}
    Base.Cartesian.@nexprs 4 i->printf(fp, args[i])
    return zero(Int32)
end
@inline function printf(fp::Ptr{FILE}, args::Tuple{T1, T2, T3, T4, T5}) where {T1, T2, T3, T4, T5}
    Base.Cartesian.@nexprs 5 i->printf(fp, args[i])
    return zero(Int32)
end
@inline function printf(fp::Ptr{FILE}, args::Tuple{T1, T2, T3, T4, T5, T6}) where {T1, T2, T3, T4, T5, T6}
    Base.Cartesian.@nexprs 6 i->printf(fp, args[i])
    return zero(Int32)
end
@inline function printf(fp::Ptr{FILE}, args::Tuple{T1, T2, T3, T4, T5, T6, T7}) where {T1, T2, T3, T4, T5, T6, T7}
    Base.Cartesian.@nexprs 7 i->printf(fp, args[i])
    return zero(Int32)
end
@inline function printf(fp::Ptr{FILE}, args::Tuple{T1, T2, T3, T4, T5, T6, T7, T8}) where {T1, T2, T3, T4, T5, T6, T7, T8}
    Base.Cartesian.@nexprs 8 i->printf(fp, args[i])
    return zero(Int32)
end

## -- Print errors

@inline Base.error(s::Union{StaticString,MallocString}) = (perror(c"ERROR: "); perror(s))
@inline warn(s::Union{StaticString,MallocString}) = (perror(c"Warning: "); perror(s))

"""
```julia
perror(s)
```
Print the string `s` to the standard error filestream, `stderr`.

Returns `0` on success.

## Examples
```julia
julia> StaticTools.perror(c"ERROR: could not do thing\n")
ERROR: could not do thing
0
```
"""
@inline perror(s::MallocString) = perror(pointer(s))
@inline perror(s::StaticString) = GC.@preserve s perror(pointer(s))
@inline function perror(s::Ptr{UInt8})
    Base.llvmcall(("""
    ; External declaration of the fprintf function
    declare i32 @fprintf(i8*, i8*)

    define i32 @main(i64 %jlfp, i64 %jls) #0 {
    entry:
      %fp = inttoptr i64 %jlfp to i8*
      %str = inttoptr i64 %jls to i8*
      %status = call i32 (i8*, i8*) @fprintf(i8* %fp, i8* %str)
      ret i32 0
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}}, stderrp(), s)
end

## --- Print delimited data to file

"""
```julia
printdlm(filepath, data, [delim='\t'])
```
Print a vector or matrix `data` as delimited ASCII text to a new file `name` with
delimiter `delim`
Returns `0` on success.

## Examples
```julia
julia> a = szeros(3,3)
3×3 StackMatrix{Float64, 9, (3, 3)}:
 0.0  0.0  0.0
 0.0  0.0  0.0
 0.0  0.0  0.0

julia> printdlm(c"foo.csv", a, ',')
0

shell> cat foo.csv
0.000000e+00,0.000000e+00,0.000000e+00,
0.000000e+00,0.000000e+00,0.000000e+00,
0.000000e+00,0.000000e+00,0.000000e+00,

julia> parsedlm(c"foo.csv", ',')
3×3 MallocMatrix{Float64}:
 0.0  0.0  0.0
 0.0  0.0  0.0
 0.0  0.0  0.0
```
"""
@inline function printdlm(filepath::AbstractString, data, delimiter::Char='\t')
    fp = fopen(filepath, c"w")
    printdlm(fp, data, delimiter)
    fclose(fp)
end
@inline printdlm(fp::Ptr{FILE}, v::AbstractVector, delimiter) = printf(fp, v)
@inline function printdlm(fp::Ptr{FILE}, m::AbstractMatrix{T}, delimiter) where T
    delim = delimiter % UInt8
    fmt = printfmt(T)
    p = pointer(fmt)
    @inbounds GC.@preserve fmt for i ∈ axes(m,1)
        for j ∈ axes(m,2)
            printf(fp, p, m[i,j])
            putchar(fp, delim)
        end
        newline(fp)
    end
    return zero(Int32)
end
