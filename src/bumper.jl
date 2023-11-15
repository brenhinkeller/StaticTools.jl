


struct MallocSlabBufferData
    current         ::Ptr{Nothing}
    slab_end        ::Ptr{Nothing}
    slab_size       ::Int
    slabs           ::Ptr{Ptr{Nothing}}
    slabs_length    ::Int
    slabs_max_length::Int
    custom_slabs           ::Ptr{Ptr{Nothing}}
    custom_slabs_length    ::Int
    custom_slabs_max_length::Int

    function MallocSlabBufferData(;slab_size::Int = 1_048_576, slabs_max_length::Int=8, custom_slabs_max_length::Int=64) 
        current::Ptr{Nothing}  = malloc(slab_size)
        slab_end = current + slab_size
        
        slabs::Ptr{Ptr{Nothing}} = malloc(slabs_max_length*sizeof(Ptr{Nothing}))
        unsafe_store!(slabs, current, 1)
        custom_slabs::Ptr{Ptr{Nothing}} = malloc(custom_slabs_max_length*sizeof(Ptr{Nothing}))

        new(current, slab_end, slab_size, slabs, 1, slabs_max_length, custom_slabs, 0, custom_slabs_max_length)
    end
end


"""
    MallocSlabBuffer(;slab_size::Int = 1_048_576, slabs_max_length::Int=8, custom_slabs_max_length::Int=64)

A StaticCompiler.jl friendly version of `SlabBuffer` from [Bumper.jl](https://github.com/MasonProtter/Bumper.jl).
This should be the preferred way to manage dynamically sized memory without support from the julia runtime.

`MallocSlabBuffer` is what's known as a slab-based bump allocator. It stores a list of fixed size memory 'slabs'
(of size `slab_size` bytes), and memory can be requested from those slabs very fast. For allocations larger
than half the `slab_size`, we do a size-specific `malloc` call and store the pointer in a separate list of custom
sized slabs. At the end of a `@no_escape` block (see [Bumper.jl](https://github.com/MasonProtter/Bumper.jl)), any
unneeded slabs (custom or fixed-size) are `free`d.

The keyword arguments `slabs_max_length` and `custom_slabs_max_length` determine how many slabs and custom slabs
the allocator is set to be able to initially store. If you dynamically allocate more slabs or custom slabs than
these parameters, the `MallocSlabBuffer` will automatically resize itself to be able to store more slabs. These
parameters are just heuristics for the initial creation of the allocator.

`MallocSlabBuffer`s should be freed once you are done with them.

----------------------

Example usage:

    function slab_benchmark(argc::Int, argv::Ptr{Ptr{UInt8}})
        argc == 2 || return printf(c"Incorrect number of command-line arguments\n")
        Nevals = argparse(Int64, argv, 2) # First command-line argument
        # Create a slab buffer
        buf = MallocSlabBuffer()
        @no_escape buf begin
            # Create some vector x of length 10 containing all 1s.
            x = @alloc(Int, 10)
            x .= 1
            for i ∈ 1:Nevals
                # Start a new no_escape block so that allocations created during this
                # block get freed up at the end
                @no_escape buf begin
                    # Do some allocating operations in the loop
                    y = @alloc(Int, 10)
                    y .= x .+ 1
                    # It's vital that we never allow an array created by alloc to ever
                    # escape a @no_escape block!
                    sum(y) 
                end
            end
            nothing
        end
        # release the buffer once you're done with it.
        free(buf)
    end

    julia> compile_executable(slab_benchmark, (Int64, Ptr{Ptr{UInt8}}), "./");

    shell> time ./slab_benchmark 1000000000
    real    0m2.417s
    user    0m2.408s
    sys     0m0.000s

-------------------------

Implementation notes:

+ MallocSlabBuffer stores a pointer to a `MallocSlabBufferData` so it can mutate the object without being a `mutable` type.
+ It stores a set of memory "slabs" of size `slab_size` (default 1 megabyte). 
+ the `current` field is the currently active pointer that a newly `@alloc`'d object will aquire, if the object fits between `current` and `slab_end`.
+ If the object does not fit between `current` and `slab_end`, but is smaller than `slab_size`, we'll `malloc` a new slab,  and add it to `slabs` (reallocating the `slabs` pointer if there's not enough room, as determined by `max_slabs_length`) and then set that thing as the `current` pointer, and provide that to the object.
+ If the object is bigger than `slab_size`, then we `malloc` a pointer of the requested size, and add it to the `custom_slabs` pointer  (also reallocating that pointer if necessary), leaving `current` and `slab_end` unchanged.
+ When a `@no_escape` block ends, we reset `current`, and `slab_end` to their old values, and if `slabs` or `custom_slabs` have grown, we `free` all the pointers that weren't present before, and reset their respective `length`s (but not `max_size`s).



"""
struct MallocSlabBuffer
    ptr::Ptr{MallocSlabBufferData}
    function MallocSlabBuffer(;kwargs...)
        ptr::Ptr{MallocSlabBufferData} = malloc(sizeof(MallocSlabBufferData))
        unsafe_store!(ptr, MallocSlabBufferData(;kwargs...), 1)
        new(ptr)
    end
