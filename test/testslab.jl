sb = MallocSlabBuffer(;slab_size=16_384, slabs_max_length=1, custom_slabs_max_length=0)

@no_escape sb begin
    p = sb.current
    e = sb.slab_end
    # Allocate something that takes up almost all the room on the slab
    x1 = @alloc(Int8, 16_384÷2 - 1)
    x2 = @alloc(Int8, 16_384÷2 - 1)
    @test pointer(x1) == p
    @test pointer(x2) == pointer(x1) + 16_384÷2 - 1
    @test sb.slabs_max_length == 1
    @test sb.slabs_length == 1
    for i ∈ 1:5
        @no_escape sb begin
            @test sb.current == p + 16_384 - 2
            @test p <= sb.current <= e
            # Allocate a new vector that won't fit on the old slab
            y = @alloc(Int, 10)
            # A new slab was allocated automatically
            @test !(p <= sb.current <= e)
            @test sb.slabs_length == 2

            @test sb.slabs_max_length == 65
        end
    end
    @test sb.custom_slabs_max_length == 0
    # Allocate something too big to fit on any slab
    z = @alloc(Int, 100_000)
    @test sb.custom_slabs_max_length == 0
    
    # This doesn't effect sb.current
    @test sb.current == p + 16_384 - 2
    @test sb.current == p + 16_384 - 2
    @test sb.slab_end == e
    @test !(p <= pointer(z) <= e)
    # The pointer for z is tracked in the custom_slabs field instead
    @test pointer(z) == unsafe_load(sb.custom_slabs, sb.custom_slabs_length)
end
