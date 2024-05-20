## --- File IO primitives

    # Open a file
    """
    ```julia
    fopen(name::AbstractString, mode::AbstractString)
    ```
    Libc `fopen` function, accessed by direct `llvmcall`.

    Returns a file pointer to a file at location specified by `name` opened for
    reading, writing, or both as specified by `mode`. Valid modes include:

      `c"r"`: Read, from an existing file.

      `c"w"`: Write. If the file exists, it will be overwritten.

      `c"a"`: Append, to the end of an existing file.

    as well as `"r+"`, `c"w+"`, and `"a+"`, which enable both reading and writing.

    See also: `fclose`, `fseek`

    ## Examples
    ```julia
    julia> fp = fopen(c"testfile.txt", c"w")
    Ptr{StaticTools.FILE} @0x00007fffc92bd0b0

    julia> printf(fp, c"Here is a string")
    16

    julia> fclose(fp)
    0

    shell> cat testfile.txt
    Here is a string
    ```
    """
    @inline fopen(name::AbstractMallocdMemory, mode::AbstractMallocdMemory) = fopen(pointer(name), pointer(mode))
    @inline fopen(name, mode) = GC.@preserve name mode fopen(pointer(name), pointer(mode))
    @inline function fopen(name::Ptr{UInt8}, mode::Ptr{UInt8})
        Base.llvmcall(("""
        ; External declaration of the fopen function
        declare i8* @fopen(i8*, i8*)

        define i64 @main(i64 %jlname, i64 %jlmode) #0 {
        entry:
          %name = inttoptr i64 %jlname to i8*
          %mode = inttoptr i64 %jlmode to i8*
          %fp = call i8* (i8*, i8*) @fopen(i8* %name, i8* %mode)
          %jlfp = ptrtoint i8* %fp to i64
          ret i64 %jlfp
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Ptr{FILE}, Tuple{Ptr{UInt8}, Ptr{UInt8}}, name, mode)
    end

    # Close a file
    """
    ```julia
    fclose(fp::Ptr{FILE})
    ```
    Libc `fclose` function, accessed by direct `llvmcall`.

    Closes a file that has been previously opened by `fopen`, given a file pointer.

    Returns 0 on success.

    See also: `fopen`, `fseek`

    ## Examples
    ```julia
    julia> fp = fopen(c"testfile.txt", c"w")
    Ptr{StaticTools.FILE} @0x00007fffc92bd0b0

    julia> printf(fp, c"Here is a string")
    16

    julia> fclose(fp)
    0

    shell> cat testfile.txt
    Here is a string
    ```
    """
    @inline function fclose(fp::Ptr{FILE})
        if fp == C_NULL
            Int32(-1)
        else
            Base.llvmcall(("""
            ; External declaration of the fclose function
            declare i32 @fclose(i8*)

            define i32 @main(i64 %jlfp) #0 {
            entry:
              %fp = inttoptr i64 %jlfp to i8*
              %status = call i32 (i8*) @fclose(i8* %fp)
              ret i32 %status
            }

            attributes #0 = { alwaysinline nounwind ssp uwtable }
            """, "main"), Int32, Tuple{Ptr{FILE}}, fp)
        end
    end

    """
    ```julia
    ftell(fp::Ptr{FILE})
    ```
    Libc `ftell` function, accessed by direct `llvmcall`.

    Return the current position of the file pointer `fp`, in bytes from the start of the file.

    ## Examples
    ```julia
    julia> fp = fopen(c"testfile.txt", c"w")
    Ptr{StaticTools.FILE} @0x00007fffc92bd0b0

    julia> ftell(fp)
    0

    julia> printf(fp, c"Here is a string")
    16

    julia> ftell(fp)
    16

    julia> fclose(fp)
    0
    ```
    """
    @inline function ftell(fp::Ptr{FILE})
        @assert Int===Int64
        if fp == C_NULL
            Int64(-1)
        else
            Base.llvmcall(("""
            ; External declaration of the ftell function
            declare i64 @ftell(i8*)

            define i64 @main(i64 %jlfp) #0 {
            entry:
              %fp = inttoptr i64 %jlfp to i8*
              %position = call i64 @ftell(i8* %fp)
              ret i64 %position
            }

            attributes #0 = { alwaysinline nounwind ssp uwtable }
            """, "main"), Int64, Tuple{Ptr{FILE}}, fp)
        end
    end

    # Seek in a file
    @inline frewind(fp::Ptr{FILE}) = fseek(fp, 0, SEEK_SET)

    """
    ```julia
    fseek(fp::Ptr{FILE}, offset::Int64, whence::Int32=SEEK_CUR)
    ```
    Libc `fseek` function, accessed by direct `llvmcall`.

    Move position within a file given a file pointer `fp` obtained from `fopen`.
    The new position will be `offset` bytes (or characters, in the event that all
    characters are non-unicode ASCII characters encoded as `UInt8`s) away from the
    position specified by `whence`.

    The position reference `whence` can take on values of either:

      SEEK_SET = Int32(0)           File start

      SEEK_CUR = Int32(1)           Current position

      SEEK_END = Int32(2)           File end

    where `SEEK_CUR` is the default value.

    Returns 0 on success.

    See also: `fopen`, `fclose`

    ## Examples
    ```julia
    julia> fp = fopen(c"testfile.txt", c"w+")
    Ptr{StaticTools.FILE} @0x00007fffc92bd148

    julia> printf(fp, c"Here is a string!")
    17

    julia> fseek(fp, -2)
    0

    julia> Char(getc(fp))
    'g': ASCII/Unicode U+0067 (category Ll: Letter, lowercase)

    julia> fclose(fp)
    0
    ```
    """
    @inline function fseek(fp::Ptr{FILE}, offset::Int64, whence::Int32=SEEK_CUR)
        @assert Int===Int64
        if fp == C_NULL || whence < 0 || whence > 2
            Int32(-1)
        else
            Base.llvmcall(("""
            ; External declaration of the fseek function
            declare i32 @fseek(i8*, i64, i32)

            define i32 @main(i64 %jlfp, i64 %offset, i32 %whence) #0 {
            entry:
              %fp = inttoptr i64 %jlfp to i8*
              %status = call i32 @fseek(i8* %fp, i64 %offset, i32 %whence)
              ret i32 %status
            }

            attributes #0 = { alwaysinline nounwind ssp uwtable }
            """, "main"), Int32, Tuple{Ptr{FILE}, Int64, Int32}, fp, offset, whence)
        end
    end
    const SEEK_SET = Int32(0)
    const SEEK_CUR = Int32(1)
    const SEEK_END = Int32(2)

## --- Read and write

    # Read binary data from file
    # fread

    # Write binary data to file
    # frwite



## -- stdio pointers

    # Get pointer to stdout
    """
    ```julia
    stdoutp()
    ```
    Zero-argument function which returns a raw pointer to the current standard
    output filestream, `stdout`.

    ## Examples
    ```julia
    julia> stdoutp()
    Ptr{StaticTools.FILE} @0x00007fffc92b91a8

    julia> printf(stdoutp(), c"Hi there!\n")
    Hi there!
    10
    ```
    """
@static if Sys.isbsd()
    @inline function stdoutp()
        @assert Int===Int64
        Base.llvmcall(("""
        @__stdoutp = external global i8*

        define i64 @main() #0 {
        entry:
          %ptr = load i8*, i8** @__stdoutp, align 8
          %jlfp = ptrtoint i8* %ptr to i64
          ret i64 %jlfp
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Ptr{FILE}, Tuple{})
    end
