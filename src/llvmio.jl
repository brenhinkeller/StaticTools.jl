## --- File IO primitives

    # Open a file
    fopen(name::AbstractMallocdMemory, mode::AbstractMallocdMemory) = fopen(pointer(name), pointer(mode))
    fopen(name, mode) = GC.@preserve name mode fopen(pointer(name), pointer(mode))
    function fopen(name::Ptr{UInt8}, mode::Ptr{UInt8})
        Base.llvmcall(("""
        ; External declaration of the fopen function
        declare i8* @fopen(i8*, i8*)

        define i8* @main(i8* %name, i8* %mode) {
        entry:
            %fp = call i8* (i8*, i8*) @fopen(i8* %name, i8* %mode)
            ret i8* %fp
        }
        """, "main"), Ptr{FILE}, Tuple{Ptr{UInt8}, Ptr{UInt8}}, name, mode)
    end

    # Close a file
    function fclose(fp::Ptr{FILE})
        Base.llvmcall(("""
        ; External declaration of the fclose function
        declare i32 @fclose(i8*)

        define i32 @main(i8* %fp) {
        entry:
            %status = call i32 (i8*) @fclose(i8* %fp)
            ret i32 %status
        }
        """, "main"), Int32, Tuple{Ptr{FILE}}, fp)
    end

## -- stdio pointers

    # Get pointer to stdout
@static if Sys.isapple()
    function stdoutp()
        Base.llvmcall(("""
        @__stdoutp = external global i8*

        define i8* @main() {
        entry:
            %ptr = load i8*, i8** @__stdoutp, align 8
            ret i8* %ptr
        }
        """, "main"), Ptr{FILE}, Tuple{})
    end
else
    function stdoutp()
        Base.llvmcall(("""
        @stdout = external global i8*

        define i8* @main() {
        entry:
            %ptr = load i8*, i8** @stdout, align 8
            ret i8* %ptr
        }
        """, "main"), Ptr{FILE}, Tuple{})
    end
end


    # Get pointer to stderr
@static if Sys.isapple()
    function stderrp()
        Base.llvmcall(("""
        @__stderrp = external global i8*

        define i8* @main() {
        entry:
            %ptr = load i8*, i8** @__stderrp, align 8
            ret i8* %ptr
        }
        """, "main"), Ptr{FILE}, Tuple{})
    end
else
    function stderrp()
        Base.llvmcall(("""
        @stderr = external global i8*

        define i8* @main() {
        entry:
            %ptr = load i8*, i8** @stderr, align 8
            ret i8* %ptr
        }
        """, "main"), Ptr{FILE}, Tuple{})
    end
end


    # Get pointer to stdin
@static if Sys.isapple()
    function stdinp()
        Base.llvmcall(("""
        @__stdinp = external global i8*

        define i8* @main() {
        entry:
            %ptr = load i8*, i8** @__stdinp, align 8
            ret i8* %ptr
        }
        """, "main"), Ptr{FILE}, Tuple{})
    end
else
    function stdinp()
        Base.llvmcall(("""
        @stdin = external global i8*

        define i8* @main() {
        entry:
            %ptr = load i8*, i8** @stdin, align 8
            ret i8* %ptr
        }
        """, "main"), Ptr{FILE}, Tuple{})
    end
end


## --- The basics of basics: putchar/fputc

    putchar(c::Char) = putchar(UInt8(c))
    function putchar(c::UInt8)
        Base.llvmcall(("""
        ; External declaration of the putchar function
        declare i32 @putchar(i8 nocapture) nounwind

        define i32 @main(i8) {
        entry:
            %status = call i32 (i8) @putchar(i8 %0)
            ret i32 0
        }
        """, "main"), Int32, Tuple{UInt8}, c)
    end
    putchar(fp::Ptr{FILE}, c::Char) = putchar(fp, UInt8(c))
    function putchar(fp::Ptr{FILE}, c::UInt8)
        Base.llvmcall(("""
        ; External declaration of the fputc function
        declare i32 @fputc(i8, i8*) nounwind

        define i32 @main(i8* %fp, i8 %c) {
        entry:
            %status = call i32 (i8, i8*) @fputc(i8 %c, i8* %fp)
            ret i32 0
        }
        """, "main"), Int32, Tuple{Ptr{FILE}, UInt8}, fp, c)
    end

    newline() = putchar(0x0a)
    newline(fp::Ptr{FILE}) = putchar(fp, 0x0a)

