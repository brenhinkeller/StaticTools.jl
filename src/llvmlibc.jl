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
@inline system(s::AbstractMallocdMemory) = system(pointer(s))
@inline system(s) = GC.@preserve s system(pointer(s))


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
@inline strlen(s::AbstractMallocdMemory) = strlen(pointer(s))
@inline strlen(s) = GC.@preserve s strlen(pointer(s))

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
@inline function strtod(s::AbstractMallocdMemory)
    pbuf = MemoryBuffer{1,Ptr{UInt8}}(undef)
    num = GC.@preserve pbuf strtod(pointer(s), pointer(pbuf))
    return num, pbuf
end
@inline function strtod(s)
    pbuf = MemoryBuffer{1,Ptr{UInt8}}(undef)
    num = GC.@preserve s pbuf strtod(pointer(s), pointer(pbuf))
    return num, pbuf
end

@inline function strtol(s::Ptr{UInt8}, p::Ptr{Ptr{UInt8}}, base::Int32=Int32(10))
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
@inline function strtol(s::AbstractMallocdMemory)
    pbuf = MemoryBuffer{1,Ptr{UInt8}}(undef)
    num = GC.@preserve pbuf strtol(pointer(s), pointer(pbuf))
    return num, pbuf
end
@inline function strtol(s)
    pbuf = MemoryBuffer{1,Ptr{UInt8}}(undef)
    num = GC.@preserve s pbuf strtol(pointer(s), pointer(pbuf))
    return num, pbuf
end

@inline function Base.parse(::Type{Float64}, s::Union{StaticString, MallocString})
    num, pbuf = strtod(s)
    load(pointer(pbuf)) == Ptr{UInt8}(0) && return NaN
    return num
end
@inline Base.parse(::Type{T}, s::Union{StaticString, MallocString}) where {T <: AbstractFloat} = T(parse(Float64, s))

@inline function Base.parse(::Type{Int64}, s::Union{StaticString, MallocString})
    num, pbuf = strtol(s)
    return num
end
@inline Base.parse(::Type{T}, s::Union{StaticString, MallocString}) where {T <: Integer} = T(parse(Int64, s))
