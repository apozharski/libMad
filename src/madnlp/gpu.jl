
# TODO(@anton): this is for late conversion to a gpu compatible model, this is hard to automate for each solver
#               I think so we do it manually for now. Long term (when I push through getting rid of varargs >:D)
#               we can and should just have a method use_gpu(AbstractSolverOptions).
# TODO(@anton): this is type unstable.
function gpuconvert(::Type{MadNLPSolver}, opts::OptsDict, nlp::CNLPModel)
    # TODO(@anton) is this a complete and sound list?
    if haskey(opts, "linear_solver") && opts["linear_solver"] ∈ ["CUDSSSolver", "LapackGPUSolver"]
        out = MadNLP.SparseWrapperModel(CuVector,nlp)
    else
        out = nlp
    end

    return out
end
