# Process any ASCII escape sequences in a raw string captured by string macro
function _unsafe_unescape!(c)
    n = ncodeunits(c)
    a = Base.unsafe_wrap(Array, pointer(c)::Ptr{UInt8}, n)
    i = 1
    while i < n # A backslash in the final position has nothing to escape
        if a[i] == 0x5c # \
            x = a[i+1]
            if x == 0x30 # \0
                a[i] = 0x00
            elseif x == 0x61 # \a
                a[i] = 0x07
            elseif x == 0x62 # \b
                a[i] = 0x08
            elseif x == 0x66 # \f
                a[i] = 0x0c
            elseif x == 0x6e # \n
                a[i] = 0x0a
            elseif x == 0x72 # \r
                a[i] = 0x0d
            elseif x == 0x74 # \t
                a[i] = 0x09
            elseif x == 0x76 # \v
                a[i] = 0x0b
            elseif x == 0x5c # \\
                a[i] = 0x5c
            elseif x == 0x27 # \'
                a[i] = 0x27
            elseif x == 0x22 # \"
                a[i] = 0x22
            else
                i += 1
                continue
            end
            n = _advance!(a, i+1, n)
        end
        i += 1
    end
    return n
end

@inline function _advance!(a::AbstractArray{UInt8}, i::Int, n::Int)
    copyto!(a, i, a, i+1, n-i)
    a[n] = 0x00
    n -= 1
end
