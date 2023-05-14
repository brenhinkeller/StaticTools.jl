abstract type StaticContext end
abstract type DefaultStaticContext <: StaticContext end

struct DefaultCtx <: DefaultStaticContext end

"""
```julia
static_type(ctx::StaticContext, x)
static_type(x)
```

Returns an object similar to `x` with contents converted based on rules 
specified by `ctx`. `static_type` can be used for types or for objects.

For the default case, this converts `Array`s to `MallocArray`s and 
`String`s to `MallocString`s.

To define your own rules, create a new `StaticContext` and then define
two versions of `static_type` for each type you would like to convert.
One converts the value, and one converts the type. Here is the builtin
example for converting Arrays:
    
```
struct MyCtx <: StaticContext end
static_type(ctx::MyCtx, x::Array) = MallocArray(x)
static_type(ctx::MyCtx, ::Type{Array{T,N}}) where {T,N} = MallocArray{T,N}
```
For this context struct, inherit from `StaticTools.DefaultStaticContext`
to build on the defaults, or inherit from `StaticTools.StaticContext`
to define rules from scratch.

`static_type` is mainly useful for converting objects that are heavily 
paramaterized. The SciML infrastructure has a lot of this. The main
objects like a `DiffEq.Integrator` has many type parameters, and by
default, some are not amenable to static compilation. `static_type`
can be used to convert them to forms that can help numerical code to
be statically compiled.

`static_type` cannot convert all objects automatically. It transforms
all type parameters and the contents of each field in an object 
(recursively). But, some objects do not define a "fully specified" 
constructor. In some cases, another method, `static_type_contents`
can help by returning the components to help for a manual invocation
of the constructor.

Note that any `Malloc`-objects created through this function must still be 
`free`d manually if you do not wish to leak memory.
"""
static_type(x) = static_type(DefaultCtx(), x)
static_type(ctx::DefaultStaticContext, x::Array) = MallocArray(x)
static_type(ctx::DefaultStaticContext, ::Type{Array{T,N}}) where {T,N} = MallocArray{T,N}
static_type(ctx::DefaultStaticContext, x::Vector{Vector{T}}) where {T} = MallocArray(MallocArray.(x))
static_type(ctx::DefaultStaticContext, ::Type{Vector{Vector{T}}}) where {T} = MallocVector{MallocVector{T}}
static_type(ctx::DefaultStaticContext, x::Tuple) = tuple((static_type(ctx, y) for y in x)...)
static_type(ctx::DefaultStaticContext, x::String) = MallocString(x)
static_type(ctx::DefaultStaticContext, ::Type{String}) = MallocString

# version for types including parameters
function static_type(ctx::StaticContext, ::Type{T}) where {T}
    (!isconcretetype(T) || length(T.parameters) == 0) && return T
    return T.name.wrapper{(static_type(ctx, p) for p in T.parameters)...}
end

function static_type(ctx::StaticContext, x::T) where T
    length(fieldnames(T)) == 0 && return x
    newtypes, newfields = static_type_contents(ctx, x)
    if length(newtypes) > 0
        return T.name.wrapper{newtypes...}(newfields...)
    else
        return T.name.wrapper(newfields...)
    end
end

"""
```julia
static_type_contents(ctx::StaticContext, x)
static_type_contents(x)
```

Returns a tuple with:

* a vector of type parameters for `x` transformed by `static_type`
* a vector of the contents of the fields in `x` transformed by 
  `static_type`

Results can be useful for defining objects that do not define a 
fully specified constructor. 
"""
static_type_contents(x) = static_type_contents(DefaultCtx(), x)
function static_type_contents(ctx::StaticContext, x::T) where T
    newtypes = [static_type(ctx, p) for p in T.parameters]
    newfields = [static_type(ctx, getfield(x, i)) for i in 1:fieldcount(T)]
    return newtypes, newfields
end

