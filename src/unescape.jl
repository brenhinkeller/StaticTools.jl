# Process any ASCII escape sequences in a raw string captured by string macro
function _unsafe_unescape!(c)
    n = ncodeunits(c)
    a = Base.unsafe_wrap(Array, pointer(c)::Ptr{UInt8}, n)
    for i = 1:n
        if a[i] == 0x5c # \
            if a[i+1] == 0x30 # \0
                a[i] = 0x00
                n = _advance!(a, i+1, n)
            elseif a[i+1] == 0x61 # \a
                a[i] = 0x07
                n = _advance!(a, i+1, n)
            elseif a[i+1] == 0x62 # \b
                a[i] = 0x08
                n = _advance!(a, i+1, n)
            elseif a[i+1] == 0x66 # \f
                a[i] = 0x0c
                n = _advance!(a, i+1, n)
            elseif a[i+1] == 0x6e # \n
                a[i] = 0x0a
                n = _advance!(a, i+1, n)
            elseif a[i+1] == 0x72 # \r
                a[i] = 0x0d
                n = _advance!(a, i+1, n)
            elseif a[i+1] == 0x74 # \t
                a[i] = 0x09
                n = _advance!(a, i+1, n)
            elseif a[i+1] == 0x76 # \v
                a[i] = 0x0b
                n = _advance!(a, i+1, n)
            elseif a[i+1] == 0x5c # \\
                a[i] = 0x5c
                n = _advance!(a, i+1, n)
            elseif a[i+1] == 0x27 # \'
                a[i] = 0x27
                n = _advance!(a, i+1, n)
            elseif a[i+1] == 0x22 # \"
                a[i] = 0x22
                n = _advance!(a, i+1, n)
            end
        end
    end
    return n
end

@inline function _advance!(a::AbstractArray{UInt8}, i::Int, n::Int)
    copyto!(a, i, a, i+1, n-i)
    a[n] = 0x00
    n -= 1
end
