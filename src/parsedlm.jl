# Parse a CSV file, return pointer to a 2d array of doubles
@inline parsedlm(filepath, delimiter::Char) = parsedlm(Float64, filepath, delimiter::Char)
@inline function parsedlm(::Type{T}, filepath, delimiter::Char) where {T}

	# File to open
	fp = fopen(filepath, c"r")

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

	# # if debug
	# printf(c"Maximum number of characters: %d\n", maxchars)
	# printf(c"Maximum number of delimiters: %d\n", maxcolumns)
	# printf(c"Number of rows: %d\n", rows)

	# Allocate space for the imported array
	importedMatrix = MallocMatrix{T}(undef, rows, maxcolumns)
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
			importedMatrix[i,j] = parse(T, pointer(str) + field[j])
		end
		i += 1
	end
	fclose(fp)
	free(str)
	free(field)

	return importedMatrix
end
