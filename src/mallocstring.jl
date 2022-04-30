## ---  Define a StatiCompiler- and LLVM-compatible dynamically-sized string type

    # Define the MallocString type, backed by a malloc'd heap of memory

    # Definition and constructors:
    """
    ```julia
    struct MallocString
        pointer::Ptr{UInt8}
        length::Int
    end
    ```
    A stringy object that contains `length` bytes (i.e., `UInt8`s), including
    the final null-termination (`0x00`), at a location in memory specified by
    `pointer`.

    A `MallocString` should generally behave like a base Julia `String`, but is
    explicitly null-terminated, mutable, standalone-StaticCompiler-safe (does not
    require libjulia) and backed by `malloc`ed memory which is not tracked by
    the GC and should be `free`d when no longer in use.

    Can be constructed with the `m"..."` string macro.
    """
    struct MallocString
        pointer::Ptr{UInt8}
        length::Int
    end

    """
    ```julia
    MallocString(undef, N)
    ```
    Construct an uninitialized `N`-byte (including null-termination!) `MallocString`.
    Here `undef` is the `UndefInitializer`.

    ## Examples
    ```julia
    julia> s = MallocString(undef, 10)
    m""

    julia> free(s)
    0
    ```
    """
    @inline function MallocString(::UndefInitializer, N::Int)
        MallocString(Ptr{UInt8}(malloc(N)), N)
    end
    """
    ```julia
    MallocString(data::NTuple{N, UInt8})
    ```
    Construct a `MallocString` containing the `N` bytes specified by `data`.

    ## Examples
    ```julia
    julia> data = (0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x21, 0x00);

    julia> s = MallocString(data)
    m"Hello world!"

    julia> s[8:12] = c"there"; s
    m"Hello there!"

    julia> free(s)
    0
    ```
    """
    @inline function MallocString(data::NTuple{N, UInt8}) where N
        s = MallocString(Ptr{UInt8}(malloc(N)), N)
        s[:] = data
        return s
    end
    @inline MallocString(p::Ptr{UInt8}) = MallocString(p, strlen(p)+1)
    @inline MallocString(argv::Ptr{Ptr{UInt8}}, n::Integer) = MallocString(unsafe_load(argv, n))

    # String macro to create null-terminated `MallocStrings`s
    """
    ```julia
    @m_str -> MallocString
    ```
    Construct a `MallocString`, such as `m"Foo"`.

    A `MallocString` should generally behave like a base Julia `String`, but is
    explicitly null-terminated, mutable, standalone-StaticCompiler-safe (does not
    require libjulia) and is backed by `malloc`d memory which is not tracked by
    the GC and should be `free`d when no longer in use.

    ## Examples
    ```julia
    julia> s = m"Hello there!"
    m"Hello there!"

    julia> s == "Hello there!"
    true

    julia> free(s)
    0
    ```
    """
    macro m_str(s)
        n = _unsafe_unescape!(s)
        t = Expr(:tuple, codeunits(s[1:n])..., 0x00)
        :(MallocString($t))
    end

    # Destructor:
    @inline free(s::MallocString) = free(s.pointer)


    # Fundamentals
    @inline Base.unsafe_convert(::Type{Ptr{T}}, m::MallocString) where {T} = Ptr{T}(s.pointer)
    @inline Base.pointer(s::MallocString) = s.pointer
    @inline Base.length(s::MallocString) = s.length - 1     # For consistency with base
    @inline Base.sizeof(s::MallocString) = s.length         # Thou shalt not lie
    const NullTerminatedString = Union{StaticString, MallocString}
    @inline function Base.:(==)(a::NullTerminatedString, b::NullTerminatedString)
        (N = length(a)) == length(b) || return false
        pa, pb = pointer(a), pointer(b)
        for n ∈ 0:N
            unsafe_load(pa + n) == unsafe_load(pb + n) || return false
        end
        return true
    end
    @inline function Base.:(==)(a::NullTerminatedString, b::AbstractString)
        GC.@preserve a b begin
            (N = length(a)) == sizeof(b) || return false
            pa, pb = pointer(a), pointer(b)
            for n in 0:N-1
                unsafe_load(pa + n) == unsafe_load(pb + n) || return false
            end
            return true
        end
    end
    @inline function Base.:(==)(a::AbstractString, b::NullTerminatedString)
        GC.@preserve a b begin
            (N = sizeof(a)) == length(b) || return false
            pa, pb = pointer(a), pointer(b)
            for n in 0:N-1
                unsafe_load(pa + n) == unsafe_load(pb + n) || return false
            end
            return true
        end
    end


    # Custom printing
    @inline Base.print(s::MallocString) = printf(s)
    @inline Base.println(s::MallocString) = puts(s)
    @inline Base.print(fp::Ptr{FILE}, s::MallocString) = printf(fp, s)
    @inline Base.println(fp::Ptr{FILE}, s::MallocString) = puts(fp, s)

    # Custom replshow for interactive use (n.b. _NOT_ static-compilerable)
    function Base.show(io::IO, s::MallocString)
        Base.print(io, "m\"")
        Base.escape_string(io, Base.unsafe_string(pointer(s)))
        Base.print(io, "\"")
    end

    # Some of the AbstractArray interface:
    @inline Base.firstindex(s::MallocString) = 1
    @inline Base.lastindex(s::MallocString) = s.length
    @inline Base.eachindex(s::MallocString) = 1:s.length
    @inline Base.getindex(s::MallocString, i::Int) = unsafe_load(pointer(s)+(i-1))
    @inline Base.setindex!(s::MallocString, x::UInt8, i::Integer) = unsafe_store!(pointer(s)+(i-1), x)
    @inline Base.setindex!(s::MallocString, x, i::Integer) = unsafe_store!(pointer(s)+(i-1), convert(UInt8,x))
    @inline Base.getindex(s::MallocString, r::UnitRange{<:Integer}) = MallocString(pointer(s)+first(r)-1, length(r))
    @inline Base.getindex(s::MallocString, ::Colon) = s
    @inline function Base.setindex!(s::MallocString, x, r::UnitRange{<:Integer})
        is₀ = first(r)-1
        ix₀ = firstindex(x)-1
        for i = 1:length(r)
            s[i+is₀] = x[i+ix₀]
        end
    end
    @inline function Base.setindex!(s::MallocString, x, ::Colon)
        ix₀ = firstindex(x)-firstindex(s)
        for i ∈ eachindex(s)
            s[i] = x[i+ix₀]
        end
    end
    @inline function Base.copy(s::MallocString)
        new_s = MallocString(undef, sizeof(s))
        new_s[:] = s
        return new_s
    end

    # Some of the AbstractString interface
    @inline Base.ncodeunits(s::MallocString) = s.length
    @inline Base.codeunits(s::MallocString) = MallocVector{UInt8}(s.pointer, s.length)
    @inline Base.codeunit(s::MallocString) = UInt8
    @inline Base.codeunit(s::MallocString, i::Integer) = s[i]
    @inline function Base.:*(a::MallocString, b::MallocString)  # Concatenation
        N = length(a) + length(b) + 1
        c = MallocString(undef, N)
        c[1:length(a)] = a
        c[length(a)+1:length(a)+length(b)] = b
        c[end] = 0x00 # Null-terminate
        return c
    end
    @inline function Base.:^(s::MallocString, n::Integer)       # Repetition
        l = length(s) # Excluding the null-termination
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
