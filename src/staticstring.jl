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

    Can be constructed with the `c"..."` string macro.

    Unlike base Julia `String`s, slicing does not create a copy, but rather a view.
    You are responsible for ensuring that any such views are null-terminated if you
    wish to pass them to any functions (including most system IO) that expect
    null-termination.

    ---

    ```julia
    StaticString(data::NTuple{N,UInt8})
    ```
    Construct a `StaticString` containing the `N` bytes specified by `data`.
    To yield a valid string, `data` must be null-terminated, i.e., end in `0x00`.

    ## Examples
    ```julia
    julia> data = (0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x21, 0x00);

    julia> s = StaticString(data)
    c"Hello world!"

    julia> s[8:12] = c"there"; s
    c"Hello there!"
    ```
    """
    mutable struct StaticString{N} <: AbstractStaticString
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

    # Fundamentals -- where differing from AbstractStaticString:
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

    # Custom replshow for interactive use (n.b. _NOT_ static-compilerable)
    function Base.show(io::IO, s::StaticString)
        Base.print(io, "c\"")
        Base.escape_string(io, Base.unsafe_string(pointer(s)))
        Base.print(io, "\"")
    end

    # Implement some of the AbstractArray interface -- where differing from AbstractStaticString:
    @inline Base.firstindex(s::StaticString) = 1
    @inline Base.lastindex(s::StaticString{N}) where {N} = N
    @inline Base.eachindex(s::StaticString{N}) where {N} = 1:N
    @inline Base.getindex(s::StaticString, i::Int) = unsafe_load(pointer(s)+(i-1))
    @inline Base.copy(s::StaticString) = StaticString(codeunits(s))


    # Implement some of the AbstractString interface -- where differing from AbstractStaticString:
    @inline Base.ncodeunits(s::StaticString{N}) where N = N
    @inline Base.codeunits(s::StaticString) = s.data
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
