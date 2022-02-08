function strtod(s::Ptr{UInt8}, p::Ptr{Ptr{UInt8}})
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

function strtol(s::Ptr{UInt8}, p::Ptr{Ptr{UInt8}})
    Base.llvmcall(("""
    ; External declaration of the `strtol` function
    declare i64 @strtol(i8*, i8**)

    ; Function Attrs: noinline nounwind optnone ssp uwtable
    define dso_local i64 @main(i8* %str, i8** %ptr) #0 {
      %l = call i64 (i8*, i8**) @strtol (i8* %str, i8** %ptr)
      ret i64 %l
    }

    attributes #0 = { noinline nounwind optnone ssp uwtable }
    """, "main"), Int64, Tuple{Ptr{UInt8}, Ptr{Ptr{UInt8}}}, s, p)
end
@inline function strtol(s::AbstractMallocdMemory)
    pbuf = MemoryBuffer{1,Ptr{UInt8}}(undef)
    num = GC.@preserve buf strtol(pointer(s), pointer(pbuf))
    return num, pbuf
end
@inline function strtol(s)
    pbuf = MemoryBuffer{1,Ptr{UInt8}}(undef)
    num = GC.@preserve s pbuf strtol(pointer(s), pointer(pbuf))
    return num, pbuf
end


@inline function Base.parse(Float64, s::Union{StaticString, MallocString})
    num, pbuf = strtod(s)
    load(pointer(pbuf)) == Ptr{UInt8}(0) && return NaN
    return num
end
@inline Base.parse(::T, s::Union{StaticString, MallocString}) where T <: AbstractFloat = T(parse(Float64, s))

@inline function Base.parse(Int64, s::Union{StaticString, MallocString})
    num, pbuf = strtol(s)
    load(pointer(pbuf)) == Ptr{UInt8}(0) && throw(ArgumentError)
    return num
end
@inline Base.parse(::T, s::Union{StaticString, MallocString}) where T <: Integer = T(parse(Int64, s))


function system(s::Ptr{UInt8})
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
system(s::AbstractMallocdMemory) = system(pointer(s))
system(s) = GC.@preserve s system(pointer(s))
