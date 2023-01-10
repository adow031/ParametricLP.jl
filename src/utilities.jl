function insidePolygon(corners, point)
    check_sign = 0.0
    if length(corners) == 1
        if point[1] != corners[1][1] || point[2] != corners[1][2]
            return false
        else
            return true
        end
    end
    for k in eachindex(corners)
        if k == length(corners)
            current_poly = (corners[1][1] - corners[k][1], corners[1][2] - corners[k][2])
        else
            current_poly =
                (corners[k+1][1] - corners[k][1], corners[k+1][2] - corners[k][2])
        end

        point_vect = (point[1] - corners[k][1], point[2] - corners[k][2])

        current_sign = cross_product(current_poly, point_vect)

        if check_sign == 0.0
            check_sign = current_sign
        elseif check_sign != current_sign && current_sign != 0.0
            return false
        end
    end
    return true
end

function cross_product(v1::Tuple{Float64,Float64}, v2::Tuple{Float64,Float64})
    val = v1[1] * v2[2] - v1[2] * v2[1]
    # This could theoretically cause an early termination of the algorithm, but
    # in practice prevents infinite loops.
    if abs(val) < 1e-8
        val = 0.0
    end
    return sign(val)
end

function fix_minus_zero(x::Tuple{Float64,Float64})
    if x[1] == 0.0
        if x[2] == -0.0
            return (0.0, 0.0)
        else
            return (0.0, x[2])
        end
    else
        if x[2] == -0.0
            return (x[1], 0.0)
        else
            return (x[1], x[2])
        end
    end
end
