using Test, ParametricLP, JuMP, HiGHS

function get_model()
    model = JuMP.Model(HiGHS.Optimizer)
    set_silent(model)

    @variable(model, x >= 0)
    @variable(model, y >= 0)
    @variable(model, p[1:2])
    @variable(model, 0 <= T[1:3] <= 1)

    con = @constraint(model, sum(T[i] for i in 1:3) + x + y == 5)

    @constraint(model, x <= p[1])
    @constraint(model, y <= p[2])

    @objective(model, Min, sum(i * T[i] for i in 1:3))

    return model, p, con
end

model, p, con = get_model()
box = ((0.0, 4.0), (0.0, 4.0))
regions, πs = find_regions(model, p, box)

@testset "Utility Tests" begin
    @test ParametricLP.insidePolygon([(0.0, 0.0), (1.0, 0.0), (0.0, 1.0)], (0.25, 0.25)) ==
          true
    @test ParametricLP.insidePolygon([(0.0, 0.0), (1.0, 0.0), (0.0, 1.0)], (0.6, 0.25)) ==
          true
    @test ParametricLP.insidePolygon([(0.0, 0.0), (1.0, 0.0), (0.0, 1.0)], (0.8, 0.25)) ==
          false
    @test ParametricLP.cross_product((1.0, 0.2), (-0.5, 0.5)) == 1.0
    @test ParametricLP.cross_product((1.0, 0.2), (0.5, -0.5)) == -1.0
    @test ParametricLP.cross_product((1.0, 0.2), (0.5, 0.1)) == 0.0
end

@testset "Region Tests" begin
    @test length(regions) == 4
    @test πs[1][con] == 1.0
    @test πs[2][con] == 2.0
    @test πs[3][con] == 3.0
    @test πs[4][con] == 0.0
    @test sum([v[1] + v[2] for v in regions[1]]) == 18.0
    @test sum([v[1] + v[2] for v in regions[3]]) == 10.0
end
