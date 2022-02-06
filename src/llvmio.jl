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
puts(s) = puts(pointer(s))

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
printf(s) = printf(pointer(s))

function printf(fmt, s)
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i8*) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, Ptr{UInt8}}, pointer(fmt), pointer(s))
end

## --- printf, with a format string, just like in C

# Floating point numbers
function printf(fmt, n::Float64)
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, double) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, double %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, Float64}, pointer(fmt), n)
end
# Just convert everything else to double
function printf(fmt, n::AbstractFloat)
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, double) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, double %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, Float64}, pointer(fmt), Float64(n))
end

# Integers
function printf(fmt, n::T) where T <: Union{Int64, UInt64, Ptr} # We're going to go ahead and assume 64-bit pointers here
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i64) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i64 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, T}, pointer(fmt), n)
end
function printf(fmt, n::T) where T <: Union{Int32, UInt32}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i32) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i32 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, T}, pointer(fmt), n)
end
function printf(fmt, n::T) where T <: Union{Int16, UInt16}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i16) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i16 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, T}, pointer(fmt), n)
end
function printf(fmt, n::T) where T <: Union{Int8, UInt8}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i8) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i8 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, T}, pointer(fmt), n)
end

## ---

    # Pick a printf format string depending on the type
    printfmt(::Type{<:AbstractFloat}) = mm"%e\0"
    printfmt(::Type{<:Integer}) = mm"%d\0"
    printfmt(::Type{<:Ptr}) = mm"Ptr @0x%016x\0" # Assume 64-bit pointers
    printfmt(::Type{UInt64}) = mm"0x%016x\0"
    printfmt(::Type{UInt32}) = mm"%08x\0"
    printfmt(::Type{UInt16}) = mm"%04x\0"
    printfmt(::Type{UInt8}) = mm"%02x\0"
    printfmt(::Type{StaticString}) = mm"\"%s\"\0" # Can I offer you a string in this trying time?

    # Top-level formats, single numbers
    function printf(n::T) where T <: Union{Number, Ptr}
        fmt = printfmt(T)
        GC.@preserve fmt printf(fmt, n)
        newline()
    end

    # Print a vector
    function printf(v::AbstractVector{T}) where T <: Union{Number, Ptr, StaticString}
        fmt = printfmt(T)
        @inbounds GC.@preserve fmt for i ∈ eachindex(v)
            printf(fmt, v[i])
            newline()
        end
    end

    # Print a tuple
    function printf(v::NTuple{N, T} where N) where T <: Union{Number, Ptr, StaticString}
        fmt = printfmtc(T)
        putchar(0x28) # open paren
        @inbounds GC.@preserve fmt for i ∈ eachindex(v)
            printf(fmt, v[i])
            putchar(0x2c) # comma
            putchar(0x20) # space
        end
        putchar(0x29) # close paren
        newline()
    end

    # Print a 2d matrix
    function printf(m::AbstractMatrix{T}) where T <: Union{Number, Ptr, StaticString}
        fmt = printfmt(T)
        @inbounds GC.@preserve fmt for i ∈ axes(m,1)
            for j ∈ axes(m,2)
                printf(fmt, m[i,j])
                putchar(0x09) # tab
            end
            newline()
        end
    end


## ---
