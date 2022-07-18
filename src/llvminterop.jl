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

julia> dltime() = @ptrcall fp()::Int
ctime (generic function with 1 method)

julia> dltime()
1654320146

julia> StaticTools.dlclose(lib)
0
```
"""
@inline dlopen(name::AbstractMallocdMemory, flag=RTLD_LOCAL|RTLD_LAZY) = dlopen(pointer(name), flag)
@inline dlopen(name, flag=RTLD_LOCAL|RTLD_LAZY) = GC.@preserve name dlopen(pointer(name), flag)
@inline function dlopen(name::Ptr{UInt8}, flag::Int32)
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

@static if Sys.isapple()
    const DLEXT = c".dylib"
elseif Sys.iswindows()
    const DLEXT = c".dll"
else
    const DLEXT = c".so"
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

See also: `StaticTools.dlopen`, `StaticTools.@ptrcall`, `StaticTools.dlclose`

## Examples
```julia
julia> lib = StaticTools.dlopen(c"libc.dylib") # on macOS
Ptr{StaticTools.DYLIB} @0x000000010bf49b78

julia> fp = StaticTools.dlsym(lib, c"time")
Ptr{Nothing} @0x00007fffa773dfa4

julia> dltime() = @ptrcall fp()::Int
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

julia> dltime() = @ptrcall fp()::Int
dltime (generic function with 1 method)

julia> dltime()
1654320146

julia> StaticTools.dlclose(lib)
0
```
"""
@inline function dlclose(handle::Ptr{DYLIB})
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

## -- Macro for calling function pointers (as obtained from e.g. dlsym) via llvm

"""
```julia
@ptrcall function_pointer(argvalue1::Type1, ...)::ReturnType
```
Call a function pointer (e.g., as obtained from `dlsym`) via macro-constructed
`llvmcall`.

See also: `StaticTools.dlopen`, `StaticTools.dlsym`, `StaticTools.dlclose`
c.f.: `@ccall`, `StaticTools.@symbolcall`

## Examples
```julia
julia> lib = StaticTools.dlopen(c"libc.dylib") # on macOS
Ptr{StaticTools.DYLIB} @0x000000010bf49b78

julia> fp = StaticTools.dlsym(lib, c"time")
Ptr{Nothing} @0x00007fffa773dfa4

julia> dltime() = @ptrcall fp()::Int
dltime (generic function with 1 method)

julia> dltime()
1654320146

