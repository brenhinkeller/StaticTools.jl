## --- dlopen

const RTLD_LOCAL = Int32(1)
const RTLD_GLOBAL = Int32(2)
const RTLD_LAZY = Int32(4)

@inline dlopen(name::AbstractMallocdMemory, mode=RTLD_LOCAL) = dlopen(pointer(name), mode)
@inline dlopen(name, mode=RTLD_LOCAL) = GC.@preserve name dlopen(pointer(name), mode)
@inline function dlopen(name::Ptr{UInt8}, mode::Int32)
    Base.llvmcall(("""
    ; External declaration of the dlopen function
    declare i8* @dlopen(i8*, i32)

    define i64 @main(i64 %jlname, i32 %mode) #0 {
    entry:
      %name = inttoptr i64 %jlname to i8*
      %fp = call i8* (i8*, i32) @dlopen(i8* %name, i32 %mode)
      %jlfp = ptrtoint i8* %fp to i64
      ret i64 %jlfp
    }

    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """, "main"), Ptr{DYLIB}, Tuple{Ptr{UInt8}, Int32}, name, mode)
end

@static if Sys.isapple()
    const DLEXT = c".dylib"
elseif Sys.iswindows()
    const DLEXT = c".dll"
else
    const DLEXT = c".so"
end

## --- dylsym

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
    retstr = Tᵣ_int == Tᵣ_ext ? "" : "%result = ptrtoint %result_ptr $Tᵣ_int to $Tᵣ_ext\n"
    retstr *= "ret $Tᵣ_ext"
    Tᵣ_int === :void || (retstr *= " %result")

    # Construct argument types
    llvm_str = """
    define $Tᵣ_int @main($argstr_external) #0 {
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
    regname = 'a':'z'

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
    retstr = Tᵣ_int == Tᵣ_ext ? "" : "%result = ptrtoint %result_ptr $Tᵣ_int to $Tᵣ_ext\n"
    retstr *= "ret $Tᵣ_ext"
    Tᵣ_int === :void || (retstr *= " %result")


    # Construct argument types
    llvm_str = """
    declare $Tᵣ_int @$fname($argtypestr)

    define $Tᵣ_int @main($argstr_external) #0 {
      $inttoptrstr
      $callstr $Tᵣ_int ($argtypestr) @$fname($argstr_internal)
      $retstr
    }
    attributes #0 = { alwaysinline nounwind ssp uwtable }
    """
    call = :(Base.llvmcall(($llvm_str, "main"), $return_type, Tuple{$(argument_types...)}, $(arguments...)))
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
    (isa(t, Expr) && first(t.args) === :Ptr) && return :("i8*") # All other Ptrs can be i8*
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
