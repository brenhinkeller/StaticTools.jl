var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = StaticTools","category":"page"},{"location":"#StaticTools","page":"Home","title":"StaticTools","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for StaticTools.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [StaticTools]","category":"page"},{"location":"#StaticTools.MallocArray","page":"Home","title":"StaticTools.MallocArray","text":"MallocArray{T,N} <: AbstractArray{T,N}\n\nN-dimensional dense heap-allocated array with elements of type T.\n\nMuch like Base.Array, except (1) backed by memory that is not tracked by the Julia garbage collector (is directly allocated with malloc) so is StaticCompiler-safe, (2) should be freed when no longer in use, and (3) indexing returns views rather than copies.\n\n\n\n\n\n","category":"type"},{"location":"#StaticTools.MallocArray-Union{Tuple{N}, Tuple{T}, Tuple{UndefInitializer, Int64, Tuple{Vararg{Int64, N}}}} where {T, N}","page":"Home","title":"StaticTools.MallocArray","text":"MallocArray{T}(undef, dims)\nMallocArray{T,N}(undef, dims)\n\nConstruct an uninitialized N-dimensional MallocArray containing elements of type T. N can either be supplied explicitly, as in Array{T,N}(undef, dims), or be determined by the length or number of dims. dims may be a tuple or a series of integer arguments corresponding to the lengths in each dimension. If the rank N is supplied explicitly, then it must match the length or number of dims. Here undef is the UndefInitializer.\n\nExamples\n\njulia> A = MallocArray{Float64}(undef, 3,3) # implicit N\n3×3 MallocMatrix{Float64}:\n 3.10504e231   6.95015e-310   2.12358e-314\n 1.73061e-77   6.95015e-310   5.56271e-309\n 6.95015e-310  0.0           -1.29074e-231\n\njulia> free(A)\n0\n\njulia> A = MallocArray{Float64, 3}(undef, 2,2,2) # explicit N\n2×2×2 MallocArray{Float64, 3}:\n[:, :, 1] =\n 3.10504e231  2.0e-323\n 2.32036e77   6.94996e-310\n\n[:, :, 2] =\n 6.95322e-310  5.0e-324\n 6.95322e-310  5.56271e-309\n\njulia> free(A)\n0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.MallocMatrix","page":"Home","title":"StaticTools.MallocMatrix","text":"MallocMatrix{T} <: AbstractMatrix{T}\n\nTwo-dimensional dense heap-allocated array with elements of type T. As Base.Matrix is to Base.Array, but with MallocArray.\n\n\n\n\n\n","category":"type"},{"location":"#StaticTools.MallocString","page":"Home","title":"StaticTools.MallocString","text":"struct MallocString\n    pointer::Ptr{UInt8}\n    length::Int\nend\n\nA stringy object that contains length bytes (i.e., UInt8s), including the final null-termination (0x00), at a location in memory specified by pointer.\n\nA MallocString should generally behave like a base Julia String, but is explicitly null-terminated, mutable, standalone-StaticCompiler-safe (does not require libjulia) and backed by malloced memory which is not tracked by the GC and should be freed when no longer in use.\n\nCan be constructed with the m\"...\" string macro.\n\n\n\n\n\n","category":"type"},{"location":"#StaticTools.MallocString-Tuple{UndefInitializer, Int64}","page":"Home","title":"StaticTools.MallocString","text":"MallocString(undef, N)\n\nConstruct an uninitialized N-byte (including null-termination!) MallocString. Here undef is the UndefInitializer.\n\nExamples\n\njulia> s = MallocString(undef, 10)\nm\"\"\n\njulia> free(s)\n0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.MallocString-Union{Tuple{Tuple{Vararg{UInt8, N}}}, Tuple{N}} where N","page":"Home","title":"StaticTools.MallocString","text":"MallocString(data::NTuple{N, UInt8})\n\nConstruct a MallocString containing the N bytes specified by data.\n\nExamples\n\njulia> data = (0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x21, 0x00);\n\njulia> s = MallocString(data)\nm\"Hello world!\"\n\njulia> s[8:12] = c\"there\"; s\nm\"Hello there!\"\n\njulia> free(s)\n0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.MallocVector","page":"Home","title":"StaticTools.MallocVector","text":"MallocVector{T} <: AbstractVector{T}\n\nTwo-dimensional dense heap-allocated array with elements of type T. As Base.Vector is to Base.Array, but with MallocArray.\n\n\n\n\n\n","category":"type"},{"location":"#StaticTools.SplitMix64","page":"Home","title":"StaticTools.SplitMix64","text":"SplitMix64([seed::Bits64])\n\nInitialize the internal state of a StaticCompiler-safe (non-allocating) SplitMix64 deterministic pseudorandom number generator, optionally specifying a 64-bit seed (which may be a Float64, Int64, or UInt64).\n\nIf a seed is not specified, StaticTools.time() will be used, which returns the current Unix epoch time in seconds.\n\nSee also:\n\nsplitmix64, rand\n\nExamples\n\njulia> seed = StaticTools.time() # Pick a seed\n1649890154\n\njulia> rng = SplitMix64(seed) # Initialize the generator\nSplitMix64{Int64}((1649890154,))\n\njulia> splitmix64(rng) # Draw a pseudorandom `UInt64` from the generator\n0xca764ac7b7ea31e8\n\njulia> rand(rng) # Draw a `Float64` between 0 and 1\n0.8704883051360292\n\n\n\n\n\n","category":"type"},{"location":"#StaticTools.StaticString","page":"Home","title":"StaticTools.StaticString","text":"StaticString{N}\n\nA stringy type which should generally behave like a base Julia String, but is explicitly null-terminated, mutable, and standalone-StaticCompiler safe (does not require libjulia).\n\nCan be constructed with the c\"...\" string macro.\n\n\n\nStaticString(data::NTuple{N,UInt8})\n\nConstruct a StaticString containing the N bytes specified by data.\n\nExamples\n\njulia> data = (0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x21, 0x00);\n\njulia> s = StaticString(data)\nc\"Hello world!\"\n\njulia> s[8:12] = c\"there\"; s\nc\"Hello there!\"\n\n\n\n\n\n","category":"type"},{"location":"#StaticTools.Xoshiro256✴︎✴︎","page":"Home","title":"StaticTools.Xoshiro256✴︎✴︎","text":"Xoshiro256✴︎✴︎(seed::NTuple{4,Bits64})\n\nInitialize the internal state of a StaticCompiler-safe (non-allocating) Xoshiro256✴︎✴︎ deterministic pseudorandom number generator, specifying a 256-bit seed, which should be specified as an NTuple of four 64-bit numbers (all either Float64, Int64, or UInt64).\n\nSee also:\n\nxoshiro256✴︎✴︎, static_rng, rand\n\nExamples\n\njulia> seed = (0x9b134eccd2e63538, 0xd74ab64b2c3ecc9b, 0x70ba9c07628c27bf, 0x270a2eb658e6130b)\n(0x9b134eccd2e63538, 0xd74ab64b2c3ecc9b, 0x70ba9c07628c27bf, 0x270a2eb658e6130b)\n\njulia> rng = Xoshiro256✴︎✴︎(seed) # Initialize the generator\nXoshiro256✴︎✴︎{UInt64}((0x9b134eccd2e63538, 0xd74ab64b2c3ecc9b, 0x70ba9c07628c27bf, 0x270a2eb658e6130b))\n\njulia> xoshiro256✴︎✴︎(rng) # Draw a pseudorandom `UInt64` from the generator\n0x11059b6384fba06a\n\njulia> rand(rng) # Draw a `Float64` between 0 and 1\n0.9856766307398369\n\n\n\n\n\n","category":"type"},{"location":"#Base.parse-Tuple{Type{Float64}, Union{MallocString, StaticString}}","page":"Home","title":"Base.parse","text":"parse(::Type{T}, s::Union{StaticString, MallocString})\n\nParse a number from a StaticString or MallocString s.\n\nExamples\n\njulia> parse(Float64, c\"3.141592\")\n3.141592\n\njulia> parse(Int64, c\"3.141592\")\n3\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.fclose-Tuple{Ptr{StaticTools.FILE}}","page":"Home","title":"StaticTools.fclose","text":"fclose(fp::Ptr{FILE})\n\nLibc fclose function, accessed by direct llvmcall.\n\nCloses a file that has been previously opened by fopen, given a file pointer.\n\nSee also: fopen, fseek\n\nExamples\n\njulia> fp = fopen(c\"testfile.txt\", c\"w\")\nPtr{StaticTools.FILE} @0x00007fffc92bd0b0\n\njulia> printf(fp, c\"Here is a string\")\n16\n\njulia> fclose(fp)\n0\n\nshell> cat testfile.txt\nHere is a string\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.fopen-Tuple{Union{MallocString, MallocArray}, Union{MallocString, MallocArray}}","page":"Home","title":"StaticTools.fopen","text":"fopen(name, mode)\n\nLibc fopen function, accessed by direct llvmcall.\n\nReturns a file pointer to a file at location specified by name opened for reading, writing, or both as specified by mode. Valid modes include:\n\nc\"r\": Read, from an existing file.\n\nc\"w\": Write. If the file exists, it will be overwritten.\n\nc\"a\": Append, to the end of an existing file.\n\nas well as \"r+\", c\"w+\", and \"a+\", which enable both reading and writing.\n\nSee also: fclose, fseek\n\nExamples\n\njulia> fp = fopen(c\"testfile.txt\", c\"w\")\nPtr{StaticTools.FILE} @0x00007fffc92bd0b0\n\njulia> printf(fp, c\"Here is a string\")\n16\n\njulia> fclose(fp)\n0\n\nshell> cat testfile.txt\nHere is a string\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.free-Tuple{Ptr}","page":"Home","title":"StaticTools.free","text":"free(ptr::Ptr)\n\nLibc free function, accessed by direct StaticCompiler-safe llvmcall.\n\nFree memory that has been previously allocated with malloc.\n\nSee also: free.\n\nExamples\n\njulia> p = malloc(500)\nPtr{UInt8} @0x00007ff0e9e74290\n\njulia> free(p)\n0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.fseek","page":"Home","title":"StaticTools.fseek","text":"fseek(fp::Ptr{FILE}, offset::Int64, whence::Int32=SEEK_CUR)\n\nLibc fseek function, accessed by direct llvmcall.\n\nMove position within a file given a file pointer fp obtained from fopen. The new position will be offset bytes (or characters, in the event that all characters are non-unicode ASCII characters encoded as UInt8s) away from the position specified by whence.\n\nThe position reference whence can take on values of either:\n\nSEEK_SET = Int32(0)           File start\n\nSEEK_CUR = Int32(1)           Current position\n\nSEEK_END = Int32(2)           File end\n\nwhere SEEK_CUR is the default value.\n\nSee also: fopen, fclose\n\nExamples\n\njulia> fp = fopen(c\"testfile.txt\", c\"w+\")\nPtr{StaticTools.FILE} @0x00007fffc92bd148\n\njulia> printf(fp, c\"Here is a string!\")\n17\n\njulia> fseek(fp, -2)\n0\n\njulia> Char(getc(fp))\n'g': ASCII/Unicode U+0067 (category Ll: Letter, lowercase)\n\njulia> fclose(fp)\n0\n\n\n\n\n\n","category":"function"},{"location":"#StaticTools.getc-Tuple{Ptr{StaticTools.FILE}}","page":"Home","title":"StaticTools.getc","text":"getc(fp::Ptr{FILE})\n\nLibc getc function, accessed by direct llvmcall.\n\nReads a single character from file pointer fp, returning as Int32 (-1 on EOF).\n\nExamples\n\njulia> getc(stdinp())\nc\n99\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.getchar-Tuple{}","page":"Home","title":"StaticTools.getchar","text":"getchar()\n\nLibc getchar function, accessed by direct llvmcall.\n\nReads a single character from standard input stdin, returning as UInt8.\n\nExamples\n\njulia> getchar()\nc\n0x63\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.gets!","page":"Home","title":"StaticTools.gets!","text":"gets!(s::MallocString, fp::Ptr{FILE}, n::Integer=length(s))\n\nLibc fgets function, accessed by direct llvmcall.\n\nRead up to n characters from the filestream specified by file pointer fp to the MallocString s.\n\nExamples\n\njulia> s = MallocString(undef, 100)\nm\"\"\n\njulia> gets!(s, stdinp(), 3)\nPtr{UInt8} @0x00007fb15afce550\n\njulia> s\nm\"\n\"\n\n\n\n\n\n","category":"function"},{"location":"#StaticTools.malloc-Tuple{Integer}","page":"Home","title":"StaticTools.malloc","text":"malloc(size::Integer)\n\nLibc malloc function, accessed by direct StaticCompiler-safe llvmcall.\n\nAllocate size bytes of memory and return a pointer to that memory.\n\nSee also: free.\n\nExamples\n\njulia> p = malloc(500)\nPtr{UInt8} @0x00007ff0e9e74290\n\njulia> free(p)\n0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.memcmp-Tuple{Any, Any, Int64}","page":"Home","title":"StaticTools.memcmp","text":"memcmp(a, b, n::Int64)\n\nLibc memcmp function, accessed by direct StaticCompiler-safe llvmcall.\n\nCompare the first n bytes of a and b, returning\n\na positive value if the first n bytes of a are greater than the first n bytes of b\na negative value if the first n bytes of a are less than the first n bytes of b\n0 the first n bytes of a are equal to the first n bytes of b\n\nExamples\n\njulia> memcmp(c\"foo\", c\"foo\", 3)\n0\n\njulia> memcmp(c\"foo\", c\"bar\", 3)\n4\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.memcpy!-Tuple{Any, Any}","page":"Home","title":"StaticTools.memcpy!","text":"memcpy!(a, b, n=length(b))\n\nLibc memcpy function, accessed by direct StaticCompiler-safe llvmcall.\n\nCopy n elements from array b to array a.\n\nExamples\n\njulia> a = rand(3)\n3-element Vector{Float64}:\n 0.8559883493421137\n 0.4203692766310769\n 0.5728354965961716\n\njulia> memcpy!(a, ones(3))\n0\n\njulia> a\n3-element Vector{Float64}:\n 1.0\n 1.0\n 1.0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.newline-Tuple{}","page":"Home","title":"StaticTools.newline","text":"newline([fp::Ptr{FILE}])\n\nPrints a single newline () to a file pointer fp, defaulting  to stdout if not specified.\n\nReturns 0 on success.\n\nExamples\n\njulia> putchar('C')\n0\n\njulia> newline() # flushes stdout\nC\n0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.parsedlm-Tuple{Any, Char}","page":"Home","title":"StaticTools.parsedlm","text":"parsedlm([T::Type], filepath::String, delimiter::Char)\n\nParse a delimited text file, given a filepath and delimiter, and return the parsed contents as a MallocMatrix{T}, that is a 2D MallocArray containing numbers of type T.\n\nIf not specified, the parse type T will default to Float64.\n\nExamples\n\njulia> using StaticTools\n\njulia> m = (1:10) * (1:10)';\n\njulia> fp = fopen(c\"testfile.tsv\", c\"w\"); printf(fp, m); fclose(fp);\n\njulia> parsedlm(Int32, c\"testfile.tsv\", '\t')\n10×10 MallocMatrix{Int32}:\n  1   2   3   4   5   6   7   8   9   10\n  2   4   6   8  10  12  14  16  18   20\n  3   6   9  12  15  18  21  24  27   30\n  4   8  12  16  20  24  28  32  36   40\n  5  10  15  20  25  30  35  40  45   50\n  6  12  18  24  30  36  42  48  54   60\n  7  14  21  28  35  42  49  56  63   70\n  8  16  24  32  40  48  56  64  72   80\n  9  18  27  36  45  54  63  72  81   90\n 10  20  30  40  50  60  70  80  90  100\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.perror-Tuple{MallocString}","page":"Home","title":"StaticTools.perror","text":"perror(s)\n\nPrint the string s to the standard error filestream, stderr.\n\nReturns 0 on success.\n\nExamples\n\njulia> StaticTools.perror(c\"ERROR: could not do thing\n\")\nERROR: could not do thing\n0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.printf-Tuple{MallocString}","page":"Home","title":"StaticTools.printf","text":"printf([fp::Ptr{FILE}], [fmt], s)\n\nLibc printf function, accessed by direct llvmcall.\n\nPrints a string s (specified either as a raw Ptr{UInt8} to a valid null-terminated string in memory or else a string type such as StaticString or MallocString for which a valid pointer can be obtained) to a filestream specified by the file pointer fp, defaulting to the current standard output stdout if not specified.\n\nOptionally, a C-style format specifier string fmt may be provided as well.\n\nReturns the number of characters printed on success.\n\nExamples\n\njulia> printf(c\"Hello there!\n\")\nHello there!\n13\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.printf-Tuple{T} where T<:Union{Number, Ptr}","page":"Home","title":"StaticTools.printf","text":"printf([fp::Ptr{FILE}], [fmt], n::Number)\n\nLibc printf function, accessed by direct llvmcall.\n\nPrints a number n to a filestream specified by the file pointer fp, defaulting to the current standard output stdout if not specified.\n\nOptionally, a C-style format specifier string fmt may be provided as well.\n\nReturns 0 on success.\n\nExamples\n\njulia> printf(1)\n1\n0\n\njulia> printf(1/3)\n3.333333e-01\n0\n\njulia> printf(c\"%f\n\", 1/3)\n0.333333\n0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.printf-Union{Tuple{AbstractVector{T}}, Tuple{T}} where T<:Union{Number, Ptr, StaticString}","page":"Home","title":"StaticTools.printf","text":"printf([fp::Ptr{FILE}], a::AbstractArray{<:Number})\n\nPrint a matrix or vector of numbers a to a filestream specified by the file pointer fp, defaulting to the current standard output stdout if not specified.\n\nReturns 0 on success.\n\nExamples\n\njulia> printf(rand(5,5))\n5.500186e-02    8.425572e-01    3.871220e-01    5.442254e-01    5.990694e-02\n5.848425e-01    6.714915e-01    5.616896e-01    6.668248e-01    2.643873e-01\n9.156712e-01    1.276033e-01    3.350369e-01    6.513146e-01    9.999104e-01\n3.301038e-01    6.027120e-01    5.139433e-01    2.219796e-01    4.057417e-01\n2.821340e-01    9.258760e-01    7.950481e-01    1.152236e-01    7.949463e-01\n0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.putchar-Tuple{Char}","page":"Home","title":"StaticTools.putchar","text":"putchar([fp::Ptr{FILE}], c::Union{Char,UInt8})\n\nLibc putchar / fputc function, accessed by direct llvmcall.\n\nPrints a single character c (either a Char or a raw UInt8) to a file pointer fp, defaulting to the current standard output stdout if not specified.\n\nReturns 0 on success.\n\nExamples\n\njulia> putchar('C')\n0\n\njulia> putchar(0x63)\n0\n\njulia> putchar('\n') # Newline, flushes stdout\nCc\n0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.puts-Tuple{Union{MallocString, MallocArray}}","page":"Home","title":"StaticTools.puts","text":"puts([fp::Ptr{FILE}], s)\n\nLibc puts/fputs function, accessed by direct llvmcall.\n\nPrints a string s (specified either as a raw Ptr{UInt8} to a valid null-terminated string in memory or elseor else a string type such as StaticString or MallocString for which a valid pointer can be obtained) followed by a newline () to a filestream specified by the file pointer fp, defaulting to the current standard output stdout if not specified.\n\nReturns 0 on success.\n\nExamples\n\njulia> puts(c\"Hello there!\")\nHello there!\n0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.splitmix64","page":"Home","title":"StaticTools.splitmix64","text":"splitmix64([rng::SplitMix64])\n\nA StaticCompiler-safe (non-allocating) implementation of the SplitMix64 deterministic pseudorandom number generator.\n\nSee also:\n\nSplitMix64, rand\n\nExamples\n\njulia> seed = StaticTools.time() # Pick a seed\n1649890154\n\njulia> rng = SplitMix64(seed) # Initialize the generator\nSplitMix64{Int64}((1649890154,))\n\njulia> splitmix64(rng) # Draw a pseudorandom `UInt64` from the generator\n0xca764ac7b7ea31e8\n\njulia> rand(rng) # Draw a `Float64` between 0 and 1\n0.8704883051360292\n\n\n\n\n\n","category":"function"},{"location":"#StaticTools.static_rng","page":"Home","title":"StaticTools.static_rng","text":"static_rng([seed::Bits64])\n\nInitialize a StaticCompiler-safe (non-allocating) deterministic pseudorandom number generator, optionally specifying a 64-bit seed (which may be any 64-bit primitive numeric type – that is, Float64, Int64, or UInt64).\n\nIn particular, static_rng uses the specified seed value (or if not specified, the current result of StaticTools.time()) to initialize a simple SplitMix64 generator, which is then in turn used to bootstrap the larger seed required for a Xoshiro256✴︎✴︎ generator.\n\nExamples\n\njulia> rng = static_rng()\nXoshiro256✴︎✴︎{UInt64}((0x2d4c7aa97cc1a621, 0x63460fc58ff25249, 0x81498572d44bd2ec, 0x2d4e96d3a7e9fdd2))\n\njulia> rand(rng) # Draw a `Float64` between 0 and 1\n0.6577585429879329\n\njulia> rand(rng)\n0.4711097758403277\n\n\n\n\n\n","category":"function"},{"location":"#StaticTools.stderrp-Tuple{}","page":"Home","title":"StaticTools.stderrp","text":"stderrp()\n\nZero-argument function which returns a raw pointer to the current standard error filestream, stderr.\n\nExamples\n\njulia> stderrp()\nPtr{StaticTools.FILE} @0x00007fffc92b9240\n\njulia> printf(stderrp(), c\"Hi there!\n\")\nHi there!\n10\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.stdinp-Tuple{}","page":"Home","title":"StaticTools.stdinp","text":"stdinp()\n\nZero-argument function which returns a raw pointer to the current standard input filestream, stdin.\n\nExamples\n\njulia> stdinp()\nPtr{StaticTools.FILE} @0x00007fffc92b9110\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.stdoutp-Tuple{}","page":"Home","title":"StaticTools.stdoutp","text":"stdoutp()\n\nZero-argument function which returns a raw pointer to the current standard output filestream, stdout.\n\nExamples\n\njulia> stdoutp()\nPtr{StaticTools.FILE} @0x00007fffc92b91a8\n\njulia> printf(stdoutp(), c\"Hi there!\n\")\nHi there!\n10\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.strlen-Tuple{Union{MallocString, MallocArray}}","page":"Home","title":"StaticTools.strlen","text":"strlen(s)\n\nLibc strlen function, accessed by direct StaticCompiler-safe llvmcall.\n\nReturns the length in bytes of the null-terminated string s, not counting the terminating null character.\n\nExamples\n\njulia> strlen(\"foo\") # Not documented, but Julia strings are null-terminated in practice every time I've checked\n3\n\njulia> strlen(c\"foo\")\n3\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.strtod-Tuple{Union{MallocString, MallocArray}}","page":"Home","title":"StaticTools.strtod","text":"strtod(s)\n\nLibc strtod function, accessed by direct StaticCompiler-safe llvmcall.\n\nReturns a Float64 (\"double\") containing the number written out in decimal form in null-terminated string s.\n\nExamples\n\njulia> num, pbuf = StaticTools.strtod(c\"3.1415\")\n(3.1415, ManualMemory.MemoryBuffer{1, Ptr{UInt8}}((Ptr{UInt8} @0x000000010aeee946,)))\n\njulia> num, pbuf = StaticTools.strtod(c\"5\")\n(5.0, ManualMemory.MemoryBuffer{1, Ptr{UInt8}}((Ptr{UInt8} @0x000000010d8f2bb1,)))\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.strtol-Tuple{Union{MallocString, MallocArray}}","page":"Home","title":"StaticTools.strtol","text":"strtol(s)\n\nLibc strtol function, accessed by direct StaticCompiler-safe llvmcall.\n\nReturns an Int64 (\"long\") containing the number written out in decimal form in null-terminated string s.\n\nExamples\n\njulia> num, pbuf = StaticTools.strtol(c\"3.1415\")\n(3, ManualMemory.MemoryBuffer{1, Ptr{UInt8}}((Ptr{UInt8} @0x000000010dd827f1,)))\n\njulia> num, pbuf = StaticTools.strtol(c\"5\")\n(5, ManualMemory.MemoryBuffer{1, Ptr{UInt8}}((Ptr{UInt8} @0x000000015dbdda41,)))\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.strtoul-Tuple{Union{MallocString, MallocArray}}","page":"Home","title":"StaticTools.strtoul","text":"strtoul(s)\n\nLibc strtol function, accessed by direct StaticCompiler-safe llvmcall.\n\nReturns an UInt64 (\"unsigned long\") containing the number written out in decimal form in null-terminated string s.\n\nExamples\n\njulia> num, pbuf = StaticTools.strtoul(c\"3.1415\")\n(0x0000000000000003, ManualMemory.MemoryBuffer{1, Ptr{UInt8}}((Ptr{UInt8} @0x000000010d6976a1,)))\n\njulia> num, pbuf = StaticTools.strtoul(c\"5\")\n(0x0000000000000005, ManualMemory.MemoryBuffer{1, Ptr{UInt8}}((Ptr{UInt8} @0x000000015ed45d11,)))\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.system-Tuple{Union{MallocString, MallocArray}}","page":"Home","title":"StaticTools.system","text":"system(s)\n\nLibc system function, accessed by direct StaticCompiler-safe llvmcall.\n\nPass the null-terminated string (or pointer thereto) s to the libc system function for evaluation.\n\nReturns 0 on success.\n\nExamples\n\njulia> StaticTools.system(c\"time echo hello\")\nhello\n\nreal    0m0.001s\nuser    0m0.000s\nsys 0m0.000s\n0\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.time-Tuple{}","page":"Home","title":"StaticTools.time","text":"time()\n\nLibc time function, accessed by direct StaticCompiler-safe llvmcall.\n\nReturn, as an Int64, the current time in seconds since the beginning of the current Unix epoch on 00:00:00 UTC, January 1, 1970.\n\nExamples\n\njulia> StaticTools.time()\n1651105298\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.xoshiro256✴︎✴︎-Tuple{Xoshiro256✴︎✴︎}","page":"Home","title":"StaticTools.xoshiro256✴︎✴︎","text":"xoshiro256✴︎✴︎(rng::Xoshiro256✴︎✴︎)\n\nA StaticCompiler-safe (non-allocating) implementation of the Xoshiro256✴︎✴︎ deterministic pseudorandom number generator, written in LLVM IR and invoked via llvmcall.\n\nSee also:\n\nXoshiro256✴︎✴︎, static_rng, rand\n\nExamples\n\njulia> seed = (0x9b134eccd2e63538, 0xd74ab64b2c3ecc9b, 0x70ba9c07628c27bf, 0x270a2eb658e6130b);\n\njulia> rng = Xoshiro256✴︎✴︎(seed) # Initialize the generator\nXoshiro256✴︎✴︎{UInt64}((0x9b134eccd2e63538, 0xd74ab64b2c3ecc9b, 0x70ba9c07628c27bf, 0x270a2eb658e6130b))\n\njulia> xoshiro256✴︎✴︎(rng) # Draw a pseudorandom `UInt64` from the generator\n0x11059b6384fba06a\n\njulia> rand(rng) # Draw a `Float64` between 0 and 1\n0.9856766307398369\n\n\n\n\n\n","category":"method"},{"location":"#StaticTools.@c_str-Tuple{Any}","page":"Home","title":"StaticTools.@c_str","text":"@c_str -> StaticString\n\nConstruct a StaticString, such as c\"Foo\".\n\nA StaticString should generally behave like a base Julia String, but is explicitly null-terminated, mutable, and standalone-StaticCompiler safe (does not require libjulia).\n\nExamples\n\njulia> c\"Hello there!\"\nc\"Hello there!\"\n\njulia> c\"foo\" == \"foo\"\ntrue\n\n\n\n\n\n","category":"macro"},{"location":"#StaticTools.@m_str-Tuple{Any}","page":"Home","title":"StaticTools.@m_str","text":"@m_str -> MallocString\n\nConstruct a MallocString, such as m\"Foo\".\n\nA MallocString should generally behave like a base Julia String, but is explicitly null-terminated, mutable, standalone-StaticCompiler-safe (does not require libjulia) and is backed by mallocd memory which is not tracked by the GC and should be freed when no longer in use.\n\nExamples\n\njulia> s = m\"Hello there!\"\nm\"Hello there!\"\n\njulia> s == \"Hello there!\"\ntrue\n\njulia> free(s)\n0\n\n\n\n\n\n","category":"macro"}]
}