julia> StaticTools.dlclose(lib)
0
```
"""
macro ptrcall(expr)
    # Error if missing type annotation
    expr.head === :(::) || return :(error("@ptrcall expression must end with type annotation"))
    # Separate function call from type annotation
    fn = first(expr.args)
    return_type = last(expr.args)
    # Separate function call into function name and arg types
    fptr = first(fn.args)
    all(i->fn.args[i].head===:(::), 2:length(fn.args)) || return :(error("@ptrcall function arguments must be annotated"))
    arguments = ntuple(i->first(fn.args[i+1].args), length(fn.args)-1)
    argument_types = ntuple(i->last(fn.args[i+1].args), length(fn.args)-1)
    regname = 'a':'z'

    # Convert Julia types to equivalent LLVM types
    Tᵣ_ext = llvmtype_external(return_type)
    Tᵣ_int = llvmtype_internal(return_type)
    Tₐ_ext = llvmtype_external.(argument_types)
    Tₐ_int = llvmtype_internal.(argument_types)

    # String of arguments in LLVM form
    fpstr = Int===Int64 ? "i64 %jlfp" : "i32 %jlfp"
    argstr_external = fpstr
    for i ∈ 1:length(Tₐ_ext)
        argstr_external *= ", "
        argstr_external *= "$(Tₐ_ext[i]) %$(regname[i])"
    end
    argstr_internal = ""
    for i ∈ 1:length(Tₐ_int)
        if Tₐ_ext[i] != Tₐ_int[i] # If we need to convert int<>ptr
            argstr_internal *= "$(Tₐ_int[i]) %$(regname[i])_ptr"
        else
            argstr_internal *= "$(Tₐ_int[i]) %$(regname[i])"
        end
        i < length(Tₐ_int) && (argstr_internal *= ", ")
    end

    # String of argument types in LLVM form
    argtypestr = ""
    for i ∈ 1:length(Tₐ_int)
        argtypestr *= "$(Tₐ_int[i])"
        i < length(Tₐ_int) && (argtypestr *= ", ")
    end

    # Int to pointer conversions
    inttoptrstr = ""
    for i ∈ eachindex(argument_types)
        if Tₐ_ext[i] != Tₐ_int[i] # If we need to convert int<>ptr
            inttoptrstr *= "%$(regname[i])_ptr = inttoptr $(Tₐ_ext[i]) %$(regname[i]) to $(Tₐ_int[i])\n"
        end
    end

    # Function call
    callstr = Tᵣ_int == Tᵣ_ext ? "%result = call" : "%result_ptr = call"
    Tᵣ_int === :void && (callstr = "call")

    # Return statement
    retstr = Tᵣ_int == Tᵣ_ext ? "" : "%result = ptrtoint $Tᵣ_int %result_ptr to $Tᵣ_ext\n"
    retstr *= "ret $Tᵣ_ext"
    Tᵣ_int === :void || (retstr *= " %result")

    # Construct llvm IR to call
    llvm_str = """
    define $Tᵣ_ext @main($argstr_external) #0 {
      $inttoptrstr
      %fptr = inttoptr $fpstr to $Tᵣ_int ($argtypestr)*
      $callstr $Tᵣ_int ($argtypestr) %fptr($argstr_internal)
      $retstr
    }
    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """
    call = :(Base.llvmcall(($llvm_str, "main"), $return_type, Tuple{Ptr{Nothing}, $(argument_types...)}, $fptr, $(arguments...)))
    return esc(call)
end

## --- Macro for calling arbitrary symbols via LLVM

"""
```julia
@symbolcall symbol(argvalue1::Type1, ...)::ReturnType
```
Call a function by symbol/name in LLVM IR, via macro-constructed `llvmcall`

See also: `@ccall`, `StaticTools.@ptrcall`

## Examples
```julia
julia> ctime() = @symbolcall time()::Int
ctime (generic function with 1 method)

julia> ctime()
1654322507

