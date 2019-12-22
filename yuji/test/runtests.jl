using Test
include("../src/info.jl")

@testset "Transfer Entropy" begin
    let as = [2,2,2,1,1], bs = [2,2,1,1,2]
        @test abs(transferentropy(as, as, 2) - 0.0) < 1e-6
        @test abs(transferentropy(bs, bs, 2) - 0.0) < 1e-6
        @test abs(transferentropy(as, bs, 2) - 0.0) < 1e-6
        @test abs(transferentropy(bs, as, 2) - 2/3) < 1e-6
    end

    let as = [1,1,2,2,2,1,1,1,1,2]
        bs = [2,2,1,1,1,1,1,1,2,2]
        @test abs(transferentropy(as, as, 2) - 0.0) < 1e-6
        @test abs(transferentropy(bs, bs, 2) - 0.0) < 1e-6
        @test abs(transferentropy(as, bs, 2) - 0.106844) < 1e-6
        @test abs(transferentropy(bs, as, 2) - 1/2) < 1e-6
    end

    let as = [1,2,1,2,1,1,2,2,1,1]
        bs = [1,1,2,1,2,2,2,1,2,2]
        @test abs(transferentropy(as, as, 2) - 0.0) < 1e-6
        @test abs(transferentropy(bs, bs, 2) - 0.0) < 1e-6
        @test abs(transferentropy(as, bs, 2) - 1/4) < 1e-6
        @test abs(transferentropy(bs, as, 2) - 0.344361) < 1e-6
    end

    let as = [1,1,1,2,2], bs = [1,1,2,2,1]
        @test abs(transferentropy(as, as, 2) - 0.0) < 1e-6
        @test abs(transferentropy(bs, bs, 2) - 0.0) < 1e-6
        @test abs(transferentropy(as, bs, 2) - 0.0) < 1e-6
        @test abs(transferentropy(bs, as, 2) - 2/3) < 1e-6
    end

    let as = [2,2,1,1,1,2,2,2,2,1]
        bs = [1,1,2,2,2,2,2,2,1,1]
        @test abs(transferentropy(as, as, 2) - 0.0) < 1e-6
        @test abs(transferentropy(bs, bs, 2) - 0.0) < 1e-6
        @test abs(transferentropy(as, bs, 2) - 0.106844) < 1e-6
        @test abs(transferentropy(bs, as, 2) - 1/2) < 1e-6
    end

    let as = [2,1,2,1,2,2,1,1,2,2]
        bs = [2,2,1,2,1,1,1,2,1,1]
        @test abs(transferentropy(as, as, 2) - 0.0) < 1e-6
        @test abs(transferentropy(bs, bs, 2) - 0.0) < 1e-6
        @test abs(transferentropy(as, bs, 2) - 1/4) < 1e-6
        @test abs(transferentropy(bs, as, 2) - 0.344361) < 1e-6
    end

    let xs = rand(1:2, 60), ys = rand(1:2, 60)
        @time for _ in 1:810000
            mutualinfo!(MIDist(), xs, ys)
        end
    end

    let xs = rand(1:2, 60), ys = rand(1:2, 60)
        @time for _ in 1:810000
            transferentropy(xs, ys, 2)
        end
        @time for _ in 1:810000
            transferentropy(xs, ys, 3)
        end
    end
end
