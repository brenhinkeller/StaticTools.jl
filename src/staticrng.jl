# Constructors
mutable struct StaticRNG{T}
    state::NTuple
    @inline function StaticRNG{T}(state::NTuple) where {T}
        new{T}(state)
    end
end
struct Xoshiro256✴︎✴︎ end

@inline static_rng(seed=time()) = StaticRNG{Xoshiro256✴︎✴︎}((1*seed, 2*seed, 3*seed, 4*seed))

@inline Base.rand(rng::StaticRNG{Xoshiro256✴︎✴︎}) = xoshiro256✴︎✴︎(rng)/typemax(UInt64)
# @inline Random.rand!(rng::StaticRNG, A::AbstractArray)
#     @inbounds for i ∈ A
#         A[i] = rand(rng)
#     end
# end

# Xoshiro256✴︎✴︎ PRNG implemented in LLVM IR
@inline xoshiro256✴︎✴︎(rng::StaticRNG) = GC.@preserve rng xoshiro256✴︎✴︎(Ptr{Int64}(pointer_from_objref(rng)))
@inline function xoshiro256✴︎✴︎(state::Ptr{Int64})
    Base.llvmcall(("""
    ; Function Attrs: noinline nounwind ssp uwtable
    define i64 @next(i64*) #0 {
      %2 = alloca i64*, align 8
      %3 = alloca i64, align 8
      %4 = alloca i64, align 8
      store i64* %0, i64** %2, align 8
      %5 = load i64*, i64** %2, align 8
      %6 = getelementptr inbounds i64, i64* %5, i64 1
      %7 = load i64, i64* %6, align 8
      %8 = mul i64 %7, 5
      %9 = call i64 @rotl(i64 %8, i32 7)
      %10 = mul i64 %9, 9
      store i64 %10, i64* %3, align 8
      %11 = load i64*, i64** %2, align 8
      %12 = getelementptr inbounds i64, i64* %11, i64 1
      %13 = load i64, i64* %12, align 8
      %14 = shl i64 %13, 17
      store i64 %14, i64* %4, align 8
      %15 = load i64*, i64** %2, align 8
      %16 = getelementptr inbounds i64, i64* %15, i64 0
      %17 = load i64, i64* %16, align 8
      %18 = load i64*, i64** %2, align 8
      %19 = getelementptr inbounds i64, i64* %18, i64 2
      %20 = load i64, i64* %19, align 8
      %21 = xor i64 %20, %17
      store i64 %21, i64* %19, align 8
      %22 = load i64*, i64** %2, align 8
      %23 = getelementptr inbounds i64, i64* %22, i64 1
      %24 = load i64, i64* %23, align 8
      %25 = load i64*, i64** %2, align 8
      %26 = getelementptr inbounds i64, i64* %25, i64 3
      %27 = load i64, i64* %26, align 8
      %28 = xor i64 %27, %24
      store i64 %28, i64* %26, align 8
      %29 = load i64*, i64** %2, align 8
      %30 = getelementptr inbounds i64, i64* %29, i64 2
      %31 = load i64, i64* %30, align 8
      %32 = load i64*, i64** %2, align 8
      %33 = getelementptr inbounds i64, i64* %32, i64 1
      %34 = load i64, i64* %33, align 8
      %35 = xor i64 %34, %31
      store i64 %35, i64* %33, align 8
      %36 = load i64*, i64** %2, align 8
      %37 = getelementptr inbounds i64, i64* %36, i64 3
      %38 = load i64, i64* %37, align 8
      %39 = load i64*, i64** %2, align 8
      %40 = getelementptr inbounds i64, i64* %39, i64 0
      %41 = load i64, i64* %40, align 8
      %42 = xor i64 %41, %38
      store i64 %42, i64* %40, align 8
      %43 = load i64, i64* %4, align 8
      %44 = load i64*, i64** %2, align 8
      %45 = getelementptr inbounds i64, i64* %44, i64 2
      %46 = load i64, i64* %45, align 8
      %47 = xor i64 %46, %43
      store i64 %47, i64* %45, align 8
      %48 = load i64*, i64** %2, align 8
      %49 = getelementptr inbounds i64, i64* %48, i64 3
      %50 = load i64, i64* %49, align 8
      %51 = call i64 @rotl(i64 %50, i32 45)
      %52 = load i64*, i64** %2, align 8
      %53 = getelementptr inbounds i64, i64* %52, i64 3
      store i64 %51, i64* %53, align 8
      %54 = load i64, i64* %3, align 8
      ret i64 %54
    }

    ; Function Attrs: noinline nounwind ssp uwtable
    define internal i64 @rotl(i64, i32) #0 {
      %3 = alloca i64, align 8
      %4 = alloca i32, align 4
      store i64 %0, i64* %3, align 8
      store i32 %1, i32* %4, align 4
      %5 = load i64, i64* %3, align 8
      %6 = load i32, i32* %4, align 4
      %7 = zext i32 %6 to i64
      %8 = shl i64 %5, %7
      %9 = load i64, i64* %3, align 8
      %10 = load i32, i32* %4, align 4
      %11 = sub nsw i32 64, %10
      %12 = zext i32 %11 to i64
      %13 = lshr i64 %9, %12
      %14 = or i64 %8, %13
      ret i64 %14
    }

    attributes #0 = { noinline nounwind ssp uwtable }
    """, "next"), UInt64, Tuple{Ptr{Int64}}, state)
end