julia> @macroexpand @symbolcall time()::Int
:(Base.llvmcall(("declare i64 @time()\n\ndefine i64 @main() #0 {\n  \n  %result = call i64 () @time()\n  ret i64 %result\n}\nattributes #0 = { alwaysinline nounwind ssp uwtable }\n", "main"), Int, Tuple{}))
```
"""
macro symbolcall(expr)
    # Error if missing type annotation
    expr.head === :(::) || return :(error("@symbolcall expression must end with type annotation"))
    # Separate function call from type annotation
    fn = first(expr.args)
    return_type = last(expr.args)
    # Separate function call into function name and arg types
    fname = first(fn.args)
    all(i->fn.args[i].head===:(::), 2:length(fn.args)) || return :(error("@symbolcall function arguments must be annotated"))
    arguments = ntuple(i->first(fn.args[i+1].args), length(fn.args)-1)
    argument_types = ntuple(i->last(fn.args[i+1].args), length(fn.args)-1)
    regname = 'A':'z'

    # Convert Julia types to equivalent LLVM types
    Tᵣ_ext = llvmtype_external(return_type)
    Tᵣ_int = llvmtype_internal(return_type)
    Tₐ_ext = llvmtype_external.(argument_types)
    Tₐ_int = llvmtype_internal.(argument_types)

    # String of arguments in LLVM form
    argstr_external = ""
    for i ∈ 1:length(Tₐ_ext)
        argstr_external *= "$(Tₐ_ext[i]) %$(regname[i])"
        i < length(Tₐ_ext) && (argstr_external *= ", ")
    end
    argstr_internal = ""
    for i ∈ 1:length(Tₐ_int)
        if Tₐ_ext[i] != Tₐ_int[i] # If we need to convert int<>ptr
            argstr_internal *= "$(Tₐ_int[i]) %$(regname[i])_ptr"
        else
            argstr_internal *= "$(Tₐ_int[i]) %$(regname[i])"
        end
        i < length(Tₐ_int) && (argstr_internal *= ", ")
    end

    # String of argument types in LLVM form
    argtypestr = ""
    for i ∈ 1:length(Tₐ_int)
        argtypestr *= "$(Tₐ_int[i])"
        i < length(Tₐ_int) && (argtypestr *= ", ")
    end

    # Int to pointer conversions
    inttoptrstr = ""
    for i ∈ eachindex(argument_types)
        if Tₐ_ext[i] != Tₐ_int[i] # If we need to convert int<>ptr
            inttoptrstr *= "%$(regname[i])_ptr = inttoptr $(Tₐ_ext[i]) %$(regname[i]) to $(Tₐ_int[i])\n"
        end
    end

    # Function call
    callstr = Tᵣ_int == Tᵣ_ext ? "%result = call" : "%result_ptr = call"
    Tᵣ_int === :void && (callstr = "call")

    # Return statement
    retstr = Tᵣ_int == Tᵣ_ext ? "" : "%result = ptrtoint $Tᵣ_int %result_ptr to $Tᵣ_ext\n"
    retstr *= "ret $Tᵣ_ext"
    Tᵣ_int === :void || (retstr *= " %result")

    # Construct llvm IR to call
    llvm_str = """
    declare $Tᵣ_int @$fname($argtypestr)

    define $Tᵣ_ext @main($argstr_external) #0 {
      $inttoptrstr
      $callstr $Tᵣ_int ($argtypestr) @$fname($argstr_internal)
      $retstr
    }
    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """
    call = :(Base.llvmcall(($llvm_str, "main"), $return_type, Tuple{$(argument_types...)}, $(arguments...)))
    return esc(call)
end

## --- Macros for obtaining llvm `external global` constants

"""
```julia
@externptr symbol::T
```
Return the pointer to an LLVM `external global` variable with name `symbol` and type `T`

## Examples
```julia
julia> foo() = @externptr __stderrp::Ptr{UInt8} # macos syntax
foo (generic function with 1 method)

julia> foo()
Ptr{Ptr{UInt8}} @0x00007fffadb8a9a0

julia> Base.unsafe_load(foo()) == stderrp()
true
```
"""
macro externptr(expr)
  # Error if missing type annotation
  expr.head === :(::) || return :(error("@externptr expression must end with type annotation"))
  # Separate name from type annotation
  name = first(expr.args)
  return_type = last(expr.args)

  # Convert Julia types to equivalent LLVM types
  Tᵣ_ext = Int===Int64 ? :i64 : :i32      # pointer
  Tᵣ_int = llvmtype_internal(return_type)

  # Construct llvm IR to call
  llvm_str = """
  @$name = external global $Tᵣ_int

  define $Tᵣ_ext @main() #0 {
    %jlptr = ptrtoint $Tᵣ_int* @$name to $Tᵣ_ext
    ret $Tᵣ_ext %jlptr
  }
  attributes #0 = { alwaysinline nounwind ssp uwtable }
  """
  call = :(Base.llvmcall(($llvm_str, "main"), Ptr{$return_type}, Tuple{}))
  return esc(call)
end


"""
```julia
@externload symbol::T
```
Load an LLVM `external global` variable with name `symbol` and type `T`

## Examples
```julia
julia> foo() = @externload __stderrp::Ptr{UInt8} # macos syntax
foo (generic function with 1 method)

julia> foo()
Ptr{UInt8} @0x00007fffadb8a240

