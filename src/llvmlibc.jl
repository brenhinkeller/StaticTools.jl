"""
```julia
malloc(size::Integer)
```
Libc `malloc` function, accessed by direct StaticCompiler-safe `llvmcall`.

Allocate `size` bytes of memory and return a pointer to that memory.

See also: `calloc`, `free`.

## Examples
```julia
julia> p = malloc(500)
Ptr{UInt8} @0x00007ff0e9e74290

julia> free(p)
0
```
"""
@inline malloc(size::Integer) = malloc(size % Int)
@inline malloc(size::Int) = @symbolcall malloc(size::Int)::Ptr{UInt8}
@inline malloc(size::Unsigned) = malloc(size % UInt)
@inline malloc(size::UInt) = @symbolcall malloc(size::UInt)::Ptr{UInt8}

"""
```julia
calloc([n], size::Integer)
```
Libc `calloc` function, accessed by direct StaticCompiler-safe `llvmcall`.

Allocate `size` bytes of zero-initialized memory and return a pointer to that memory.
As `malloc`, but initializes the memory to all zero.

See also: `malloc`, `free`.

## Examples
```julia
julia> p = calloc(100*sizeof(Int64))
Ptr{UInt8} @0x00007fb74ff04360

julia> MallocArray{Int64}(p, 10, 10)
10×10 MallocMatrix{Int64}:
 0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0

julia> free(p)
0
```
"""
@inline calloc(nbytes::Integer) = calloc(nbytes % Int)
@inline calloc(nbytes::Int) = calloc(1, nbytes)
@inline calloc(n::Int, size::Int) = @symbolcall calloc(n::Int, size::Int)::Ptr{UInt8}

"""
```julia
free(ptr::Ptr)
```
Libc `free` function, accessed by direct StaticCompiler-safe `llvmcall`.

Free memory that has been previously allocated with `malloc`.

See also: `calloc`, `malloc`.

## Examples
```julia
julia> p = malloc(500)
Ptr{UInt8} @0x00007ff0e9e74290

julia> free(p)
0
```
"""
@inline free(ptr::Ptr) = free(Ptr{UInt8}(ptr))
@inline function free(ptr::Ptr{UInt8})
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the `free` function
    declare void @free(i8*)

    ; Function Attrs: nounwind ssp uwtable
    define i32 @main(i64 %jlp) #0 {
      %ptr = inttoptr i64 %jlp to i8*
      call void (i8*) @free(i8* %ptr)
      ret i32 0
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Int32, Tuple{Ptr{UInt8}}, ptr)
end