elseif Sys.iswindows()
    @inline function stdoutp()
        @assert Int===Int64
        Base.llvmcall(("""
        declare i8* @__acrt_iob_func(i32 noundef)

        define i64 @main() #0 {
        entry:
          %ptr = call i8* @__acrt_iob_func(i32 noundef 1)
          %jlfp = ptrtoint i8* %ptr to i64
          ret i64 %jlfp
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Ptr{FILE}, Tuple{})
    end
else
    @inline function stdoutp()
        @assert Int===Int64
        Base.llvmcall(("""
        @stdout = external global i8*

        define i64 @main() #0 {
        entry:
          %ptr = load i8*, i8** @stdout, align 8
          %jlfp = ptrtoint i8* %ptr to i64
          ret i64 %jlfp
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Ptr{FILE}, Tuple{})
    end
end


    # Get pointer to stderr
    """
    ```julia
    stderrp()
    ```
    Zero-argument function which returns a raw pointer to the current standard
    error filestream, `stderr`.

    ## Examples
    ```julia
    julia> stderrp()
    Ptr{StaticTools.FILE} @0x00007fffc92b9240

    julia> printf(stderrp(), c"Hi there!\n")
    Hi there!
    10
    ```
    """
@static if Sys.isbsd()
    @inline function stderrp()
        @assert Int===Int64
        Base.llvmcall(("""
        @__stderrp = external global i8*

        define i64 @main() #0 {
        entry:
          %ptr = load i8*, i8** @__stderrp, align 8
          %jlfp = ptrtoint i8* %ptr to i64
          ret i64 %jlfp
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Ptr{FILE}, Tuple{})
    end
elseif Sys.iswindows()
    @inline function stderrp()
        @assert Int===Int64
        Base.llvmcall(("""
        declare i8* @__acrt_iob_func(i32 noundef)

        define i64 @main() #0 {
        entry:
          %ptr = call i8* @__acrt_iob_func(i32 noundef 2)
          %jlfp = ptrtoint i8* %ptr to i64
          ret i64 %jlfp
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Ptr{FILE}, Tuple{})
    end
else
    @inline function stderrp()
        @assert Int===Int64
        Base.llvmcall(("""
        @stderr = external global i8*

        define i64 @main() #0 {
        entry:
          %ptr = load i8*, i8** @stderr, align 8
          %jlfp = ptrtoint i8* %ptr to i64
          ret i64 %jlfp
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Ptr{FILE}, Tuple{})
    end
end


    # Get pointer to stdin
    """
    ```julia
    stdinp()
    ```
    Zero-argument function which returns a raw pointer to the current standard
    input filestream, `stdin`.

    ## Examples
    ```julia
    julia> stdinp()
    Ptr{StaticTools.FILE} @0x00007fffc92b9110
    ```
    """
@static if Sys.isbsd()
    @inline function stdinp()
        @assert Int===Int64
        Base.llvmcall(("""
        @__stdinp = external global i8*

        define i64 @main() #0 {
        entry:
          %ptr = load i8*, i8** @__stdinp, align 8
          %jlfp = ptrtoint i8* %ptr to i64
          ret i64 %jlfp
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Ptr{FILE}, Tuple{})
    end
elseif Sys.iswindows()
    @inline function stdinp()
        @assert Int===Int64
        Base.llvmcall(("""
        declare i8* @__acrt_iob_func(i32 noundef)

        define i64 @main() #0 {
        entry:
          %ptr = call i8* @__acrt_iob_func(i32 noundef 0)
          %jlfp = ptrtoint i8* %ptr to i64
          ret i64 %jlfp
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Ptr{FILE}, Tuple{})
    end
else
    @inline function stdinp()
        @assert Int===Int64
        Base.llvmcall(("""
        @stdin = external global i8*

        define i64 @main() #0 {
        entry:
          %ptr = load i8*, i8** @stdin, align 8
          %jlfp = ptrtoint i8* %ptr to i64
          ret i64 %jlfp
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Ptr{FILE}, Tuple{})
    end
end


## --- The basics of basics: putchar/fputc

    """
    ```julia
    putchar([fp::Ptr{FILE}], c::Union{Char,UInt8})
    ```
    Libc `putchar` / `fputc` function, accessed by direct `llvmcall`.

    Prints a single character `c` (either a `Char` or a raw `UInt8`) to a file
    pointer `fp`, defaulting to the current standard output `stdout` if not
    specified.

    Returns `0` on success.

    ## Examples
    ```julia
    julia> putchar('C')
    0

    julia> putchar(0x63)
    0

    julia> putchar('\n') # Newline, flushes stdout
    Cc
    0
    ```
    """
    @inline putchar(c::Char) = putchar(UInt8(c))
    @inline function putchar(c::UInt8)
        Base.llvmcall(("""
        ; External declaration of the putchar function
        declare i32 @putchar(i8) nounwind

        define i32 @main(i8 %c) #0 {
        entry:
          %status = call i32 (i8) @putchar(i8 %c)
          ret i32 0
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{UInt8}, c)
    end
    @inline putchar(fp::Ptr{FILE}, c::Char) = putchar(fp, UInt8(c))
    @inline function putchar(fp::Ptr{FILE}, c::UInt8)
        @assert Int===Int64
        if fp == C_NULL
            Int32(-1)
        else
            Base.llvmcall(("""
            ; External declaration of the fputc function
            declare i32 @fputc(i32, i8*) nounwind

            define i32 @main(i64 %jlfp, i32 %c) #0 {
            entry:
              %fp = inttoptr i64 %jlfp to i8*
              %status = call i32 (i32, i8*) @fputc(i32 %c, i8* %fp)
              ret i32 0
            }

            attributes #0 = { alwaysinline nounwind ssp uwtable }
            """, "main"), Int32, Tuple{Ptr{FILE}, Int32}, fp, c % Int32)
        end
    end


    """
    ```julia
    newline([fp::Ptr{FILE}])
    ```
    Prints a single newline (`\n`) to a file pointer `fp`, defaulting  to `stdout`
    if not specified.

    Returns `0` on success.

    ## Examples
    ```julia
    julia> putchar('C')
    0

    julia> newline() # flushes stdout
    C
    0
    ```
    """
    @inline newline() = putchar(0x0a)
    @inline newline(fp::Ptr{FILE}) = putchar(fp, 0x0a)

## --- getchar / getc


    """
    ```julia
    getchar()
    ```
    Libc `getchar` function, accessed by direct `llvmcall`.

    Reads a single character from standard input `stdin`, returning as `UInt8`.

    ## Examples
    ```julia
    julia> getchar()
    c
    0x63
    ```
    """
    @inline function getchar()
        Base.llvmcall(("""
        ; External declaration of the getchar function
        declare i32 @getchar()

        define i8 @main() #0 {
        entry:
          %result = call i32 @getchar()
          %c = trunc i32 %result to i8
          ret i8 %c
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), UInt8, Tuple{})
    end


    """
    ```julia
    getc(fp::Ptr{FILE})
    ```
    Libc `getc` function, accessed by direct `llvmcall`.

    Reads a single character from file pointer `fp`, returning as `Int32`
    (`-1` on EOF).

    ## Examples
    ```julia
    julia> getc(stdinp())
    c
    99
    ```
    """
    @inline function getc(fp::Ptr{FILE})
        @assert Int===Int64
        if fp == C_NULL
            Int32(-1)
        else
            Base.llvmcall(("""
            ; External declaration of the fgetc function
            declare i32 @fgetc(i8*)

            define i32 @main(i64 %jlfp) #0 {
            entry:
              %fp = inttoptr i64 %jlfp to i8*
              %c = call i32 (i8*) @fgetc(i8* %fp)
              ret i32 %c
            }

            attributes #0 = { alwaysinline nounwind ssp uwtable }
            """, "main"), Int32, Tuple{Ptr{FILE}}, fp)
        end
    end
    const EOF = Int32(-1)


## --- The old reliable: puts/fputs

    """
    ```julia
    puts([fp::Ptr{FILE}], s::AbstractString)
    ```
    Libc `puts`/`fputs` function, accessed by direct `llvmcall`.

    Prints a string `s` (specified either as a raw `Ptr{UInt8}` to a valid
    null-terminated string in memory or elseor else a string type such as
    `StaticString` or `MallocString` for which a valid pointer can be obtained)
    followed by a newline (`\n`) to a filestream specified by the file pointer
    `fp`, defaulting to the current standard output `stdout` if not specified.

    Returns `0` on success.

    ## Examples
    ```julia
    julia> puts(c"Hello there!")
    Hello there!
    0
    ```
    """
    @inline puts(s::AbstractMallocdMemory) = puts(pointer(s))
    @inline puts(s) = GC.@preserve s puts(pointer(s))
    @inline function puts(s::Ptr{UInt8})
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the puts function
        declare i32 @puts(i8* nocapture) nounwind

        define i32 @main(i64 %jls) #0 {
        entry:
          %str = inttoptr i64 %jls to i8*
          %status = call i32 (i8*) @puts(i8* %str)
          ret i32 0
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{UInt8}}, s)
    end

    @inline puts(fp::Ptr{FILE}, s::AbstractMallocdMemory) = puts(fp, pointer(s))
    @inline puts(fp::Ptr{FILE}, s) = GC.@preserve s puts(fp, pointer(s))
    @inline function puts(fp::Ptr{FILE}, s::Ptr{UInt8})
        @assert Int===Int64
        if fp == C_NULL
            Int32(-1)
        else
            Base.llvmcall(("""
            ; External declaration of the puts function
            declare i32 @fputs(i8*, i8*) nounwind

            define i32 @main(i64 %jlfp, i64 %jls) #0 {
            entry:
              %fp = inttoptr i64 %jlfp to i8*
              %str = inttoptr i64 %jls to i8*
              %status = call i32 (i8*, i8*) @fputs(i8* %str, i8* %fp)
              ret i32 0
            }

            attributes #0 = { alwaysinline nounwind ssp uwtable }
            """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}}, fp, s)
            newline(fp) # puts appends `\n`, but fputs doesn't (!)
        end
    end
    @inline puts(s::StringView) = (printf(s); newline())
    @inline puts(fp::Ptr{FILE}, s::StringView) = (printf(fp, s); newline(fp))

