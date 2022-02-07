## --- The basics of basics: putchar

function putchar(c::UInt8)
    Base.llvmcall(("""
    ; External declaration of the puts function
    declare i32 @putchar(i8 nocapture) nounwind

    define i32 @main(i8) {
    entry:
        %call = call i32 (i8) @putchar(i8 %0)
        ret i32 0
    }
    """, "main"), Int32, Tuple{UInt8}, c)
end
putchar(c::Char) = putchar(UInt8(c))
newline() = putchar(0x0a)

## --- The old reliable: puts

function puts(p::Ptr{UInt8})
    Base.llvmcall(("""
    ; External declaration of the puts function
    declare i32 @puts(i8* nocapture) nounwind

    define i32 @main(i8*) {
    entry:
        %call = call i32 (i8*) @puts(i8* %0)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}}, p)
end
puts(s::MallocString) = puts(pointer(s))
puts(s) = GC.@preserve s puts(pointer(s))

## --- Printf, just a string

function printf(p::Ptr{UInt8})
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}}, p)
end
printf(s::MallocString) = printf(pointer(s))
printf(s) = GC.@preserve s printf(pointer(s))

function printf(fmt::Ptr{UInt8}, s::Ptr{UInt8})
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i8*) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i8* %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, Ptr{UInt8}}, fmt, s)
end
printf(fmt::MallocString, s::MallocString) = printf(pointer(fmt), pointer(s))
printf(fmt, s) = GC.@preserve fmt s printf(pointer(fmt), pointer(s))


## --- printf, with a format string, just like in C

printf(fmt::StaticString, n::Union{Number, Ptr}) = GC.@preserve fmt printf(pointer(fmt), n)
printf(fmt::MallocString, n::Union{Number, Ptr}) = printf(pointer(fmt), n)

# Floating point numbers
function printf(fmt::Ptr{UInt8}, n::Float64)
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, double) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, double %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, Float64}, fmt, n)
end
# Just convert everything else to double
function printf(fmt::Ptr{UInt8}, n::AbstractFloat)
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, double) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, double %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, Float64}, fmt, Float64(n))
end

# Integers
function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int64, UInt64, Ptr}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i64) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i64 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
end
function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int32, UInt32}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i32) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i32 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
end
function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int16, UInt16}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i16) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i16 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
end
function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int8, UInt8}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i8) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i8 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
end

## ---

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
    return 0
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
    return 0
end


## ---