"""
```julia
memset!(a, char::Integer, nbytes::Integer=sizeof(a))
```
Libc `memset` function, accessed by direct StaticCompiler-safe `llvmcall`.

Set `nbytes` bytes of the array or memory region `a` to the `Char`/`UInt8`
conversion of the integer `char`.

## Examples
```julia
julia> a = rand(5,5)
5×5 Matrix{Float64}:
 0.252808   0.6125    0.947215   0.0966341  0.637651
 0.736149   0.527729  0.928291   0.725644   0.832734
 0.704827   0.990302  0.0380948  0.768337   0.891583
 0.0826808  0.833624  0.364925   0.230345   0.366826
 0.301975   0.113886  0.329196   0.772636   0.0156762

julia> memset!(a, 0)
0

julia> a
5×5 Matrix{Float64}:
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
```
"""
@inline memset!(a, char, nbytes=sizeof(a)) = GC.@preserve a memset!(pointer(a), char, nbytes)
@inline memset!(a::AbstractMallocdMemory, char, nbytes=sizeof(a)) = memset!(pointer(a), char, nbytes)
@inline memset!(ptr::Ptr, char::Integer, nbytes::Integer) = memset!(Ptr{UInt8}(ptr), char, nbytes)
@inline memset!(ptr::Ptr{UInt8}, char::Integer, nbytes::Integer) = memset!(ptr, Int(char), Int(nbytes))
@inline function memset!(ptr::Ptr{UInt8}, char::Int, nbytes::Int)
    @static if Int===Int64
        Base.llvmcall(("""
        ; External declaration of the `memset` function
        ; Function Attrs: argmemonly nounwind
        declare void @memset(i8* nocapture writeonly, i64, i64) #0

        ; Function Attrs: nounwind ssp uwtable
        define i32 @main(i64 %jlp, i64 %value, i64 %n) #1 {
          %ptr = inttoptr i64 %jlp to i8*
          call void @memset(i8* %ptr, i64 %value, i64 %n)
          ret i32 0
        }

        attributes #0 = { argmemonly nounwind }
        attributes #1 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{UInt8}, Int64, Int64}, ptr, char, nbytes)
    else
        Base.llvmcall(("""
        ; External declaration of the `memset` function
        ; Function Attrs: argmemonly nounwind
        declare void @memset(i8* nocapture writeonly, i32, i32) #0

        ; Function Attrs: nounwind ssp uwtable
        define i32 @main(i64 %jlp, i32 %value, i32 %n) #1 {
          %ptr = inttoptr i64 %jlp to i8*
          call void @memset(i8* %ptr, i32 %value, i32 %n)
          ret i32 0
        }

        attributes #0 = { argmemonly nounwind }
        attributes #1 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{UInt8}, Int32, Int32}, ptr, char, nbytes)
    end
end


"""
```julia
memcpy!(a, b, n=length(b))
```
Libc `memcpy` function, accessed by direct StaticCompiler-safe `llvmcall`.

Copy `n` elements from array `b` to array `a`.

## Examples
```julia
julia> a = rand(3)
3-element Vector{Float64}:
 0.8559883493421137
 0.4203692766310769
 0.5728354965961716

julia> memcpy!(a, ones(3))
0

julia> a
3-element Vector{Float64}:
 1.0
 1.0
 1.0
```
"""
@inline memcpy!(a, b) = memcpy!(a, b, length(b))
@inline memcpy!(a, b, n::Int64) = GC.@preserve a b memcpy!(pointer(a), pointer(b), n)
@inline memcpy!(dst::Ptr, src::Ptr{T}, n::Int64) where {T} = memcpy!(Ptr{UInt8}(dst), Ptr{UInt8}(src), n*sizeof(T))
@inline function memcpy!(dst::Ptr{UInt8}, src::Ptr{UInt8}, nbytes::Int64)
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the `memcpy` function
    ; Function Attrs: argmemonly nounwind
    declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture writeonly, i8* nocapture readonly, i64, i1) #0

    ; Function Attrs: nounwind ssp uwtable
    define i32 @main(i64 %jldest, i64 %jlsrc, i64 %nbytes) #1 {
      %dest = inttoptr i64 %jldest to i8*
      %src = inttoptr i64 %jlsrc to i8*
      call void @llvm.memcpy.p0i8.p0i8.i64(i8* %dest, i8* %src, i64 %nbytes, i1 false)
      ret i32 0
    }

    attributes #0 = { argmemonly nounwind }
    attributes #1 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Int32, Tuple{Ptr{UInt8}, Ptr{UInt8}, Int64}, dst, src, nbytes)
end

"""
```julia
memcmp(a, b, n::Int64)
```
Libc `memcmp` function, accessed by direct StaticCompiler-safe `llvmcall`.

Compare the first `n` bytes of `a` and `b`, returning
* a positive value if the first `n` bytes of `a` are greater than the first `n` bytes of `b`
* a negative value if the first `n` bytes of `a` are less than the first `n` bytes of `b`
* `0` the first `n` bytes of `a` are equal to the first `n` bytes of `b`

## Examples
```julia
julia> memcmp(c"foo", c"foo", 3)
0

julia> memcmp(c"foo", c"bar", 3)
4
```
"""
@inline memcmp(a, b, n::Int64) = GC.@preserve a b memcmp(pointer(a), pointer(b), n)
@inline memcmp(a::Ptr, b::Ptr, n::Int64) = memcpy!(Ptr{UInt8}(a), Ptr{UInt8}(b), n)
@inline function memcmp(a::Ptr{UInt8}, b::Ptr{UInt8}, nbytes::Int64)
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the `memcmp` function
    declare i32 @memcmp(i8*, i8*, i64)

    ; Function Attrs: nounwind ssp uwtable
    define i32 @main(i64 %jla, i64 %jlb, i64 %nbytes) #0 {
      %a = inttoptr i64 %jla to i8*
      %b = inttoptr i64 %jlb to i8*
      %cmp = call i32 @memcmp(i8* %a, i8* %b, i64 %nbytes)
      ret i32 %cmp
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Int32, Tuple{Ptr{UInt8}, Ptr{UInt8}, Int64}, a, b, nbytes)
end


