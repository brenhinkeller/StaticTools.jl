## ---  Define a StatiCompiler- and LLVM-compatible dynamically-sized string type

    # Define the MallocString type, backed by a Libc.malloc'd heap of memory

    # Definition and constructors:
    struct MallocString <: AbstractMallocdMemory
        pointer::Ptr{UInt8}
        length::Int
    end
    @inline function MallocString(::UndefInitializer, N::Int)
        MallocString(Ptr{UInt8}(Libc.malloc(N)), N)
    end
    @inline function MallocString(data::NTuple{N, UInt8}) where N
        s = MallocString(Ptr{UInt8}(Libc.malloc(N)), N)
        s[:] = data
        return s
    end
    @inline MallocString(p::Ptr{UInt8}) = MallocString(p, strlen(p)+1)

    # String macro to create null-terminated `MallocStrings`s
    macro m_str(s)
        n = _unsafe_unescape!(s)
        t = Expr(:tuple, codeunits(s[1:n])..., 0x00)
        :(MallocString($t))
    end

    # Destructor:
    @inline free(s::MallocString) = Libc.free(s.pointer)


    # Fundamentals
    Base.unsafe_convert(::Type{Ptr{T}}, m::MallocString) where {T} = Ptr{T}(s.pointer)
    Base.pointer(s::MallocString) = s.pointer
    Base.length(s::MallocString) = s.length
    Base.sizeof(s::MallocString) = s.length
    @inline function Base.:(==)(a::MallocString, b::MallocString)
        (N = length(a)) == length(b) || return false
        pa, pb = pointer(a), pointer(b)
        for n in 0:N-1
            unsafe_load(pa + n) == unsafe_load(pb + n) || return false
        end
        return true
    end

    # Custom printing
    Base.print(s::MallocString) = printf(s)
    Base.println(s::MallocString) = puts(s)

    # Custom replshow for interactive use (n.b. _NOT_ static-compilerable)
    function Base.show(io::IO, s::MallocString)
        Base.print(io, "m\"")
        Base.escape_string(io, Base.unsafe_string(pointer(s)))
        Base.print(io, "\"")
    end

    # Some of the AbstractArray interface:
    Base.firstindex(s::MallocString) = 1
    Base.lastindex(s::MallocString) = s.length
    Base.getindex(s::MallocString, i::Int) = unsafe_load(pointer(s)+(i-1))
    Base.setindex!(s::MallocString, x::UInt8, i::Integer) = unsafe_store!(pointer(s)+(i-1), x)
    Base.setindex!(s::MallocString, x, i::Integer) = unsafe_store!(pointer(s)+(i-1), convert(UInt8,x))
    Base.getindex(s::MallocString, r::UnitRange{<:Integer}) = MallocString(pointer(s)+first(r)-1, length(r))
    Base.getindex(s::MallocString, ::Colon) = s
    @inline function Base.setindex!(s::MallocString, x, r::UnitRange{<:Integer})
        is₀ = first(r)-1
        ix₀ = firstindex(x)-1
        for i = 1:length(r)
            s[i+is₀] = x[i+ix₀]
        end
    end
    @inline function Base.setindex!(s::MallocString, x, ::Colon)
        ix₀ = firstindex(x)-1
        for i = 1:length(s)
            s[i] = x[i+ix₀]
        end
    end
    @inline function Base.copy(s::MallocString)
        new_s = MallocString(undef, length(s))
        new_s[:] = s
        return new_s
    end

    # Some of the AbstractString interface
    Base.ncodeunits(s::MallocString) = s.length
    Base.codeunits(s::MallocString) = MallocBuffer{UInt8}(s.pointer, s.length) # TODO: return some sort of array
    Base.codeunit(s::MallocString) = UInt8
    Base.codeunit(s::MallocString, i::Integer) = s[i]
    @inline function Base.:*(a::MallocString, b::MallocString)  # Concatenation
        N = length(a) + length(b) - 1
        c = MallocString(undef, N)
        c[1:length(a)-1] = a
        c[length(a):end-1] = b
        c[end] = 0x00 # Null-terminate
        return c
    end
    @inline function Base.:^(s::MallocString, n::Integer)       # Repetition
        l = length(s)-1 # Excluding the null-termination
        N = n*l + 1
        c = MallocString(undef, N)
        for i=1:n
            c[(l*(i-1) + 1):(l*i)] = s
        end
        c[end] = 0x00 # Null-terminate
        return c
    end

    # As Base.unsafe_string, but loading to a MallocString instead
    @inline function unsafe_mallocstring(p::Ptr{UInt8})
        len = 1
        while unsafe_load(p, len) != 0x00
            len +=1
        end
        s = MallocString(undef, len)
        for i=1:len
            s[i] = unsafe_load(p, i)
        end
        return s
    end