## --- gets/fgets

    """
    ```julia
    gets!(s::MallocString, fp::Ptr{FILE}, n::Integer=length(s))
    ```
    Libc `fgets` function, accessed by direct `llvmcall`.

    Read up to `n` characters from the filestream specified by file pointer `fp`
    to the MallocString `s`. Stops when a newline is encountered, end-of-file
    is reached, or `n` characters have been read (whichever comes first).

    ## Examples
    ```julia
    julia> s = MallocString(undef, 100)
    m""

    julia> gets!(s, stdinp(), 3)
    Ptr{UInt8} @0x00007fb15afce550

    julia> s
    m"\n"
    ```
    """
    @inline function gets!(s::MallocString, fp::Ptr{FILE}, n::Integer=length(s))
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the gets function
        declare i8* @fgets(i8*, i32, i8*)

        define i64 @main(i64 %jls, i64 %jlfp, i32 %n) #0 {
        entry:
          %str = inttoptr i64 %jls to i8*
          %fp = inttoptr i64 %jlfp to i8*
          %stp = call i8* (i8*, i32, i8*) @fgets(i8* %str, i32 %n, i8* %fp)
          %status = ptrtoint i8* %stp to i64
          ret i64 %status
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Ptr{UInt8}, Tuple{Ptr{UInt8}, Ptr{FILE}, Int32}, pointer(s), fp, n % Int32 + Int32(1))
    end
    const readline! = gets!


    """
    ```julia
    readline(fp::Ptr{FILE})
    ```
    Read characters from file pointer `fp` until a unix newline (\n) is encountered
    and copy the results to a `MallocString`

    See also `readline!` / `gets!` for a more efficient in-place version.

    ## Examples
    ```julia
    julia> fp = fopen(c"testfile.txt", c"w+")
    Ptr{FILE} @0x00007fffb05f1148

    julia> printf(fp, c"Here is a line of text!")
    23

    julia> frewind(fp)
    0

    julia> readline(fp)
    m"Here is a line of text!"
    ```
    """
    @inline function Base.readline(fp::Ptr{FILE})
        linelen = 0
        c = getc(fp)
        while c > 0 && c != 0x0d && c != 0x0a
            linelen += 1
            c = getc(fp)
        end
        fseek(fp, (c < 0) - linelen - 1)
        str = MallocString(undef, linelen + 1) # str[end] == 0x00
        if linelen > 0
            gets!(str, fp, linelen)
            fseek(fp, 1) # Advance by 1
        end
        return str
    end