julia> foo() == stderrp()
true
```
"""
macro externload(expr)
  # Error if missing type annotation
  expr.head === :(::) || return :(error("@externload expression must end with type annotation"))
  # Separate name from type annotation
  name = first(expr.args)
  return_type = last(expr.args)

  # Convert Julia types to equivalent LLVM types
  Tᵣ_ext = llvmtype_external(return_type)
  Tᵣ_int = llvmtype_internal(return_type)
  resultstr = Tᵣ_int == Tᵣ_ext ? "%result = %value" : "%result = ptrtoint $Tᵣ_int %value to $Tᵣ_ext"

  # Construct llvm IR to call
  llvm_str = """
  @$name = external global $Tᵣ_int

  define $Tᵣ_ext @main() #0 {
    %value = load $Tᵣ_int, $Tᵣ_int* @$name
    $resultstr
    ret $Tᵣ_ext %result
  }
  attributes #0 = { alwaysinline nounwind ssp uwtable }
  """
  call = :(Base.llvmcall(($llvm_str, "main"), $return_type, Tuple{}))
  return esc(call)
end


## --- Converting between llvm types and Julia types

function llvmtype_external(t)
    (isa(t, Expr) && first(t.args) === :Ptr) && return Int===Int64 ? :i64 : :i32
    (t === :Int128 || t === :UInt128) && return :i128
    (t === :Int64 || t === :UInt64) && return :i64
    (t === :Int32 || t === :UInt32) && return :i32
    (t === :Int16 || t === :UInt16) && return :i16
    (t === :Int8 || t === :UInt8) && return :i8
    (t === :Bool) && return :i1
    t === :Int && return Int===Int64 ? :i64 : :i32
    t === :Float64 && return :double
    t === :Float32 && return :float
    t === :Float16 && return :half
    t === :Nothing && return :void
    error("No corresponding LLVM IR type to \"$t\"")
end

function llvmtype_internal(t)
    (t == :(Ptr{UInt64}) || t == :(Ptr{Int64})) && return :("i64*")
    (t == :(Ptr{UInt32}) || t == :(Ptr{Int32})) && return :("i32*")
    (t == :(Ptr{UInt16}) || t == :(Ptr{Int16})) && return :("i16*")
    (t == :(Ptr{UInt8}) || t == :(Ptr{Int8})) && return :("i8*")
    (t == :(Ptr{Float64})) && return :("double*")
    (t == :(Ptr{Float32})) && return :("float*")
    (t == :(Ptr{Float16})) && return :("half*")
    # All other Ptrs can be i8*
    # ANSI C allows up to 12 levels of pointers, only implementing 5 here for now
    if (isa(t, Expr) && first(t.args) === :Ptr)
        t2 = last(t.args)
        if (isa(t2, Expr) && first(t2.args) === :Ptr)
            t3 = last(t2.args)
            if (isa(t3, Expr) && first(t3.args) === :Ptr)
                t4 = last(t3.args)
                if (isa(t4, Expr) && first(t4.args) === :Ptr)
                    t5 = last(t4.args)
                    if (isa(t5, Expr) && first(t5.args) === :Ptr)
                        return :("i8*****")
                    end
                    return :("i8****")
                end
                return :("i8***")
            end
            return :("i8**")
        end
        return :("i8*")
    end
    (t === :Int128 || t === :UInt128) && return :i128
    (t === :Int64 || t === :UInt64) && return :i64
    (t === :Int32 || t === :UInt32) && return :i32
    (t === :Int16 || t === :UInt16) && return :i16
    (t === :Int8 || t === :UInt8) && return :i8
    (t === :Bool) && return :i1
    t === :Int && return Int===Int64 ? :i64 : :i32
    t === :Float64 && return :double
    t === :Float32 && return :float
    t === :Float16 && return :half
    t === :Nothing && return :void
    error("No corresponding LLVM IR type to \"$t\"")
end
