using EMD, Test

run(ys) = (emdrice(ys), emd(ys))

@testset "Sin" begin
    let
        xs = range(0, 2π; length=200)
        ys = sin.(xs)
        expected, got = run(ys)
        @test length(expected[1]) == length(got[1])
        for (e, g) in zip(expected[1], got[1])
            @test all(g .≈ e)
        end
        @test all(got[2] .≈ expected[2])
    end
end
