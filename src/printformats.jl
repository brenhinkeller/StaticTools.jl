## --- Auto-formatted `printf` methods for Julia types

# Pick a printf format string depending on the type
printfmt(::Type{<:AbstractFloat}) = c"%e"
printfmt(::Type{<:Integer}) = c"%d"
printfmt(::Type{<:Ptr})  = c"Ptr @0x%016x" # Assume 64-bit pointers
printfmt(::Type{UInt64}) = c"0x%016x"
printfmt(::Type{UInt32}) = c"0x%08x"
printfmt(::Type{UInt16}) = c"0x%04x"
printfmt(::Type{UInt8})  = c"0x%02x"
printfmt(::Type{<:Union{MallocString, StaticString}}) = c"\"%s\"" # Can I offer you a string in this trying time?

# Top-level formats, single numbers
function printf(n::T) where T <: Union{Number, Ptr}
    printf(printfmt(T), n)
    newline()
end

# Print a vector
function printf(v::AbstractVector{T}) where T <: Union{Number, Ptr, StaticString}
    fmt = printfmt(T)
    p = pointer(fmt)
    @inbounds GC.@preserve fmt for i ∈ eachindex(v)
        printf(p, v[i])
        newline()
    end
    return zero(Int32)
end

# Print a tuple
function printf(v::NTuple{N, T} where N) where T <: Union{Number, Ptr, StaticString}
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
function printf(m::AbstractMatrix{T}) where T <: Union{Number, Ptr, StaticString}
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
function printf(fp::Ptr{FILE}, n::T) where T <: Union{Number, Ptr}
    printf(fp, printfmt(T), n)
    newline(fp)
end


# Print a vector
function printf(fp::Ptr{FILE}, v::AbstractVector{T}) where T <: Union{Number, Ptr, StaticString}
    fmt = printfmt(T)
    p = pointer(fmt)
    @inbounds GC.@preserve fmt for i ∈ eachindex(v)
        printf(fp, p, v[i])
        newline(fp)
    end
    return zero(Int32)
end

# Print a tuple
function printf(fp::Ptr{FILE}, v::NTuple{N, T} where N) where T <: Union{Number, Ptr, StaticString}
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
function printf(fp::Ptr{FILE}, m::AbstractMatrix{T}) where T <: Union{Number, Ptr, StaticString}
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