"""
```julia
time()
```
Libc `time` function, accessed by direct StaticCompiler-safe `llvmcall`.

Return, as an `Int64`, the current time in seconds since the beginning of the
current Unix epoch on 00:00:00 UTC, January 1, 1970.

## Examples
```julia
julia> StaticTools.time()
1651105298
```
"""
@inline function time()
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the `time` function
    declare i64 @time(i64*)

    ; Function Attrs: nounwind ssp uwtable
    define i64 @main() {
      %time = call i64 @time(i64* null)
      ret i64 %time
    }
    """, "main"), Int64, Tuple{}, size)
end


"""
```julia
usleep(μsec::Integer)
```
Libc `usleep` function, accessed by direct StaticCompiler-safe `llvmcall`.

Suspend execution of the calling thread for (at least) μsec microseconds.

## Examples
```julia
julia> usleep(1000000)
0
```
"""
@inline usleep(μsec::Integer) = malloc(Int64(μsec))
@inline function usleep(μsec::Int64)
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the `usleep` function
    declare i32 @usleep(i64)

    ; Function Attrs: nounwind ssp uwtable
    define i32 @main(i64 %usec) #0 {
      %status = call i32 (i64) @usleep(i64 %usec)
      ret i32 %status
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Int32, Tuple{Int64}, μsec)
end


"""
```julia
system(s)
```
Libc `system` function, accessed by direct StaticCompiler-safe `llvmcall`.

Pass the null-terminated string (or pointer thereto) `s` to the libc `system`
function for evaluation.

Returns `0` on success.

## Examples
```julia
julia> StaticTools.system(c"time echo hello")
hello

real    0m0.001s
user    0m0.000s
sys 0m0.000s
0
```
"""
@inline system(s::AbstractMallocdMemory) = system(pointer(s))
@inline system(s) = GC.@preserve s system(pointer(s))
@inline function system(s::Ptr{UInt8})
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the `system` function
    declare i32 @system(...)

    ; Function Attrs: nounwind ssp uwtable
    define i32 @main(i64 %jlstr) #0 {
      %str = inttoptr i64 %jlstr to i8*
      %status = call i32 (i8*, ...) bitcast (i32 (...)* @system to i32 (i8*, ...)*)(i8* %str)
      ret i32 %status
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Int32, Tuple{Ptr{UInt8}}, s)
end

"""
```julia
strlen(s)
```
Libc `strlen` function, accessed by direct StaticCompiler-safe `llvmcall`.

Returns the length in bytes of the null-terminated string `s`, not counting the
terminating null character.

## Examples
```julia
julia> strlen("foo") # Not documented, but Julia strings are null-terminated in practice every time I've checked
3

julia> strlen(c"foo")
3
```
"""
@inline strlen(s::AbstractMallocdMemory) = strlen(pointer(s))
@inline strlen(s) = GC.@preserve s strlen(pointer(s))
@inline function strlen(s::Ptr{UInt8})
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the `strlen` function
    declare i64 @strlen(i8*)

    ; Function Attrs: nounwind ssp uwtable
    define i64 @main(i64 %jlstr) #0 {
      %str = inttoptr i64 %jlstr to i8*
      %li = call i64 (i8*) @strlen (i8* %str)
      ret i64 %li
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Int64, Tuple{Ptr{UInt8}}, s)
end


"""
```julia
strtod(s)
```
Libc `strtod` function, accessed by direct StaticCompiler-safe `llvmcall`.

Returns a `Float64` ("double") containing the number written out in decimal form
in null-terminated string `s`.

## Examples
```julia
julia> num, pbuf = StaticTools.strtod(c"3.1415")
(3.1415, ManualMemory.MemoryBuffer{1, Ptr{UInt8}}((Ptr{UInt8} @0x000000010aeee946,)))

julia> num, pbuf = StaticTools.strtod(c"5")
(5.0, ManualMemory.MemoryBuffer{1, Ptr{UInt8}}((Ptr{UInt8} @0x000000010d8f2bb1,)))
```
"""
@inline strtod(s::AbstractMallocdMemory) = strtod(pointer(s))
@inline strtod(s) = GC.@preserve s strtod(pointer(s))
@inline function strtod(p::Ptr{UInt8})
    pbuf = MemoryBuffer{1,Ptr{UInt8}}(undef)
    num = GC.@preserve pbuf strtod(p, pointer(pbuf))
    return num, pbuf
end
@inline function strtod(s::Ptr{UInt8}, p::Ptr{Ptr{UInt8}})
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the `strtod` function
    declare double @strtod(i8*, i8**)

    ; Function Attrs: nounwind ssp uwtable
    define double @main(i64 %jlstr, i64 %jlp) #0 {
      %str = inttoptr i64 %jlstr to i8*
      %ptr = inttoptr i64 %jlp to i8**
      %d = call double (i8*, i8**) @strtod (i8* %str, i8** %ptr)
      ret double %d
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Float64, Tuple{Ptr{UInt8}, Ptr{Ptr{UInt8}}}, s, p)
end

"""
```julia
strtol(s)
```
Libc `strtol` function, accessed by direct StaticCompiler-safe `llvmcall`.

