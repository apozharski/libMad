function obj(stats::MadNLPCExecutionStats{T})::T where {T}
    return stats.objective
end

function solution(stats::MadNLPCExecutionStats{T, VT})::VT where {T,VT}
    return stats.solution
end

function constraints(stats::MadNLPCExecutionStats{T, VT})::VT where {T,VT}
    return stats.constraints
end

function multipliers(stats::MadNLPCExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers
end

function multipliers_L(stats::MadNLPCExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers_L
end

function multipliers_U(stats::MadNLPCExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers_U
end

function multipliers_x1(stats::MadNLPCExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers_x1
end

function multipliers_x2(stats::MadNLPCExecutionStats{T, VT})::VT where {T,VT}
    return stats.multipliers_x2
end

function get_n(stats::MadNLPCExecutionStats)::Int
    return length(stats.solution)
end

function get_m(stats::MadNLPCExecutionStats)::Int
    return length(stats.constraints)
end

function get_ncc(stats::MadNLPCExecutionStats)::Int
    return length(stats.multipliers_x1)
end

function success(stats::MadNLPCExecutionStats{T, VT}) where {T,VT}
    return MadNLP.SOLVE_SUCCEEDED <= stats.status <= MadNLP.SOLVED_TO_ACCEPTABLE_LEVEL
    # TODO SEARCH_DIRECTION_BECOMES_TOO_SMALL is not technically a success but might be
end

function iters(stats::MadNLPCExecutionStats)
    return stats.iter
end

function primal_feas(stats::MadNLPCExecutionStats{T}) where T
    return stats.primal_feas
end

function dual_feas(stats::MadNLPCExecutionStats{T}) where T
    return stats.dual_feas
end

function cc_feas(stats::MadNLPCExecutionStats{T}) where T
    return stats.inf_pr_cc
end

function status(stats::MadNLPCExecutionStats)
    return Clonglong(stats.status)
end
