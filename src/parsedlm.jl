
"""
```julia
parsedlm([T::Type], filepath::String, delimiter::Char)
```

Parse a delimited text file, given a `filepath` and `delimiter`, and return the
parsed contents as a `MallocMatrix{T}`, that is a 2D `MallocArray` containing
numbers of type `T`.

If not specified, the parse type `T` will default to `Float64`.

## Examples
```julia
julia> using StaticTools

julia> m = (1:10) * (1:10)';

julia> fp = fopen(c"testfile.tsv", c"w"); printf(fp, m); fclose(fp);

julia> parsedlm(Int32, c"testfile.tsv", '\t')
10×10 MallocMatrix{Int32}:
  1   2   3   4   5   6   7   8   9   10
  2   4   6   8  10  12  14  16  18   20
  3   6   9  12  15  18  21  24  27   30
  4   8  12  16  20  24  28  32  36   40
  5  10  15  20  25  30  35  40  45   50
  6  12  18  24  30  36  42  48  54   60
  7  14  21  28  35  42  49  56  63   70
  8  16  24  32  40  48  56  64  72   80
  9  18  27  36  45  54  63  72  81   90
 10  20  30  40  50  60  70  80  90  100
```
"""
@inline parsedlm(source, delimiter::Char) = parsedlm(Float64, source, delimiter::Char)
@inline function parsedlm(::Type{T}, filepath::AbstractString, delimiter::Char) where {T}
	str = read(filepath, MallocString)
	importedmatrix = parsedlmstr(T, str, delimiter)
	free(str)
	return importedmatrix
end
@inline function parsedlm(::Type{T}, fp::Ptr{FILE}, delimiter::Char) where {T}

	if fp == C_NULL
		error(c"File does not exist!")
		return MallocMatrix{T}(undef, 0, 0)
	end

	delim = delimiter % Int32
	chars, rows, columns = 0, 0, 0
	maxcolumns, maxchars = 0, 0

	# Determine maximum number of characters per row, delimiters per row, and rows
	@inbounds while (c = getc(fp)) > 0
		chars += 1
		c == delim && (columns += 1)
		if c == 10 #Int32('\n')
			rows += 1
			# If there is a trailing delimiter, don't add an extra column for it
			fseek(fp, -2)
			getc(fp) != delim && (columns += 1)
			fseek(fp, +1)
			# See if we have a new maximum, and reset the counters
			chars > maxchars && (maxchars = chars)
			columns > maxcolumns && (maxcolumns = columns)
			chars, columns = 0, 0
		end
	end
	# If the last line isn't blank, add one more to the row counter
	fseek(fp, -1)
	getc(fp) != Int32('\n') && (rows += 1)
	frewind(fp)

	# If file starts with \ufeff, ignore it (with warning)
	c1, c2 = getc(fp), getc(fp)
	if c1 == 0xfe && c2 == 0xff
		warn(c"Skipping hidden U+FEFF character at start of input file.\n")
	else
		frewind(fp)
	end

	# # if debug
	# printf(c"Maximum number of characters: %d\n", maxchars)
	# printf(c"Maximum number of delimiters: %d\n", maxcolumns)
	# printf(c"Number of rows: %d\n", rows)

	# Allocate space for the imported array
	importedmatrix = MallocMatrix{T}(undef, rows, maxcolumns)
	field = MallocVector{Int}(undef, maxcolumns+2)
	str = MallocString(undef, maxchars+2)

	# For each line,
	i = 1
	@inbounds while gets!(str,fp) != C_NULL

		# identify the delimited fields,
		field[1] = 0
		k, columns = 1, 1
		while str[k] != 0x00 #UInt8('\0')
			if str[k] == UInt8(delim)
				str[k] = '\0'
				columns += 1
				field[columns] = k
			elseif str[k] == UInt8('\n')
				str[k] = '\0'
			end
			k += 1
		end

		# and perform operations on each field
		for j = 1:maxcolumns
			importedmatrix[i,j] = parse(T, pointer(str) + field[j])
		end
		i += 1
	end
	free(str)
	free(field)

	return importedmatrix
end

@inline function parsedlmstr(::Type{T}, str::AbstractString, delimiter::Char) where {T}

	delim = delimiter % UInt8
	rows, columns, maxcolumns = 0, 0, 0

	# Determine maximum number of characters per row, delimiters per row, and rows
	@inbounds for i=1:length(str)
		c = str[i]
		c == delim && (columns += 1)
		if c == 0x0a
			rows += 1
			# If there is a trailing delimiter, don't add an extra column for it
			str[i-1] != delim && (columns += 1)

			# See if we have a new maximum, and reset the counters
			columns > maxcolumns && (maxcolumns = columns)
			columns = 0
		end
	end
	# If the last line isn't blank, add one more to the row counter
	str[end-1] != 0x0a && (rows += 1)

	# # if debug
	# printf(c"Maximum number of characters: %d\n", maxchars)
	# printf(c"Maximum number of delimiters: %d\n", maxcolumns)
	# printf(c"Number of rows: %d\n", rows)

	# Allocate space for the imported array
	importedmatrix = MallocMatrix{T}(undef, rows, maxcolumns)
	field = MallocVector{Int}(undef, maxcolumns)

	# For each line,
	k = 1
	if str[1] == 0xfe && str[2] == 0xff
		warn(c"Skipping hidden U+FEFF character at start of input file.\n")
		k += 2
	end
	@inbounds for i ∈ 1:rows

		# identify the delimited fields,
		field[1] = k-1
		columns = 1
		while str[k] != 0x0a
			if str[k] == delim
				str[k] = 0x00
				columns += 1
				field[columns] = k
			end
			k += 1
		end

		# and perform operations on each field
		for j = 1:maxcolumns
			importedmatrix[i,j] = parse(T, pointer(str) + field[j])
		end
		k += 1
	end
	free(field)

	return importedmatrix
end