## --- getchar / getc


    function getchar()
        Base.llvmcall(("""
        ; External declaration of the getchar function
        declare i32 @getchar()

        define i8 @main() {
        entry:
            %result = call i32 @getchar()
            %c = trunc i32 %result to i8
            ret i8 %c
        }
        """, "main"), UInt8, Tuple{})
    end

    function getchar(fp::Ptr{FILE})
        Base.llvmcall(("""
        ; External declaration of the fgetc function
        declare i32 @fgetc(i8*)

        define i8 @main(i8* %fp) {
        entry:
            %result = call i32 (i8*) @fgetc(i8* %fp)
            %c = trunc i32 %result to i8
            ret i8 %c
        }
        """, "main"), UInt8, Tuple{Ptr{FILE}}, fp)
    end


## --- The old reliable: puts/fputs

    puts(s::AbstractMallocdMemory) = puts(pointer(s))
    puts(s) = GC.@preserve s puts(pointer(s))
    function puts(s::Ptr{UInt8})
        Base.llvmcall(("""
        ; External declaration of the puts function
        declare i32 @puts(i8* nocapture) nounwind

        define i32 @main(i8*) {
        entry:
            %status = call i32 (i8*) @puts(i8* %0)
            ret i32 0
        }
        """, "main"), Int32, Tuple{Ptr{UInt8}}, s)
    end

    puts(fp::Ptr{FILE}, s::AbstractMallocdMemory) = puts(fp, pointer(s))
    puts(fp::Ptr{FILE}, s) = GC.@preserve s puts(fp, pointer(s))
    function puts(fp::Ptr{FILE}, s::Ptr{UInt8})
        Base.llvmcall(("""
        ; External declaration of the puts function
        declare i32 @fputs(i8*, i8*) nounwind

        define i32 @main(i8* %fp, i8* %str) {
        entry:
            %status = call i32 (i8*, i8*) @fputs(i8* %str, i8* %fp)
            ret i32 0
        }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}}, fp, s)
        newline(fp) # puts appends `\n`, but fputs doesn't (!)
    end

## --- printf/fprintf, just a string

    printf(s::MallocString) = printf(pointer(s))
    printf(s) = GC.@preserve s printf(pointer(s))
    printf(fp::Ptr{FILE}, s::MallocString) = printf(fp, pointer(s))
    printf(fp::Ptr{FILE}, s) = GC.@preserve s printf(fp, pointer(s))
    function printf(s::Ptr{UInt8})
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8*, ...)

        define i32 @main(i8* %str) {
        entry:
            %status = call i32 (i8*, ...) @printf(i8* %str)
            ret i32 %status
        }
        """, "main"), Int32, Tuple{Ptr{UInt8}}, s)
    end
    function printf(fp::Ptr{FILE}, s::Ptr{UInt8})
        Base.llvmcall(("""
        ; External declaration of the fprintf function
        declare i32 @fprintf(i8*, i8*)

        define i32 @main(i8* %fp, i8* %str) {
        entry:
            %status = call i32 (i8*, i8*) @fprintf(i8* %fp, i8* %str)
            ret i32 %status
        }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}}, fp, s)
    end

## --- printf/fprintf, with a format string, just like in C

    printf(fmt::MallocString, s::MallocString) = printf(pointer(fmt), pointer(s))
    printf(fmt, s) = GC.@preserve fmt s printf(pointer(fmt), pointer(s))
    printf(fp::Ptr{FILE}, fmt::MallocString, s::MallocString) = printf(fp::Ptr{FILE}, pointer(fmt), pointer(s))
    printf(fp::Ptr{FILE}, fmt, s) = GC.@preserve fmt s printf(fp::Ptr{FILE}, pointer(fmt), pointer(s))
    function printf(fmt::Ptr{UInt8}, s::Ptr{UInt8})
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8*, ...)

        define i32 @main(i8*, i8*) {
        entry:
            %call = call i32 (i8*, ...) @printf(i8* %0, i8* %1)
            ret i32 0
        }
        """, "main"), Int32, Tuple{Ptr{UInt8}, Ptr{UInt8}}, fmt, s)
    end
    function printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, s::Ptr{UInt8})
        Base.llvmcall(("""
        ; External declaration of the fprintf function
        declare i32 @fprintf(i8*, ...)

        define i32 @main(i8* %fp, i8* %fmt, i8* %str) {
        entry:
            %status = call i32 (i8*, ...) @fprintf(i8* %fp, i8* %fmt, i8* %str)
            ret i32 %status
        }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, Ptr{UInt8}}, fp, fmt, s)
    end


    printf(fmt::StaticString, n::Union{Number, Ptr}) = GC.@preserve fmt printf(pointer(fmt), n)
    printf(fmt::MallocString, n::Union{Number, Ptr}) = printf(pointer(fmt), n)
    printf(fp::Ptr{FILE}, fmt::StaticString, n::Union{Number, Ptr}) = GC.@preserve fmt printf(fp::Ptr{FILE}, pointer(fmt), n)
    printf(fp::Ptr{FILE}, fmt::MallocString, n::Union{Number, Ptr}) = printf(fp::Ptr{FILE}, pointer(fmt), n)

    # Floating point numbers
    function printf(fmt::Ptr{UInt8}, n::Float64)
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8*, ...)

        define i32 @main(i8*, double) {
        entry:
            %call = call i32 (i8*, ...) @printf(i8* %0, double %1)
            ret i32 0
        }
        """, "main"), Int32, Tuple{Ptr{UInt8}, Float64}, fmt, n)
    end
    function printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::Float64)
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @fprintf(i8*, ...)

        define i32 @main(i8* %fp, i8* %fmt, double %n) {
        entry:
            %call = call i32 (i8*, ...) @fprintf(i8* %fp, i8* %fmt, double %n)
            ret i32 %call
        }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, Float64}, fp, fmt, n)
    end

    # Just convert all other Floats to double
    printf(fmt::Ptr{UInt8}, n::AbstractFloat) = printf(fmt::Ptr{UInt8}, Float64(n))
    printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::AbstractFloat) = printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, Float64(n))

    # Integers
    function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int64, UInt64, Ptr}
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8*, ...)

        define i32 @main(i8*, i64) {
        entry:
            %call = call i32 (i8*, ...) @printf(i8* %0, i64 %1)
            ret i32 0
        }
        """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
    end
    function printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::T) where T <: Union{Int64, UInt64, Ptr}
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @fprintf(i8*, ...)

        define i32 @main(i8* %fp, i8* %fmt, i64 %n) {
        entry:
            %call = call i32 (i8*, ...) @fprintf(i8* %fp, i8* %fmt, i64 %n)
            ret i32 %call
        }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, T}, fp, fmt, n)
    end

    function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int32, UInt32}
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8*, ...)

        define i32 @main(i8*, i32) {
        entry:
            %call = call i32 (i8*, ...) @printf(i8* %0, i32 %1)
            ret i32 0
        }
        """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
    end
    function printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::T) where T <: Union{Int32, UInt32}
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @fprintf(i8*, ...)

        define i32 @main(i8* %fp, i8* %fmt, i32 %n) {
        entry:
            %call = call i32 (i8*, ...) @fprintf(i8* %fp, i8* %fmt, i32 %n)
            ret i32 %call
        }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, T}, fp, fmt, n)
    end

    function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int16, UInt16}
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8*, ...)

        define i32 @main(i8*, i16) {
        entry:
            %call = call i32 (i8*, ...) @printf(i8* %0, i16 %1)
            ret i32 0
        }
        """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
    end
    function printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::T) where T <: Union{Int16, UInt16}
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @fprintf(i8*, ...)

        define i32 @main(i8* %fp, i8* %fmt, i16 %n) {
        entry:
            %call = call i32 (i8*, ...) @fprintf(i8* %fp, i8* %fmt, i16 %n)
            ret i32 %call
        }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, T}, fp, fmt, n)
    end

    function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int8, UInt8}
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @printf(i8*, ...)

        define i32 @main(i8*, i8) {
        entry:
            %call = call i32 (i8*, ...) @printf(i8* %0, i8 %1)
            ret i32 0
        }
        """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
    end
    function printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::T) where T <: Union{Int8, UInt8}
        Base.llvmcall(("""
        ; External declaration of the printf function
        declare i32 @fprintf(i8*, ...)

        define i32 @main(i8* %fp, i8* %fmt, i8 %n) {
        entry:
            %call = call i32 (i8*, ...) @fprintf(i8* %fp, i8* %fmt, i8 %n)
            ret i32 %call
        }
        """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, T}, fp, fmt, n)
    end

## ---
