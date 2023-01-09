using HiGHS, Plots, ParametricLP, JuMP

function get_model(line_capacity::Float64)
    model = JuMP.Model(HiGHS.Optimizer)
    set_silent(model)

    @variable(model, x >= 0)
    @variable(model, y >= 0)
    @variable(model, -line_capacity <= f <= line_capacity)
    @variable(model, p[1:2])
    @variable(model, 0 <= T[1:3, 1:2] <= 1)

    nd1 = @constraint(model, sum(T[i, 1] for i in 1:3) + x - f == 3)
    nd2 = @constraint(model, sum(T[i, 2] for i in 1:3) + y + f == 2)

    @constraint(model, x <= p[1])
    @constraint(model, y <= p[2])

    @objective(model, Min, sum((i + (j - 1) / 2) * T[i, j] for i in 1:3, j in 1:2))

    return model, p, [nd1, nd2]
end

model, p, cons = get_model(0.5)

box = ((0.0, 4.0), (0.0, 4.0))

regions, πs = find_regions(model, p, box)

clims = (
    minimum([min(π[cons[1]], π[cons[2]]) for π in πs]),
    maximum([max(π[cons[1]], π[cons[2]]) for π in πs]),
)

p1 = plot(
    [Shape(r) for r in regions],
    fill_z = permutedims([π[cons[1]] for π in πs]),
    legend = false,
    colorbar = false,
    clims = clims,
    color = cgrad([:grey, :yellow, :red]),
);

p2 = plot(
    [Shape(r) for r in regions],
    fill_z = permutedims([π[cons[2]] for π in πs]),
    legend = false,
    colorbar = false,
    clims = clims,
    color = cgrad([:grey, :yellow, :red]),
);

h1 = scatter(
    [0, 0],
    [1, 1],
    zcolor = collect(clims),
    xlims = (1, 1.1),
    label = "",
    yshowaxis = false,
    c = cgrad([:grey, :yellow, :red]),
    framestyle = :none,
);

l = @layout [grid(1, 2) a{0.06w}]
plot(p1, p2, h1, layout = l, size = (940, 380), link = :all)
