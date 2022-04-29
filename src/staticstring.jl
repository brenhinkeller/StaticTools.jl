## ---  Define a StatiCompiler- and LLVM-compatible statically-sized string type

    # Define the StaticString type, backed by an NTuple

    # Definition and constructors:
    """
    ```julia
    StaticString{N}
    ```
    A stringy type which should generally behave like a base Julia `String`, but
    is explicitly null-terminated, mutable, and standalone-StaticCompiler safe
    (does not require libjulia).

    ---

    ```julia
    StaticString(data::NTuple{N,UInt8})
    ```
    Construct a `StaticString` containing the `N` bytes specified by `data`.

    ## Examples
    ```julia
    julia> data = (0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x21, 0x00);

    julia> StaticString(data)
    c"Hello, world!"
    ```
    """
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
    """
    ```julia
    @c_str -> StaticString
    ```
    Construct a `StaticString`, such as `c"Foo"`.

    A `StaticString` should generally behave like a base Julia `String`, but is
    explicitly null-terminated, mutable, and standalone-StaticCompiler safe (does
    not require libjulia).

    ## Examples
    ```julia
    julia> c"Hello there!"
    c"Hello there!"

    julia> c"foo" == "foo"
    true
    ```
    """
    macro c_str(s)
        n = _unsafe_unescape!(s)
        t = Expr(:tuple, codeunits(s[1:n])..., 0x00)
        :(StaticString($t))
    end

    # Fundamentals
    @inline Base.unsafe_convert(::Type{Ptr{T}}, m::StaticString) where {T} = Ptr{T}(pointer_from_objref(m))
    @inline Base.pointer(m::StaticString{N}) where {N} = Ptr{UInt8}(pointer_from_objref(m))
    @inline Base.length(s::StaticString{N}) where N = N-1
    @inline Base.:(==)(::StaticString, ::StaticString) = false
    @inline function Base.:(==)(a::StaticString{N}, b::StaticString{N}) where N
        GC.@preserve a b begin
            pa, pb = pointer(a), pointer(b)
            for n ∈ 0:N-1
                unsafe_load(pa + n) == unsafe_load(pb + n) || return false
            end
            return true
        end
    end

    # Custom printing
    @inline Base.print(s::StaticString) = printf(s)
    @inline Base.println(s::StaticString) = puts(s)
    @inline Base.print(fp::Ptr{FILE}, s::StaticString) = printf(fp, s)
    @inline Base.println(fp::Ptr{FILE}, s::StaticString) = puts(fp, s)

    # Custom replshow for interactive use (n.b. _NOT_ static-compilerable)
    function Base.show(io::IO, s::StaticString)
        Base.print(io, "c\"")
        Base.escape_string(io, Base.unsafe_string(pointer(s)))
        Base.print(io, "\"")
    end

    # Implement some of the AbstractArray interface:
    @inline Base.firstindex(s::StaticString) = 1
    @inline Base.lastindex(s::StaticString{N}) where {N} = N
    @inline Base.eachindex(s::StaticString{N}) where {N} = 1:N
    @inline Base.getindex(s::StaticString, i::Int) = unsafe_load(pointer(s)+(i-1))
    @inline Base.getindex(s::StaticString, r::AbstractArray{Int}) = StaticString(codeunits(s)[r]) # Should probably null-terminate
    @inline Base.getindex(s::StaticString, ::Colon) = s
    @inline Base.setindex!(s::StaticString, x::UInt8, i::Int) = unsafe_store!(pointer(s)+(i-1), x)
    @inline Base.setindex!(s::StaticString, x, i::Int) = unsafe_store!(pointer(s)+(i-1), convert(UInt8, x))
    @inline function Base.setindex!(s::StaticString, x, r::UnitRange{Int})
        is₀ = first(r)-1
        ix₀ = firstindex(x)-1
        @inbounds for i = 1:length(r)
            setindex!(s, x[i+ix₀], i+is₀)
        end
    end
    @inline function Base.setindex!(s::StaticString, x, ::Colon)
        ix₀ = firstindex(x)-firstindex(s)
        @inbounds for i ∈ eachindex(s)
            setindex!(s, x[i+ix₀], i)
        end
    end
    @inline Base.copy(s::StaticString) = StaticString(codeunits(s))


    # Implement some of the AbstractString interface
    @inline Base.ncodeunits(s::StaticString{N}) where N = N
    @inline Base.codeunits(s::StaticString) = s.data
    @inline Base.codeunit(s::StaticString) = UInt8
    @inline Base.codeunit(s::StaticString, i::Integer) = s[i]
    @inline function Base.:*(a::StaticString, b::StaticString)  # Concatenation
        N = length(a) + length(b) + 1
        c = StaticString{N}(undef)
        c[1:length(a)] = a
        c[length(a)+1:length(a)+length(b)] = b
        c[end] = 0x00 # Null-terminate
        return c
    end
    @inline function Base.:^(s::StaticString, n::Integer)       # Repetition
        l = length(s) # Excluding the null-termination, remember
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