Returns an `Int64` ("long") containing the number written out in decimal form in
null-terminated string `s`.

## Examples
```julia
julia> num, pbuf = StaticTools.strtol(c"3.1415")
(3, ManualMemory.MemoryBuffer{1, Ptr{UInt8}}((Ptr{UInt8} @0x000000010dd827f1,)))

julia> num, pbuf = StaticTools.strtol(c"5")
(5, ManualMemory.MemoryBuffer{1, Ptr{UInt8}}((Ptr{UInt8} @0x000000015dbdda41,)))
```
"""
@inline strtol(s::AbstractMallocdMemory) = strtol(pointer(s))
@inline strtol(s) = GC.@preserve s strtol(pointer(s))
@inline function strtol(p::Ptr{UInt8}, base::Int32=Int32(10))
    pbuf = MemoryBuffer{1,Ptr{UInt8}}(undef)
    num = GC.@preserve pbuf strtol(p, pointer(pbuf), base)
    return num, pbuf
end
@inline function strtol(s::Ptr{UInt8}, p::Ptr{Ptr{UInt8}}, base::Int32)
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the `strtol` function
    declare i64 @strtol(i8*, i8**, i32)

    ; Function Attrs: nounwind ssp uwtable
    define i64 @main(i64 %jlstr, i64 %jlp, i32 %base) #0 {
      %str = inttoptr i64 %jlstr to i8*
      %ptr = inttoptr i64 %jlp to i8**
      %li = call i64 (i8*, i8**, i32) @strtol (i8* %str, i8** %ptr, i32 %base)
      ret i64 %li
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Int64, Tuple{Ptr{UInt8}, Ptr{Ptr{UInt8}}, Int32}, s, p, base)
end

"""
```julia
strtoul(s)
```
Libc `strtol` function, accessed by direct StaticCompiler-safe `llvmcall`.

Returns an `UInt64` ("unsigned long") containing the number written out in decimal
form in null-terminated string `s`.

## Examples
```julia
julia> num, pbuf = StaticTools.strtoul(c"3.1415")
(0x0000000000000003, ManualMemory.MemoryBuffer{1, Ptr{UInt8}}((Ptr{UInt8} @0x000000010d6976a1,)))

julia> num, pbuf = StaticTools.strtoul(c"5")
(0x0000000000000005, ManualMemory.MemoryBuffer{1, Ptr{UInt8}}((Ptr{UInt8} @0x000000015ed45d11,)))
```
"""
@inline strtoul(s::AbstractMallocdMemory) = strtoul(pointer(s))
@inline strtoul(s) = GC.@preserve s strtoul(pointer(s))
@inline function strtoul(p::Ptr{UInt8}, base::Int32=Int32(10))
    pbuf = MemoryBuffer{1,Ptr{UInt8}}(undef)
    num = GC.@preserve pbuf strtoul(p, pointer(pbuf), base)
    return num, pbuf
end
@inline function strtoul(s::Ptr{UInt8}, p::Ptr{Ptr{UInt8}}, base::Int32)
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the `strtoul` function
    declare i64 @strtoul(i8*, i8**, i32)

    ; Function Attrs: nounwind ssp uwtable
    define i64 @main(i64 %jlstr, i64 %jlp, i32 %base) #0 {
      %str = inttoptr i64 %jlstr to i8*
      %ptr = inttoptr i64 %jlp to i8**
      %li = call i64 (i8*, i8**, i32) @strtoul (i8* %str, i8** %ptr, i32 %base)
      ret i64 %li
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), UInt64, Tuple{Ptr{UInt8}, Ptr{Ptr{UInt8}}, Int32}, s, p, base)
end

## --- Parse

"""
```julia
parse(::Type{T}, s::Union{StaticString, MallocString})
```
Parse a number from a `StaticString` or `MallocString` `s`.

