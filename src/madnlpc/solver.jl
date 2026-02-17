# For now we don't use the macro because of the weirdness with SolverCore API
push!(dummy_structs, "MadNLPCSolver")

push!(function_sigs, "int madnlpc_create_solver(MadNLPCSolver** solver_ptr_ptr, MPCCModel* mpcc_ptr, OptsDict* nlp_opts_ptr, OptsDict* mpcc_opts_ptr)")

Base.@ccallable function madnlpc_create_solver(solver_ptr_ptr::Ptr{Ptr{Cvoid}},
                                               mpcc_ptr::Ptr{Cvoid},
                                               nlp_opts_ptr::Ptr{Cvoid},
                                               mpcc_opts_ptr::Ptr{Cvoid}
                                               )::Cint
    nlp = unsafe_pointer_to_objref(mpcc_ptr) # why doesn't this work: nlp = wrap_obj($(model),nlp_ptr)
    nlp_opts = wrap_obj(OptsDict, nlp_opts_ptr)
    mpcc_opts = wrap_obj(OptsDict, mpcc_opts_ptr)
    nlp_nt_opts = madnlp_to_parameters(nlp_opts)
    mpcc_nt_opts = madnlpc_to_parameters(mpcc_opts)

    madnlpc_opts = MadNLPCOptions{Cdouble}(;mpcc_nt_opts...)
    println("NLP Options:")
    println(nlp_nt_opts)
    solver = MadNLPCSolver(
        nlp;
        solver_opts=madnlpc_opts,
        nlp_nt_opts...
            )

    solver_ptr = pointer_from_objref(solver)
    unsafe_store!(solver_ptr_ptr, solver_ptr)
    libmad_refs[solver_ptr] = solver

    return Cint(0)
end

push!(function_sigs, "int madnlpc_delete_solver(MadNLPCSolver* solver_ptr)")
Base.@ccallable function madnlpc_delete_solver(solver_ptr::Ptr{Cvoid})::Cint
    if haskey(libmad_refs, solver_ptr)
        delete!(libmad_refs, solver_ptr)
        return Cint(0)
    else
        return Cint(1)
    end
end

push!(function_sigs, "int madnlpc_solve(MadNLPCSolver* solver_ptr, OptsDict* nlp_opts_ptr, MadNLPCExecutionStats** stats_ptr_ptr)")
Base.@ccallable function madnlpc_solve(solver_ptr::Ptr{Cvoid},
                                       nlp_opts_ptr::Ptr{Cvoid},
                                       stats_ptr_ptr::Ptr{Ptr{Cvoid}})::Cint
    solver = unsafe_pointer_to_objref(solver_ptr)# why doesn't this work: wrap_obj($(solver_expr), solver_ptr)
    opts = wrap_obj(OptsDict, nlp_opts_ptr)
    nt_opts = madnlp_to_parameters(opts)
    # Prealloc a stats so we always set a stats_ptr even on rethrown error,
    # TODO(@anton): we should maybe call update! anyway? maybe in the solver itself.
    stats = MadNLPCExecutionStats(solver)
    status = 0
    try
        stats = solve_homotopy!(solver.rnlp, solver, stats; nt_opts...)
    catch e
        println(e)
        status = solver.ipm.status
    finally
        stats_ptr = pointer_from_objref(stats)
        unsafe_store!(stats_ptr_ptr, stats_ptr)
        libmad_refs[stats_ptr] = stats
    end

    return Cint(status)
end