## --- fread / fwrite

    """
    ```julia
    fread!(buffer::MallocString, fp::Ptr{FILE}, [n=length(buffer)])
    fread!(buffer::MallocArray{T}, fp::Ptr{FILE}, [n=length(buffer)])
    fread!(buffer, size::Int64, n::Int64, fp::Ptr{FILE})
    ```
    Libc `fread` function, accessed by direct `llvmcall`.

    Read `n` elements of `size` bytes each from the filestream specified by
    file pointer `fp` to the buffer specified as the first argument.

    When not otherwise specified, a `size` equal to `sizeof(eltype(b))` is used,
    or `sizeof(UInt8) == 1` for strings.

    See also: `fwrite`

    ## Examples
    ```julia
    julia> fp = fopen(c"testfile.b", c"rwb")
    Ptr{StaticTools.FILE} @0x00007fffa35730c8

    julia> fwrite(fp, (1:5)*(1:5)'); frewind(fp)
    0

    julia> a = szeros(Int,5,5);

    julia> fread!(a, fp); a
    5×5 StackMatrix{Int64, 25, (5, 5)}:
     1   2   3   4   5
     2   4   6   8  10
     3   6   9  12  15
     4   8  12  16  20
     5  10  15  20  25

    julia> fclose(fp)
    0
    ```
    """
    @inline function fread!(buffer, filepath::AbstractString, args...)
        fp = fopen(filepath, c"rb")
        fread!(buffer, fp, args...)
        fclose(fp)
        buffer
    end
    @inline fread!(buffer::AbstractString, fp::Ptr{FILE}, n=length(buffer)) = fread!(buffer, fp, 1, n)
    @inline fread!(buffer::DenseArray{T}, fp::Ptr{FILE}, n=length(buffer)) where {T} = fread!(buffer, fp, sizeof(T), n)
    @inline fread!(buffer::AbstractMallocdMemory, fp::Ptr{FILE}, size, n) = (fread!(Ptr{UInt8}(pointer(buffer)), fp, size, n); buffer)
    @inline fread!(buffer, fp::Ptr{FILE}, size, n) = (GC.@preserve buffer fread!(Ptr{UInt8}(pointer(buffer)), fp, size, n); buffer)
    @inline function fread!(bp::Ptr{UInt8}, fp::Ptr{FILE}, size::Int64, n::Int64)
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the fread function
        declare i64 @fread(i8*, i64, i64, i8*)

        define i64 @main(i64 %jls, i64 %size, i64 %n, i64 %jlfp) #0 {
        entry:
          %str = inttoptr i64 %jls to i8*
          %fp = inttoptr i64 %jlfp to i8*
          %status = call i64 (i8*, i64, i64, i8*) @fread(i8* %str, i64 %size, i64 %n, i8* %fp)
          ret i64 %status
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int64, Tuple{Ptr{UInt8}, Int64, Int64, Ptr{FILE}}, bp, size, n, fp)
    end


    """
    ```julia
    fwrite(filepath::AbstractString, data...)
    fwrite(fp::Ptr{FILE}, data::AbstractString)
    fwrite(fp::Ptr{FILE}, data::AbstractArray{T})
    fwrite(fp::Ptr{FILE}, data, size::Int64, n::Int64)
    ```
    Libc `fwrite` function, accessed by direct `llvmcall`.

    Write `n` elements of `size` bytes each to the filestream specified by
    file pointer `fp` or name `filepath` from the string or array `data`.
    Where not otherwise specified, a `size` equal to `sizeof(eltype(data))` is used,
    or `sizeof(UInt8) == 1` for strings.

    See also: `fread!`

    ## Examples
    ```julia
    julia> fp = fopen(c"testfile.b", c"rwb")
    Ptr{StaticTools.FILE} @0x00007fffa35730c8

    julia> fwrite(fp, (1:5)*(1:5)'); frewind(fp)
    0

    julia> a = szeros(Int,5,5);

    julia> fread!(a, fp); a
    5×5 StackMatrix{Int64, 25, (5, 5)}:
     1   2   3   4   5
     2   4   6   8  10
     3   6   9  12  15
     4   8  12  16  20
     5  10  15  20  25

    julia> fclose(fp)
    0
    ```
    """
    @inline function fwrite(filepath::AbstractString, data...)
        fp = fopen(filepath, c"wb")
        written = fwrite(fp, data...)
        fclose(fp)
        written
    end
    @inline fwrite(fp::Ptr{FILE}, data::AbstractString) = fwrite(fp, data, 1, length(data))
    @inline fwrite(fp::Ptr{FILE}, data::AbstractArray{T}) where {T} = fwrite(fp, data, sizeof(T), length(data))
    @inline fwrite(fp::Ptr{FILE}, data::AbstractMallocdMemory, size::Int64, n::Int64) = fwrite(fp, Ptr{UInt8}(pointer(data)), size, n)
    @inline fwrite(fp::Ptr{FILE}, data, size::Int64, n::Int64) = GC.@preserve data fwrite(fp, Ptr{UInt8}(pointer(data)), size, n)
    @inline function fwrite(fp::Ptr{FILE}, dp::Ptr{UInt8}, size::Int64, n::Int64)
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the fwrite function
        declare i64 @fwrite(i8*, i64, i64, i8*)

        define i64 @main(i64 %jls, i64 %size, i64 %n, i64 %jlfp) #0 {
        entry:
          %str = inttoptr i64 %jls to i8*
          %fp = inttoptr i64 %jlfp to i8*
          %status = call i64 (i8*, i64, i64, i8*) @fwrite(i8* %str, i64 %size, i64 %n, i8* %fp)
          ret i64 %status
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int64, Tuple{Ptr{UInt8}, Int64, Int64, Ptr{FILE}}, dp, size, n, fp)
    end

