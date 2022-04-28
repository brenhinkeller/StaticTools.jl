"""
```julia
malloc(size::Integer)
```
Libc `malloc` function, accessed by direct StaticCompiler-safe `llvmcall`.

Allocate `size` bytes of memory and return a pointer to that memory.

See also: `free`.

## Examples
```julia
julia> p = malloc(500)
Ptr{UInt8} @0x00007ff0e9e74290

julia> free(p)
0
```
"""
@inline malloc(size::Integer) = malloc(Int64(size))
@inline function malloc(size::Int64)
    Base.llvmcall(("""
    ; External declaration of the `malloc` function
    declare i8* @malloc(i64)

    ; Function Attrs: noinline nounwind optnone ssp uwtable
    define dso_local i8* @main(i64 %size) #0 {
      %ptr = call i8* (i64) @malloc(i64 %size)
      ret i8* %ptr
    }

    attributes #0 = { noinline nounwind optnone ssp uwtable }
    """, "main"), Ptr{UInt8}, Tuple{Int64}, size)
end
@inline malloc(size::Unsigned) = malloc(UInt64(size))
@inline function malloc(size::UInt64)
    Base.llvmcall(("""
    ; External declaration of the `malloc` function
    declare i8* @malloc(i64)

    ; Function Attrs: noinline nounwind optnone ssp uwtable
    define dso_local i8* @main(i64 %size) #0 {
      %ptr = call i8* (i64) @malloc(i64 %size)
      ret i8* %ptr
    }

    attributes #0 = { noinline nounwind optnone ssp uwtable }
    """, "main"), Ptr{UInt8}, Tuple{UInt64}, size)
end

"""
```julia
free(ptr::Ptr)
```
Libc `free` function, accessed by direct StaticCompiler-safe `llvmcall`.

Free memory that has been previously allocated with `malloc`.

See also: `free`.

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
    Base.llvmcall(("""
    ; External declaration of the `free` function
    declare void @free(i8*)

    ; Function Attrs: noinline nounwind optnone ssp uwtable
    define dso_local i32 @main(i8* %ptr) #0 {
      call void (i8*) @free(i8* %ptr)
      ret i32 0
    }

    attributes #0 = { noinline nounwind optnone ssp uwtable }
    """, "main"), Int32, Tuple{Ptr{UInt8}}, ptr)
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

julia> StaticTools.memcpy!(a, ones(3))
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
    Base.llvmcall(("""
    ; External declaration of the `memcpy` function
    ; Function Attrs: argmemonly nounwind
    declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture writeonly, i8* nocapture readonly, i64, i1) #0

    ; Function Attrs: noinline nounwind ssp uwtable
    define dso_local i32 @main(i8* %dest, i8* %src, i64 %nbytes) #1 {
      call void @llvm.memcpy.p0i8.p0i8.i64(i8* %dest, i8* %src, i64 %nbytes, i1 false)
      ret i32 0
    }

    attributes #0 = { argmemonly nounwind }
    attributes #1 = { noinline nounwind ssp uwtable }
    """, "main"), Int32, Tuple{Ptr{UInt8}, Ptr{UInt8}, Int64}, dst, src, nbytes)
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
    Base.llvmcall(("""
    ; External declaration of the `time` function
    declare i64 @time(i64*)

    ; Function Attrs: noinline nounwind optnone ssp uwtable
    define dso_local i64 @main() {
      %time = call i64 @time(i64* null)
      ret i64 %time
    }
    """, "main"), Int64, Tuple{}, size)
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
    Base.llvmcall(("""
    ; External declaration of the `system` function
    declare i32 @system(...)

    ; Function Attrs: noinline nounwind optnone ssp uwtable
    define dso_local i32 @main(i8* %str) #0 {
      %1 = call i32 (i8*, ...) bitcast (i32 (...)* @system to i32 (i8*, ...)*)(i8* %str)
      ret i32 0
    }

    attributes #0 = { noinline nounwind optnone ssp uwtable }
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
    Base.llvmcall(("""
    ; External declaration of the `strlen` function
    declare i64 @strlen(i8*)

    ; Function Attrs: noinline nounwind optnone ssp uwtable
    define dso_local i64 @main(i8* %str) #0 {
      %li = call i64 (i8*) @strlen (i8* %str)
      ret i64 %li
    }

    attributes #0 = { noinline nounwind optnone ssp uwtable }
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
    Base.llvmcall(("""
    ; External declaration of the `strtod` function
    declare double @strtod(i8*, i8**)

    ; Function Attrs: noinline nounwind optnone ssp uwtable
    define dso_local double @main(i8* %str, i8** %ptr) #0 {
      %d = call double (i8*, i8**) @strtod (i8* %str, i8** %ptr)
      ret double %d
    }

    attributes #0 = { noinline nounwind optnone ssp uwtable }
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
    Base.llvmcall(("""
    ; External declaration of the `strtol` function
    declare i64 @strtol(i8*, i8**, i32)

    ; Function Attrs: noinline nounwind optnone ssp uwtable
    define dso_local i64 @main(i8* %str, i8** %ptr, i32 %base) #0 {
      %li = call i64 (i8*, i8**, i32) @strtol (i8* %str, i8** %ptr, i32 %base)
      ret i64 %li
    }

    attributes #0 = { noinline nounwind optnone ssp uwtable }
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
    Base.llvmcall(("""
    ; External declaration of the `strtoul` function
    declare i64 @strtoul(i8*, i8**, i32)

    ; Function Attrs: noinline nounwind optnone ssp uwtable
    define dso_local i64 @main(i8* %str, i8** %ptr, i32 %base) #0 {
      %li = call i64 (i8*, i8**, i32) @strtoul (i8* %str, i8** %ptr, i32 %base)
      ret i64 %li
    }

    attributes #0 = { noinline nounwind optnone ssp uwtable }
    """, "main"), UInt64, Tuple{Ptr{UInt8}, Ptr{Ptr{UInt8}}, Int32}, s, p, base)
end


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
@inline function Base.parse(::Type{Float64}, s::Union{StaticString, MallocString})
    num, pbuf = strtod(s)
    load(pointer(pbuf)) == pointer(s) && return NaN
    return num
end
@inline function Base.parse(::Type{Float64}, s::Ptr{UInt8})
    num, pbuf = strtod(s)
    load(pointer(pbuf)) == s && return NaN
    return num
end
@inline Base.parse(::Type{T}, s::Union{StaticString, MallocString, Ptr{UInt8}}) where {T <: AbstractFloat} = T(parse(Float64, s))

@inline function Base.parse(::Type{Int64}, s::Union{StaticString, MallocString, Ptr{UInt8}})
    num, pbuf = strtol(s)
    return num
end
@inline Base.parse(::Type{T}, s::Union{StaticString, MallocString, Ptr{UInt8}}) where {T <: Integer} = T(parse(Int64, s))

@inline function Base.parse(::Type{UInt64}, s::Union{StaticString, MallocString, Ptr{UInt8}})
    num, pbuf = strtoul(s)
    return num
end
@inline Base.parse(::Type{T}, s::Union{StaticString, MallocString, Ptr{UInt8}}) where {T <: Unsigned} = T(parse(UInt64, s))

# Convenient parsing for argv (slight type piracy)
@inline Base.parse(::Type{T}, argv::Ptr{Ptr{UInt8}}, n::Integer) where {T} = parse(T, MallocString(argv, n))
