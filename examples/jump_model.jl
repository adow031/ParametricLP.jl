## This example is based on the model used to illustrate JuMP's sensitivity report
## https://jump.dev/JuMP.jl/stable/tutorials/linear/lp_sensitivity/

using HiGHS, Plots, ParametricLP, JuMP

model = Model(HiGHS.Optimizer)
set_silent(model)
@variable(model, x >= 0)
@variable(model, 0 <= y <= 3)
@variable(model, z <= 1)
@variable(model, p[1:2])
@objective(model, Min, 12x + 20y - z)
@constraint(model, c1, 6x + 8y >= p[1])
@constraint(model, c2, 7x + 12y >= p[2])
@constraint(model, c3, x + y <= 20)

box = ((0.0, 150.0), (0.0, 155.0))

regions, πs = find_regions(model, p, box)

clims = (minimum([min(π[c1], π[c2]) for π in πs]), maximum([max(π[c1], π[c2]) for π in πs]))

p1 = plot(
    [Shape(r) for r in regions],
    fill_z = permutedims([π[c1] for π in πs]),
    legend = false,
    colorbar = false,
    clims = clims,
    color = cgrad([:green, :yellow, :red]),
);

p2 = plot(
    [Shape(r) for r in regions],
    fill_z = permutedims([π[c2] for π in πs]),
    legend = false,
    colorbar = false,
    clims = clims,
    color = cgrad([:green, :yellow, :red]),
);

h1 = scatter(
    [0, 0],
    [1, 1],
    zcolor = collect(clims),
    xlims = (1, 1.1),
    label = "",
    yshowaxis = false,
    c = cgrad([:green, :yellow, :red]),
    framestyle = :none,
);

l = @layout [grid(1, 2) a{0.06w}]
plot(p1, p2, h1, layout = l, size = (940, 380), link = :all)