end

let
    ex = quote
        p = getfield(buf, :ptr)
    end
    for i ∈ 1:fieldcount(MallocSlabBufferData)
        cond = quote
            if s === $(QuoteNode(fieldname(MallocSlabBufferData, i)));
                T = $(fieldtype(MallocSlabBufferData, i))
                offset = $(fieldoffset(MallocSlabBufferData, i))
            end
        end
        push!(ex.args, cond)
    end
    
    @eval function Base.getproperty(buf::MallocSlabBuffer, s::Symbol)
        $ex
        unsafe_load(convert(Ptr{T}, p + offset))
    end
    
    @eval function Base.setproperty!(buf::MallocSlabBuffer, s::Symbol, x)
        $ex
        unsafe_store!(convert(Ptr{T}, p + offset), convert(T, x))
    end
end

Base.propertynames(buf::MallocSlabBuffer) = fieldnames(MallocSlabBufferData)

function free(buf::MallocSlabBuffer)
    for i ∈ 1:buf.slabs_length
        free(unsafe_load(buf.slabs, i))
    end
    for i ∈ 1:buf.custom_slabs_length
        free(unsafe_load(buf.custom_slabs, i))
    end
    free(buf.slabs)
    free(buf.custom_slabs)
    free(getfield(buf, :ptr))
end

function Bumper.alloc_ptr!(buf::MallocSlabBuffer, sz::Int)::Ptr{Nothing} 
    p = buf.current
    next = buf.current + sz
    if next > buf.slab_end
        p = add_new_slab!(buf, sz)
    else
        buf.current = next
    end
    p
end

@noinline function add_new_slab!(buf::MallocSlabBuffer, sz::Int)::Ptr{Nothing}
    if sz >= (buf.slab_size ÷ 2)
        custom = malloc(sz)
        if buf.custom_slabs_length > buf.custom_slabs_max_length
            buf.custom_slabs_max_length += 64
            new_custom_slabs::Ptr{Ptr{Nothing}} = malloc(buf.custom_slabs_max_length)
            for i ∈ 1:buf.custom_slabs_length
                unsafe_store!(new_custom_slabs, unsafe_load(buf.custom_slabs, i), i)
            end
            free(buf.custom_slabs)
            buf.custom_slabs = new_custom_slabs
        end
        buf.custom_slabs_length += 1
        unsafe_store!(buf.custom_slabs, custom, buf.custom_slabs_length)
        custom
    else
        new_slab = malloc(buf.slab_size)
        if buf.slabs_length >= buf.slabs_max_length
            buf.slabs_max_length += 64
            new_slabs::Ptr{Ptr{Nothing}} = malloc(buf.slabs_max_length + 64)
            for i ∈ 1:buf.slabs_length
                unsafe_store!(new_slabs, unsafe_load(buf.slabs, i), i)
            end
            free(buf.slabs)
            buf.slabs = new_slabs
        end
        buf.current = new_slab + sz
        buf.slab_end = new_slab + buf.slab_size
        buf.slabs_length += 1
        unsafe_store!(buf.slabs, new_slab, buf.slabs_length)
        new_slab
    end
end

struct MallocSlabCheckpoint
    buf::MallocSlabBuffer
    current::Ptr{Nothing}
    slab_end::Ptr{Nothing}
    slabs_length::Int
    custom_slabs_length::Int
end

function Bumper.checkpoint_save(buf::MallocSlabBuffer)
    MallocSlabCheckpoint(buf, buf.current, buf.slab_end, buf.slabs_length, buf.custom_slabs_length)
end

@noinline function restore_slabs!(slabs, slabs_length, cp_slabs_length)
    for i ∈ (cp_slabs_length+1):slabs_length
        free(unsafe_load(slabs, i))
    end
end

@inline function Bumper.checkpoint_restore!(cp::MallocSlabCheckpoint)
    buf = cp.buf
    slabs = buf.slabs
    custom = buf.custom_slabs

    if buf.slabs_length > cp.slabs_length
        restore_slabs!(buf.slabs, buf.slabs_length, cp.slabs_length)
        buf.slabs_length = cp.slabs_length
    end
    if buf.custom_slabs_length > cp.custom_slabs_length
        restore_slabs!(buf.custom_slabs, buf.custom_slabs_length, cp.custom_slabs_length)
        buf.custom_slabs_length = cp.custom_slabs_length
    end
    buf.current  = cp.current
    buf.slab_end = cp.slab_end 
    nothing
end
