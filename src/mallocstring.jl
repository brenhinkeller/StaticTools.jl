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
    A stringy object that contains `length` bytes (i.e., `UInt8`s, including
    the final null-termination `0x00`), at a location in memory specified by
    `pointer`.

    A `MallocString` should generally behave like a base Julia `String`, but is
    explicitly null-terminated, mutable, standalone-StaticCompiler-safe (does not
    require libjulia) and backed by `malloc`ed memory which is not tracked by
    the GC and should be `free`d when no longer in use.

    Can be constructed with the `m"..."` string macro.

    Unlike base Julia `String`s, slicing does not create a copy, but rather a view.
    You are responsible for ensuring that any such views are null-terminated if you
    wish to pass them to any functions (including most libc/system IO) that expect
    null-termination.

    ## Examples
    ```julia
    julia> s = m"Hello world!"
    m"Hello world!"

    julia> s[8:12] = c"there"; s
    m"Hello there!"

    julia> s[1:5]
    StringView: "Hello"

    julia> s[1:5] == "Hello"
    true

    julia> StaticString(s[1:5])
    c"Hello"

    julia> free(s)
    0
    ```
    """
    struct MallocString <: AbstractPointerString
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
        s = MallocString(Ptr{UInt8}(malloc(N)), N)
        s[end] = 0x00
        return s
    end
    """
    ```julia
    MallocString(data::NTuple{N, UInt8})
    ```
    Construct a `MallocString` containing the `N` bytes specified by `data`.
    To yield a valid string, `data` must be null-terminated, i.e., end in `0x00`.

    ```julia
    MallocString(s::AbstractStaticString)
    ```
    Construct a `MallocString` containing the same data as the existing string `s`

    ## Examples
    ```julia
    julia> data = (0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x21, 0x00);

    julia> s = MallocString(data)
    m"Hello world!"

    julia> s2 = MallocString(s[1:5])
    m"Hello"

    julia> free(s)
    0

    julia> free(s2)
    0
    ```
    """
    @inline function MallocString(data::NTuple{N, UInt8}) where N
        s = MallocString(Ptr{UInt8}(malloc(N)), N)
        s[:] = data
        return s
    end
@inline function MallocString(s::AbstractStaticString)
    N = length(s) + 1 # Add room for null-termination
    c = MallocString(Ptr{UInt8}(malloc(N)), N)
    c[1:length(s)] = s
    c[end] = 0x00
    return c
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
        t = Expr(:tuple, codeunits(s)[1:n]..., 0x00)
        :(MallocString($t))
    end

    # Destructor:
    @inline free(s::MallocString) = free(s.pointer)


    # Fundamentals -- where overriding AbstractStaticString defaults
    @inline Base.length(s::MallocString) = s.length - 1     # For consistency with base
    @inline function Base.:(==)(a::Union{StaticString,MallocString}, b::Union{StaticString,MallocString})
        (N = length(a)) == length(b) || return false
        pa, pb = pointer(a), pointer(b)
        for n in 0:N
            unsafe_load(pa + n) == unsafe_load(pb + n) || return false
        end
        return true
    end

    # Custom replshow for interactive use (n.b. _NOT_ static-compilerable)
    function Base.show(io::IO, s::MallocString)
        Base.print(io, "m\"")
        Base.escape_string(io, Base.unsafe_string(pointer(s)))
        Base.print(io, "\"")
    end

    # Some of the AbstractString interface -- where overriding AbstractStaticString defaults
    @inline function Base.:*(a::MallocString, b::AbstractStaticString)  # Concatenation
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
    @inline function Base.copy(s::MallocString)
        new_s = MallocString(undef, sizeof(s))
        new_s[:] = s
        return new_s
    end

    # As Base.unsafe_string, but loading to a MallocString instead
    @inline function unsafe_mallocstring(p::Ptr{UInt8})
        len = strlen(p)+1
        s = MallocString(undef, len)
        for i=1:len
            s[i] = unsafe_load(p, i)
        end
        return s
    end
