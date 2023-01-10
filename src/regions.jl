function find_region(
    model::JuMP.Model,
    parameters::Vector{VariableRef},
    box::Tuple{Tuple{Float64,Float64},Tuple{Float64,Float64}},
    point::Tuple{Float64,Float64},
    ϵ = 0.01,
)
    fix(parameters[1], point[1])
    fix(parameters[2], point[2])

    optimize!(model)

    if termination_status(model) != MOI.OPTIMAL
        unfix(parameters[1])
        unfix(parameters[2])
        return Tuple{Float64,Float64}[], Tuple{Float64,Float64}[], Dict()
    end
    sfm = JuMP._standard_form_matrix(model)
    sfb = JuMP._standard_form_basis(model, sfm)
    cons = all_constraints(model, include_variable_in_set_constraints = false)

    π = Dict(zip(cons, dual.(cons)))

    reverselookup = Dict{Int,VariableRef}()
    bounds = Dict{Int,Tuple{Float64,Float64}}()
    newcons = ConstraintRef[]
    for index in eachindex(sfm.bounds)
        reverselookup[index] = JuMP.constraint_object(sfm.bounds[index]).func
    end

    vars = all_variables(model)
    solution = Dict(zip(vars, value.(vars)))
    for i in eachindex(sfb.bounds)
        if sfb.bounds[i] != MathOptInterface.BASIC && reverselookup[i] ∉ parameters
            var = reverselookup[i]
            lb = has_lower_bound(var) ? lower_bound(var) : -Inf
            ub = has_upper_bound(var) ? upper_bound(var) : Inf
            bounds[i] = (lb, ub)

            fix(var, solution[var], force = true)
        end
    end

    for i in eachindex(sfb.constraints)
        if sfb.constraints[i] != MathOptInterface.BASIC
            constr_set = MOI.get(model, MOI.ConstraintSet(), sfm.constraints[i])
            rhs = nothing
            if typeof(constr_set) <: MOI.GreaterThan
                rhs = constr_set.lower
            elseif typeof(constr_set) <: MOI.LessThan
                rhs = constr_set.upper
            end

            if rhs !== nothing
                con = @constraint(model, 0 == rhs)

                for (var, val) in JuMP.constraint_object(sfm.constraints[i]).func.terms
                    set_normalized_coefficient(con, var, val)
                end
                push!(newcons, con)
            end
        end
    end

    unfix(parameters[1])
    unfix(parameters[2])
    set_lower_bound(parameters[1], box[1][1])
    set_upper_bound(parameters[1], box[1][2])
    set_lower_bound(parameters[2], box[2][1])
    set_upper_bound(parameters[2], box[2][2])
    original_obj = objective_function(model)

    corners = Tuple{Float64,Float64}[]

    for sgn in [-1, 1]
        for direction in [:pos, :neg]
            nextvalue = 0.0
            while true
                @objective(model, Min, nextvalue * parameters[1] + sgn * parameters[2])
                optimize!(model)
                if termination_status(model) == MOI.OPTIMAL
                    push!(corners, Tuple(value.(parameters)))
                    report = JuMP.lp_sensitivity_report(model)
                    if direction == :pos && report.objective[parameters[1]][2] != Inf
                        nextvalue += report.objective[parameters[1]][2] + ϵ
                    elseif direction == :neg && report.objective[parameters[1]][1] != -Inf
                        nextvalue += report.objective[parameters[1]][1] - ϵ
                    else
                        break
                    end
                else
                    break
                end
            end
        end
    end
    unique!(fix_minus_zero, corners)
    if length(corners) == 1
        seeds = [
            (corners[1][1] + ϵ * i[1], corners[1][2] + ϵ * i[2]) for
            i in [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        ]
    else
        c =
            (
                sum(corners[i][1] for i in eachindex(corners)),
                sum(corners[i][2] for i in eachindex(corners)),
            ) ./ length(corners)
        sort!(
            corners,
            lt = (x, y) -> atan(x[1] - c[1], x[2] - c[2]) < atan(y[1] - c[1], y[2] - c[2]),
        )

        offsets = [
            (
                (corners[i][2] - corners[i%length(corners)+1][2]),
                (corners[i%length(corners)+1][1] - corners[i][1]),
            ) .* (
                ϵ / sqrt(
                    (corners[i][1] - corners[i%length(corners)+1][1])^2 +
                    (corners[i%length(corners)+1][2] - corners[i][2])^2,
                )
            ) for i in eachindex(corners)
        ]

        seeds = [
            (
                corners[i][1] + corners[i%length(corners)+1][1] + 2 * offsets[i][1],
                corners[i][2] + corners[i%length(corners)+1][2] + 2 * offsets[i][2],
            ) ./ 2 for i in eachindex(corners)
        ]
    end

    for c in newcons
        delete(model, c)
    end

    for (index, bound) in bounds
        var = reverselookup[index]
        unfix(var)
        if bound[1] != -Inf
            set_lower_bound(var, bound[1])
        end
        if bound[2] != Inf
            set_upper_bound(var, bound[2])
        end
    end

    delete_lower_bound(parameters[1])
    delete_upper_bound(parameters[1])
    delete_lower_bound(parameters[2])
    delete_upper_bound(parameters[2])

    set_objective(model, MOI.MIN_SENSE, original_obj)

    return corners, seeds, π
end

"""
    find_regions(
        model::JuMP.Model,
        parameters::Vector{VariableRef},
        box::Tuple{Tuple{Float64,Float64},Tuple{Float64,Float64}},
        ϵ = 0.01,
    )

This function finds all the optimal bases and their corresponding regions in terms of two `parameters` in a linear programming `model`.

### Required arguments
`model` is a `JuMP.Model` linear programme, defined in a way where two of the right-hand side values are replaced by variables.

`parameters` is a vector of two variables that appear on the right-hand side of the two constraints that we wish to explore parametrically.

`box` is a Tuple of Tuples, this defines the minimum and maximum value for each of the `parameters` described above.

### Optional arguments
`ϵ` is a tolerance value used when ensuring that we find an adjacent basis.
"""
function find_regions(
    model::JuMP.Model,
    parameters::Vector{VariableRef},
    box::Tuple{Tuple{Float64,Float64},Tuple{Float64,Float64}},
    ϵ = 0.01,
)
    πs = []
    regions = Vector{Tuple{Float64,Float64}}[]
    seeds_list = [
        (box[1][1], box[2][1]),
        (box[1][2], box[2][1]),
        (box[1][2], box[2][2]),
        (box[1][1], box[2][2]),
    ]

    while length(seeds_list) > 0
        seed = pop!(seeds_list)
        duplicate =
            !insidePolygon(
                [
                    (box[1][1], box[2][1]),
                    (box[1][2], box[2][1]),
                    (box[1][2], box[2][2]),
                    (box[1][1], box[2][2]),
                ],
                seed,
            )
        if duplicate == false
            for i in eachindex(regions)
                if insidePolygon(regions[i], seed)
                    duplicate = true
                    break
                end
            end
            if !duplicate
                corners, seeds, π = find_region(model, parameters, box, seed, ϵ)
                if length(corners) != 0
                    push!(regions, corners)
                    push!(πs, π)
                    seeds_list = [seeds_list; seeds]
                end
            end
        end
    end
    return regions, πs
end
