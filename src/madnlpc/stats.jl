function obj(stats::RelaxationExecutionStats{T})::T where {T}
    return stats.objective
end

function solution(stats::RelaxationExecutionStats{T, VT})::VT where {T,VT}
    return stats.solution
end

function constraints(stats::RelaxationExecutionStats{T, VT})::VT where {T,VT}
    return stats.constraints
end

function multipliers(stats::RelaxationExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers
end

function multipliers_L(stats::RelaxationExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers_L
end

function multipliers_U(stats::RelaxationExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers_U
end

function multipliers_x1(stats::RelaxationExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers_x1
end

function multipliers_x2(stats::RelaxationExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers_x2
end

function get_n(stats::RelaxationExecutionStats)::Int
    return length(stats.solution)
end

function get_m(stats::RelaxationExecutionStats)::Int
    return length(stats.constraints)
end

function get_ncc(stats::RelaxationExecutionStats)::Int
    return length(stats.multipliers_x1)
end

function success(stats::RelaxationExecutionStats{T, VT}) where {T,VT}
    return MadNLP.SOLVE_SUCCEEDED <= stats.status <= MadNLP.SOLVED_TO_ACCEPTABLE_LEVEL
    # TODO SEARCH_DIRECTION_BECOMES_TOO_SMALL is not technically a success but might be
end

function iters(stats::RelaxationExecutionStats)
    return stats.iter
end

function primal_feas(stats::RelaxationExecutionStats{T}) where T
    return stats.primal_feas
end

function dual_feas(stats::RelaxationExecutionStats{T}) where T
    return stats.dual_feas
end

function cc_feas(stats::RelaxationExecutionStats{T}) where T
    return stats.inf_pr_cc
end

function status(stats::RelaxationExecutionStats)
    return Clonglong(stats.status)
end