## Examples
```julia
julia> parse(Float64, c"3.141592")
3.141592

julia> parse(Int64, c"3.141592")
3
```
"""
@inline function Base.parse(::Type{Float64}, s::AbstractStaticString)
    num, pbuf = strtod(s)
    load(pointer(pbuf)) == pointer(s) && return NaN
    return num
end
@inline Base.parse(::Type{T}, s::AbstractStaticString) where {T <: AbstractFloat} = T(parse(Float64, s))

@inline function Base.parse(::Type{Int64}, s::AbstractStaticString)
    num, pbuf = strtol(s)
    return num
end
@inline Base.parse(::Type{T}, s::AbstractStaticString) where {T <: Integer} = T(parse(Int64, s))

@inline function Base.parse(::Type{UInt64}, s::AbstractStaticString)
    num, pbuf = strtoul(s)
    return num
end
@inline Base.parse(::Type{T}, s::AbstractStaticString) where {T <: Unsigned} = T(parse(UInt64, s))

# Convenient parsing for argv
@inline argparse(::Type{T}, argv::Ptr{Ptr{UInt8}}, n::Integer) where {T} = parse(T, MallocString(argv, n))

## --- dlopen

const RTLD_LOCAL = Int32(1)
const RTLD_GLOBAL = Int32(2)
const RTLD_LAZY = Int32(4)
const RTLD_NOW = Int32(8)

"""
```julia
dlopen(name::AbstractString, flag=RTLD_LOCAL|RTLD_LAZY)
```
Libc `dlopen` function, accessed by direct `llvmcall`.

Returns a handle (pointer) to a `.so`/`.dylib` shared library specified by
`name` opened with the mode or combination of modes specified by `flag`.
Returns `C_NULL` on failure. Valid modes include:

Required:

  `RTLD_LOCAL` (default): Symbols will not be made available for subsequently loaded libraries. The opposite of `RTLD_GLOBAL`.

  `RTLD_GLOBAL`: Symbols will be made available for subsequently loaded libraries. The opposite of `RTLD_LOCAL`.

Optional:

  `RTLD_LAZY` (default): Lazy binding: only resolve symbols as the code that references them is executed. The opposite of `RLTD_NOW`.

  `RTLD_NOW`: Eager binding: resolve all symbols before `dlopen` returns. The opposite of `RTLD_LAZY`

Modes from the two categories can be combined with bitwise `or` (`|`)

See also: `StaticTools.dlsym`, `StaticTools.@ptrcall`, `StaticTools.dlclose`

## Examples
```julia
julia> lib = StaticTools.dlopen(c"libc.dylib") # on macOS
Ptr{StaticTools.DYLIB} @0x000000010bf49b78

julia> fp = StaticTools.dlsym(lib, c"time")
Ptr{Nothing} @0x00007fffa773dfa4

julia> dltime() = @ptrcall fp(C_NULL::Ptr{Nothing})::Int
ctime (generic function with 1 method)

julia> dltime()
1654320146

julia> StaticTools.dlclose(lib)
0
```
"""
@inline function dlopen(name, flag=RTLD_LOCAL|RTLD_LAZY)
    dlext = @static if Sys.isapple()
        c".dylib"
    elseif Sys.iswindows()
        c".dll"
    else
        c".so"
    end
    namext = name*dlext
    if contains(name, dlext)
        GC.@preserve name dlopen(pointer(name), flag)
    else
        GC.@preserve namext dlopen(pointer(namext), flag)
    end
end
@inline dlopen(name::AbstractMallocdMemory, flag=RTLD_LOCAL|RTLD_LAZY) = dlopen(pointer(name), flag)
@inline function dlopen(name::Ptr{UInt8}, flag::Int32)
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the dlopen function
    declare i8* @dlopen(i8*, i32)

    define i64 @main(i64 %jlname, i32 %flag) #0 {
    entry:
      %name = inttoptr i64 %jlname to i8*
      %fp = call i8* (i8*, i32) @dlopen(i8* %name, i32 %flag)
      %jlfp = ptrtoint i8* %fp to i64
      ret i64 %jlfp
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Ptr{DYLIB}, Tuple{Ptr{UInt8}, Int32}, name, flag)
end

# Prevent this from getting converted into a bare pointer by making it a function
@static if Sys.isapple()
    @inline DLEXT() = c".dylib"
elseif Sys.iswindows()
    @inline DLEXT() = c".dll"
else
    @inline DLEXT() = c".so"
end

## --- dylsym

"""
```julia
dlsym(lib::Ptr{DYLIB}, symbol::AbstractString)
```
Libc `dlsym` function, accessed by direct StaticCompiler-safe `llvmcall`.

