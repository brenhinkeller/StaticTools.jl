## --- Malloc and free!

    p = malloc(100)
    @test isa(p, Ptr)
    @test free(p) == 0

    p = malloc(0x10)
    @test isa(p, Ptr)
    @test free(p) == 0

    p = malloc(Int16(100))
    @test isa(p, Ptr)
    @test free(p) == 0

    p = calloc(100*sizeof(Int64))
    @test isa(p, Ptr)
    @test MallocArray{Int64}(p, 10, 10) == fill(0,10,10)
    @test free(p) == 0

## --- memcpy, memcmp, etc.

    a = MallocArray{Float64}(undef, 100)
    @test memcpy!(a, ones(100)) == 0
    @test a == ones(100)

    @test memcmp(a, a, 100) === Int32(0)
    @test memcmp(c"foo", c"foo", 3) === Int32(0)
    @test memcmp(c"foo", "foo", 3) === Int32(0)
    @test memcmp(c"foo", c"bar", 3) != 0

    @test memset!(a, 0) === Int32(0)
    @test a == zeros(100)

    free(a)

## --- dlopen / dlsym / dlclose / @ptrcall / @symbolcall

    dlpath = c"libc" * StaticTools.DLEXT
    if Sys.islinux()
        dlpath *= c".6"
    end
    lib = StaticTools.dlopen(dlpath)
    @test isa(lib, Ptr{StaticTools.DYLIB})
    @test lib != C_NULL

    t = m"time"
    timefp = StaticTools.dlsym(lib, t)
    @test isa(timefp, Ptr)
    @test timefp != C_NULL
    free(t)

    a, b = ccall(timefp, Int64, (Ptr{Cvoid},), C_NULL), time()
    @test isapprox(a, b, atol = 5)

    dltime() = @ptrcall timefp()::Int64
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

    if Sys.isapple()
        foo() = @externload __stderrp::Ptr{UInt8}
    else
        foo() = @externload stderr::Ptr{UInt8}
    end
    @test foo() == stderrp()

    if Sys.isapple()
        fooptr() = @externptr __stderrp::Ptr{UInt8}
    else
        fooptr() = @externptr stderr::Ptr{UInt8}
    end
    @test Base.unsafe_load(fooptr()) == stderrp()


## --- Other libc utility functions

    @test usleep(1000) === Int32(0)

    @test isa(StaticTools.time(), Int64)
    @test StaticTools.time() > 10^9
