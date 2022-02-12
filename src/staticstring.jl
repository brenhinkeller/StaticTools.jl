## ---  Define a StatiCompiler- and LLVM-compatible statically-sized string type

    # Define the StaticString type, backed by an NTuple

    # Definition and constructors:
    mutable struct StaticString{N}
        data::NTuple{N,UInt8}
        @inline function StaticString{N}(::UndefInitializer) where N
            new{N}()
        end
        @inline function StaticString(data::NTuple{N,UInt8}) where N
            new{N}(data)
        end
    end

    # String macro to create null-terminated `StaticString`s
    macro c_str(s)
        n = _unsafe_unescape!(s)
        t = Expr(:tuple, codeunits(s[1:n])..., 0x00)
        :(StaticString($t))
    end

    # Fundamentals
    @inline Base.unsafe_convert(::Type{Ptr{T}}, m::StaticString) where {T} = Ptr{T}(pointer_from_objref(m))
    @inline Base.pointer(m::StaticString{N}) where {N} = Ptr{UInt8}(pointer_from_objref(m))
    @inline Base.length(s::StaticString{N}) where N = N
    @inline Base.:(==)(::StaticString, ::StaticString) = false
    @inline function Base.:(==)(a::StaticString{N}, b::StaticString{N}) where N
        GC.@preserve a b begin
            pa, pb = pointer(a), pointer(b)
            for n in 0:N-1
                unsafe_load(pa + n) == unsafe_load(pb + n) || return false
            end
            return true
        end
    end

    # Custom printing
    Base.print(s::StaticString) = (printf(s); nothing)
    Base.println(s::StaticString) = (puts(s); nothing)
    Base.print(fp::Ptr{FILE}, s::StaticString) = (printf(fp, s); nothing)
    Base.println(fp::Ptr{FILE}, s::StaticString) = (puts(fp, s); nothing)

    # Custom replshow for interactive use (n.b. _NOT_ static-compilerable)
    function Base.show(io::IO, s::StaticString)
        Base.print(io, "c\"")
        Base.escape_string(io, Base.unsafe_string(pointer(s)))
        Base.print(io, "\"")
    end

    # Implement some of the AbstractArray interface:
    Base.firstindex(s::StaticString) = 1
    Base.lastindex(s::StaticString{N}) where N = N
    Base.getindex(s::StaticString, i::Int) = unsafe_load(pointer(s)+(i-1))
    Base.getindex(s::StaticString, r::AbstractArray{Int}) = StaticString(codeunits(s)[r]) # Should probably null-terminate
    Base.getindex(s::StaticString, ::Colon) = s
    Base.setindex!(s::StaticString, x::UInt8, i::Int) = unsafe_store!(pointer(s)+(i-1), x)
    Base.setindex!(s::StaticString, x, i::Int) = unsafe_store!(pointer(s)+(i-1), convert(UInt8, x))
    @inline function Base.setindex!(s::StaticString, x, r::UnitRange{Int})
        is₀ = first(r)-1
        ix₀ = firstindex(x)-1
        @inbounds for i = 1:length(r)
            setindex!(s, x[i+ix₀], i+is₀)
        end
    end
    @inline function Base.setindex!(s::StaticString, x, ::Colon)
        ix₀ = firstindex(x)-1
        @inbounds for i = 1:length(s)
            setindex!(s, x[i+ix₀], i)
        end
    end
    Base.copy(s::StaticString) = StaticString(codeunits(s))


    # Implement some of the AbstractString interface
    Base.ncodeunits(s::StaticString{N}) where N = N
    Base.codeunits(s::StaticString) = s.data
    Base.codeunit(s::StaticString) = UInt8
    Base.codeunit(s::StaticString, i::Integer) = s[i]
    @inline function Base.:*(a::StaticString, b::StaticString)  # Concatenation
        N = length(a) + length(b) - 1
        c = StaticString{N}(undef)
        c[1:length(a)-1] = a
        c[length(a):end-1] = b
        c[end] = 0x00 # Null-terminate
        return c
    end
    @inline function Base.:^(s::StaticString, n::Integer)       # Repetition
        l = length(s)-1 # Excluding the null-termination
        N = n*l + 1
        c = StaticString{N}(undef)
        for i=1:n
            c[(l*(i-1) + 1):(l*i)] = s
        end
        c[end] = 0x00 # Null-terminate
        return c
    end


    # String macro to directly create null-terminated `ManualMemory.MemoryBuffer`s
    macro mm_str(s)
        n = _unsafe_unescape!(s)
        t = Expr(:tuple, codeunits(s[1:n])...)
        :(MemoryBuffer($t))
    end
