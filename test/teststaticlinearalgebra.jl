a = sones(10)
b = sones(10,1)
c = sones(1,10)
A = sones(10,10)
B = sones(10,10)

# Scalar multiplication
@test a * 5 == 5 * a == fill(5,10)
@test A * 5 == 5 * A == fill(5,10,10)

# Vector-Vector multiplication
@test a * c isa StackMatrix
@test a * c == A
@test b * c isa StackMatrix
@test b * c == A
@test c * b == fill(10,1,1)
@test c * a == fill(10,1,1)

# Vector-Matrix multiplication
@test A * a isa StackMatrix
@test A * a == fill(10.0,10,1)
@test c * A isa StackMatrix
@test c * A == fill(10.0,1,10)

# Matrix-matrix multiplication
@test A * B isa StackMatrix
@test A * B == fill(10.0,10,10)