Takes a handle (`lib`) to a `.so`/`.dylib` shared library previously opened with
`StaticTools.dlopen`, along with a null-terminated symbol name string (`symbol`),
and returns the location in memory of that symbol. Returns `C_NULL` on failure.

Optionally, a constant pseudo-pointer `RTLD_DEFAULT` is  provided which can be
used in place of the library `lib`. This instructs `dlsym` to search for the
next occurrence of the specified `symbol` in the default search path, starting
from the beginning of the search path.

See also: `StaticTools.dlopen`, `StaticTools.@ptrcall`, `StaticTools.dlclose`

## Examples
```julia
julia> lib = StaticTools.dlopen(c"libc.dylib") # on macOS
Ptr{StaticTools.DYLIB} @0x000000010bf49b78

julia> fp = StaticTools.dlsym(lib, c"time")
Ptr{Nothing} @0x00007fffa773dfa4

julia> dltime() = @ptrcall fp(C_NULL::Ptr{Nothing})::Int
dltime (generic function with 1 method)

julia> dltime()
1654320146

julia> StaticTools.dlclose(lib)
0
```
"""
@inline dlsym(handle::Ptr{DYLIB}, symbol::AbstractMallocdMemory) = dlsym(handle, pointer(symbol))
@inline dlsym(handle::Ptr{DYLIB}, symbol) = GC.@preserve symbol dlsym(handle, pointer(symbol))
@inline function dlsym(handle::Ptr{DYLIB}, symbol::Ptr{UInt8})
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the dlsym function
    declare i8* @dlsym(i8*, i8*)

    define i64 @main(i64 %jlh, i64 %jls) #0 {
    entry:
      %handle = inttoptr i64 %jlh to i8*
      %symbol = inttoptr i64 %jls to i8*
      %fp = call i8* (i8*, i8*) @dlsym(i8* %handle, i8* %symbol)
      %jlfp = ptrtoint i8* %fp to i64
      ret i64 %jlfp
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Ptr{Nothing}, Tuple{Ptr{DYLIB}, Ptr{UInt8}}, handle, symbol)
end

# Return default handle to what Julia has already dlopened, for interactive use
# const RTLD_NEXT = Ptr{DYLIB}(-1 % UInt)
@static if Sys.isapple()
    const RTLD_DEFAULT = Ptr{DYLIB}(-2 % UInt)
else
    const RTLD_DEFAULT = Ptr{DYLIB}(0)
end



## --- dlclose

"""
```julia
dlclose(lib::Ptr{DYLIB})
```
Libc `dlclose` function, accessed by direct StaticCompiler-safe `llvmcall`.

Close a shared library `lib` given a pointer (handle) previously obtained from
`StaticTools.dlopen`.

See also: `StaticTools.dlopen`, `StaticTools.dlsym`, `StaticTools.@ptrcall`

## Examples
```julia
julia> lib = StaticTools.dlopen(c"libc.dylib") # on macOS
Ptr{StaticTools.DYLIB} @0x000000010bf49b78

julia> fp = StaticTools.dlsym(lib, c"time")
Ptr{Nothing} @0x00007fffa773dfa4

julia> dltime() = @ptrcall fp(C_NULL::Ptr{Nothing})::Int
dltime (generic function with 1 method)

julia> dltime()
1654320146

julia> StaticTools.dlclose(lib)
0
```
"""
@inline function dlclose(handle::Ptr{DYLIB})
    @assert Int===Int64
    Base.llvmcall(("""
    ; External declaration of the dlclose function
    declare i32 @dlclose(i8*)

    define i32 @main(i64 %jlh) #0 {
    entry:
      %handle = inttoptr i64 %jlh to i8*
      %status = call i32 (i8*) @dlclose(i8* %handle)
      ret i32 %status
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Int32, Tuple{Ptr{DYLIB}}, handle)
end

## ---