## --- Base.read / Base.write

    """
    ```julia
    read(fp::Ptr{FILE}, UInt8)
    ```
    Read a single byte (as a single `UInt8`) from file pointer `fp`.
    """
    @inline Base.read(fp::Ptr{FILE}, ::Type{UInt8}) = getc(fp::Ptr{FILE}) % UInt8

    """
    ```julia
    read(filename::AbstractStaticString, MallocString)
    read(filename::AbstractStaticString, MallocArray{T})
    ```
    Read `filename` in its entirety to a `MallocString` or `MallocArray{T}` with
    eltype `T`.
    """
    @inline function Base.read(filename::AbstractStaticString, T::Type{<:Union{MallocString, MallocArray}})
        fp = fopen(filename, c"rb")
        buffer = read(fp, T)
        fclose(fp)
        return buffer
    end

    """
    ```julia
    read(fp::Ptr{FILE}, MallocString)
    read(fp::Ptr{FILE}, MallocArray{T})
    ```
    Read `fp` in its entirety to a `MallocString` or `MallocArray{T}` with
    eltype `T`.
    """
    @inline function Base.read(fp::Ptr{FILE}, ::Type{MallocString})
        fseek(fp, 0, SEEK_END)
        len = ftell(fp)
        frewind(fp)
        str = MallocString(undef, len+1)
        fread!(str, fp, len)
        str[end] = 0x00
        return str
    end
    @inline function Base.read(fp::Ptr{FILE}, ::Type{MallocArray{T}}) where T
        fseek(fp, 0, SEEK_END)
        nbytes = ftell(fp)
        len = nbytes ÷ sizeof(T)
        frewind(fp)
        A = MallocArray{T}(undef, len)
        fread!(A, fp, len)
        return A
    end


    @inline Base.write(location::Union{AbstractStaticString, Ptr{FILE}}, data::DenseStaticArray) = fwrite(location, data)
    @inline Base.write(location::Union{AbstractStaticString, Ptr{FILE}}, data::AbstractStaticString) = fwrite(location, data)


