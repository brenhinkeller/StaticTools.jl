
struct X{A,B,C}
    a::A
    b::B
    c::C
end

x = X([1,2,3], 3, "hello")
xt = static_type(x)
xtt = static_type(typeof(x))

@test xt.a isa MallocArray
@test xt.b isa Int
@test xt.c isa MallocString
@test xtt.parameters[1] == MallocVector{Int}

types, fields = static_type_contents(x)

@test types[1] == MallocVector{Int}
@test fields[1] isa MallocVector
@test fields[1][1] == 1

x = X(1, X([1,2], 1, "hello"), "hello")
xt = static_type(x)

@test xt.b.a isa MallocArray
@test xt.b.c isa MallocString


