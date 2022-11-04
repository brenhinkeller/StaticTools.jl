## --- Reference operator

    x = Ref(1)
    @test isa(⅋(x), Ptr{Int64})
    @test ⅋(x) == pointer_from_objref(x)
    x = c"asdf"
    @test isa(⅋(x), Ptr{UInt8})
    @test ⅋(x) == pointer(x)

## --- dlopen / dlsym / dlclose / @ptrcall / @symbolcall

    dlpath = c"libc" * StaticTools.DLEXT()
    if Sys.islinux()
        dlpath *= c".6"
    end
    lib = StaticTools.dlopen(dlpath)
    @test isa(lib, Ptr{StaticTools.DYLIB})
    @test lib != C_NULL

    t = c"time"
    timefp = StaticTools.dlsym(lib, t)
    @test isa(timefp, Ptr)
    @test timefp != C_NULL

    a, b = ccall(timefp, Int64, (Ptr{Cvoid},), C_NULL), time()
    @test isapprox(a, b, atol = 5)

    dltime() = @ptrcall timefp(C_NULL::Ptr{Nothing})::Int64
    a, b = dltime(), time()
    @test isapprox(a, b, atol = 5)

    ctime() = @symbolcall time()::Int64
    a, b = ctime(), time()
    @test isapprox(a, b, atol = 5)

    mallocfp = StaticTools.dlsym(lib, c"malloc")
    @test isa(mallocfp, Ptr)
    @test mallocfp != C_NULL

    dlmalloc(nbytes) = @ptrcall mallocfp(nbytes::Int)::Ptr{Float64}
    ptr = dlmalloc(10*sizeof(Float64))
    @test isa(ptr, Ptr{Float64})
    @test ptr != C_NULL

    Base.unsafe_store!(ptr, 3.141592, 1)
    @test Base.unsafe_load(ptr, 1) === 3.141592

    freefp = StaticTools.dlsym(lib, c"free")
    @test isa(freefp, Ptr)
    @test freefp != C_NULL

    dlfree(ptr) = @ptrcall freefp(ptr::Ptr{Float64})::Nothing
    @test isnothing(dlfree(ptr))

    @test StaticTools.dlclose(lib) == 0

    # Try opening without specifying extension
    if Sys.isbsd()
        lib = StaticTools.dlopen(c"libm")
        @test lib != C_NULL
        @test (lib != C_NULL) && StaticTools.dlclose(lib) == 0
    end

## --- more ``@symbolcall`s

    cmalloc(nbytes) = @symbolcall malloc(nbytes::Int)::Ptr{Float64}
    ptr = cmalloc(10*sizeof(Float64))
    @test isa(ptr, Ptr{Float64})
    @test ptr != C_NULL

    Base.unsafe_store!(ptr, 3.141592, 1)
    @test Base.unsafe_load(ptr, 1) === 3.141592

    cfree(ptr) = @symbolcall free(ptr::Ptr{Float64})::Nothing
    @test isnothing(cfree(ptr))


## --- @externptr / @externload

    if Sys.isbsd()
        foo() = @externload __stderrp::Ptr{UInt8}
    else
        foo() = @externload stderr::Ptr{UInt8}
    end
    @test foo() == stderrp()

    if Sys.isbsd()
        fooptr() = @externptr __stderrp::Ptr{UInt8}
    else
        fooptr() = @externptr stderr::Ptr{UInt8}
    end
    @test Base.unsafe_load(fooptr()) == stderrp()

## --- Test llvmtype_external / llvmtype_internal

    @test StaticTools.llvmtype_internal(:(Ptr{UInt8})) == :("i8*")
    @test StaticTools.llvmtype_internal(:(Ptr{Ptr{UInt8}})) == :("i8**")
    @test StaticTools.llvmtype_internal(:(Ptr{Ptr{Ptr{UInt8}}})) == :("i8***")
    @test StaticTools.llvmtype_internal(:(Ptr{Ptr{Ptr{Ptr{UInt8}}}})) == :("i8****")
    @test StaticTools.llvmtype_internal(:(Ptr{Ptr{Ptr{Ptr{Ptr{UInt8}}}}})) == :("i8*****")
    @test StaticTools.llvmtype_internal(:(Ptr{Float32})) == :("float*")
    @test StaticTools.llvmtype_internal(:(Ptr{Float16})) == :("half*")
    @test StaticTools.llvmtype_internal(:UInt) == StaticTools.llvmtype_external(:UInt) == ((Int==Int64) ? :i64 : :i32)