## --- printf/fprintf, just a string

    """
    ```julia
    printf ([fp::Ptr{FILE}], [fmt::AbstractString], s)
    ```
    Libc `printf` function, accessed by direct `llvmcall`.

    Prints a string `s` (specified either as a raw `Ptr{UInt8}` to a valid
    null-terminated string in memory or else a string type such as `StaticString`
    or `MallocString` for which a valid pointer can be obtained) to a filestream
    specified by the file pointer `fp`, defaulting to the current standard output
    `stdout` if not specified.

    Optionally, a C-style format specifier string `fmt` may be provided as well.

    Returns the number of characters printed on success.

    ## Examples
    ```julia
    julia> printf(c"Hello there!\n")
    Hello there!
    13
    ```
    """
    @inline printf(s::MallocString) = printf(pointer(s))
    @inline printf(s) = GC.@preserve s printf(pointer(s))
    @inline printf(fp::Ptr{FILE}, s::MallocString) = printf(fp, pointer(s))
    @inline printf(fp::Ptr{FILE}, s) = GC.@preserve s printf(fp, pointer(s))
    @inline function printf(s::Ptr{UInt8})
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8* noalias nocapture, ...)

        define i32 @main(i64 %jls) #0 {
        entry:
          %str = inttoptr i64 %jls to i8*
          %status = call i32 (i8*, ...) @printf(i8* %str)
          ret i32 %status
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{UInt8}}, s)
    end
    @inline function printf(fp::Ptr{FILE}, s::Ptr{UInt8})
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the fprintf function
        declare i32 @fprintf(i8* noalias nocapture, i8*)

        define i32 @main(i64 %jlfp, i64 %jls) #0 {
        entry:
          %fp = inttoptr i64 %jlfp to i8*
          %str = inttoptr i64 %jls to i8*
          %status = call i32 (i8*, i8*) @fprintf(i8* %fp, i8* %str)
          ret i32 %status
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}}, fp, s)
    end
    @inline function printf(s::StringView)
        for i ∈ eachindex(s)
            putchar(s[i])
        end
        return length(s) % Int32
    end
    @inline function printf(fp::Ptr{FILE}, s::StringView)
        for i ∈ eachindex(s)
            putchar(fp, s[i])
        end
        return length(s) % Int32
    end

## --- printf/fprintf, with a format string, just like in C

    @inline printf(fmt::MallocString, s::MallocString) = printf(pointer(fmt), pointer(s))
    @inline printf(fmt, s) = GC.@preserve fmt s printf(pointer(fmt), pointer(s))
    @inline printf(fp::Ptr{FILE}, fmt::MallocString, s::MallocString) = printf(fp::Ptr{FILE}, pointer(fmt), pointer(s))
    @inline printf(fp::Ptr{FILE}, fmt, s) = GC.@preserve fmt s printf(fp::Ptr{FILE}, pointer(fmt), pointer(s))
    @inline function printf(fmt::Ptr{UInt8}, s::Ptr{UInt8})
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8* noalias nocapture, ...)

        define i32 @main(i64 %jlf, i64 %jls) #0 {
        entry:
          %fmt = inttoptr i64 %jlf to i8*
          %str = inttoptr i64 %jls to i8*
          %status = call i32 (i8*, ...) @printf(i8* %fmt, i8* %str)
          ret i32 0
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{UInt8}, Ptr{UInt8}}, fmt, s)
    end
    @inline function printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, s::Ptr{UInt8})
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the fprintf function
        declare i32 @fprintf(i8* noalias nocapture, i8*, i8*)

        define i32 @main(i64 %jlfp, i64 %jlf, i64 %jls) #0 {
        entry:
          %fp = inttoptr i64 %jlfp to i8*
          %fmt = inttoptr i64 %jlf to i8*
          %str = inttoptr i64 %jls to i8*
          %status = call i32 (i8*, i8*, i8*) @fprintf(i8* %fp, i8* %fmt, i8* %str)
          ret i32 %status
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, Ptr{UInt8}}, fp, fmt, s)
    end


    @inline printf(fmt::StaticString, n::Union{Number, Ptr}) = GC.@preserve fmt printf(pointer(fmt), n)
    @inline printf(fmt::MallocString, n::Union{Number, Ptr}) = printf(pointer(fmt), n)
    @inline printf(fp::Ptr{FILE}, fmt::StaticString, n::Union{Number, Ptr}) = GC.@preserve fmt printf(fp::Ptr{FILE}, pointer(fmt), n)
    @inline printf(fp::Ptr{FILE}, fmt::MallocString, n::Union{Number, Ptr}) = printf(fp::Ptr{FILE}, pointer(fmt), n)

    # Floating point numbers
    @inline function printf(fmt::Ptr{UInt8}, n::Float64)
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8* noalias nocapture, ...)

        define i32 @main(i64 %jlf, double %d) #0 {
        entry:
          %fmt = inttoptr i64 %jlf to i8*
          %status = call i32 (i8*, ...) @printf(i8* %fmt, double %d)
          ret i32 0
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{UInt8}, Float64}, fmt, n)
    end
    @inline function printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::Float64)
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @fprintf(i8* noalias nocapture, i8*, double)

        define i32 @main(i64 %jlfp, i64 %jlf, double %n) #0 {
        entry:
          %fp = inttoptr i64 %jlfp to i8*
          %fmt = inttoptr i64 %jlf to i8*
          %status = call i32 (i8*, i8*, double) @fprintf(i8* %fp, i8* %fmt, double %n)
          ret i32 %status
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, Float64}, fp, fmt, n)
    end

    # Just convert all other Floats to double
    @inline printf(fmt::Ptr{UInt8}, n::AbstractFloat) = printf(fmt::Ptr{UInt8}, Float64(n))
    @inline printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::AbstractFloat) = printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, Float64(n))

    # Integers
    @inline function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int64, UInt64, Ptr}
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8* noalias nocapture, ...)

        define i32 @main(i64 %jlf, i64 %n) #0 {
        entry:
          %fmt = inttoptr i64 %jlf to i8*
          %status = call i32 (i8*, ...) @printf(i8* %fmt, i64 %n)
          ret i32 0
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
    end
    @inline function printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::T) where T <: Union{Int64, UInt64, Ptr}
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @fprintf(i8* noalias nocapture, i8*, i64)

        define i32 @main(i64 %jlfp, i64 %jlf, i64 %n) #0 {
        entry:
          %fp = inttoptr i64 %jlfp to i8*
          %fmt = inttoptr i64 %jlf to i8*
          %status = call i32 (i8*, i8*, i64) @fprintf(i8* %fp, i8* %fmt, i64 %n)
          ret i32 %status
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, T}, fp, fmt, n)
    end

    @inline function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int32, UInt32}
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8* noalias nocapture, ...)

        define i32 @main(i64 %jlf, i32 %n) #0 {
        entry:
          %fmt = inttoptr i64 %jlf to i8*
          %status = call i32 (i8*, ...) @printf(i8* %fmt, i32 %n)
          ret i32 0
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
    end
    @inline function printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::T) where T <: Union{Int32, UInt32}
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @fprintf(i8* noalias nocapture, i8*, i32)

        define i32 @main(i64 %jlfp, i64 %jlf, i32 %n) #0 {
        entry:
          %fp = inttoptr i64 %jlfp to i8*
          %fmt = inttoptr i64 %jlf to i8*
          %status = call i32 (i8*, i8*, i32) @fprintf(i8* %fp, i8* %fmt, i32 %n)
          ret i32 %status
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, T}, fp, fmt, n)
    end

    @inline printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int16, UInt16} = printf(fmt, n % Int32)
    @inline printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::T) where T <: Union{Int16, UInt16} = printf(fp, fmt, n % Int32)

    @inline function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int8, UInt8}
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8* noalias nocapture, ...)

        define i32 @main(i64 %jlf, i8 %n) #0 {
        entry:
          %fmt = inttoptr i64 %jlf to i8*
          %status = call i32 (i8*, ...) @printf(i8* %fmt, i8 %n)
          ret i32 0
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
    end
    @inline function printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::T) where T <: Union{Int8, UInt8}
        @assert Int===Int64
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @fprintf(i8* noalias nocapture, i8*, i8)

        define i32 @main(i64 %jlfp, i64 %jlf, i8 %n) #0 {
        entry:
          %fp = inttoptr i64 %jlfp to i8*
          %fmt = inttoptr i64 %jlf to i8*
          %status = call i32 (i8*, i8*, i8) @fprintf(i8* %fp, i8* %fmt, i8 %n)
          ret i32 %status
        }

        attributes #0 = { alwaysinline nounwind ssp uwtable }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, T}, fp, fmt, n)
    end

## ---
