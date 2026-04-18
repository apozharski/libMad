# For now we don't use the macro because of the weirdness with SolverCore API
push!(dummy_structs, "RelaxationSolver")

push!(function_sigs, "int ccopt_relaxation_create_solver(RelaxationSolver** solver_ptr_ptr, CMPCCModel* mpcc_ptr, OptsDict* nlp_opts_ptr, OptsDict* mpcc_opts_ptr)")

Base.@ccallable function ccopt_relaxation_create_solver(solver_ptr_ptr::Ptr{Ptr{Cvoid}},
                                               mpcc_ptr::Ptr{Cvoid},
                                               nlp_opts_ptr::Ptr{Cvoid},
                                               mpcc_opts_ptr::Ptr{Cvoid}
                                               )::Cint
    nlp = unsafe_pointer_to_objref(mpcc_ptr)[]
    nlp_opts = wrap_obj(OptsDict, nlp_opts_ptr)
    mpcc_opts = wrap_obj(OptsDict, mpcc_opts_ptr)
    nlp_nt_opts = try
        madnlp_to_parameters(nlp_opts)
    catch e
        Base.printstyled("THIS IS A PROBLEM: "; color=:red, bold=true)
        Base.showerror(stdout, e)
        Base.show_backtrace(stdout, Base.catch_backtrace())
        return Cint(-1)
    end

    mpcc_nt_opts = try
        ccopt_relaxation_to_parameters(mpcc_opts)
    catch e
        Base.printstyled("THIS IS A PROBLEM: "; color=:red, bold=true)
        Base.showerror(stdout, e)
        Base.show_backtrace(stdout, Base.catch_backtrace())
        return Cint(-2)
    end

    ccopt_relaxation_opts = try
        RelaxationOptions(;mpcc_nt_opts...)
    catch e
        Base.printstyled("THIS IS A PROBLEM: "; color=:red, bold=true)
        Base.showerror(stdout, e)
        Base.show_backtrace(stdout, Base.catch_backtrace())
        return Cint(-3)
    end
    solver = try
        RelaxationSolver(
            nlp;
            solver_opts=ccopt_relaxation_opts,
            nlp_nt_opts...
                )
    catch e
        Base.printstyled("THIS IS A PROBLEM: "; color=:red, bold=true)
        Base.showerror(stdout, e)
        Base.show_backtrace(stdout, Base.catch_backtrace())
        return Cint(-4)
    end
    solver_ptr = pointer_from_objref(solver)
    unsafe_store!(solver_ptr_ptr, solver_ptr)
    libmad_refs[solver_ptr] = solver

    return Cint(0)
end

push!(function_sigs, "int ccopt_relaxation_delete_solver(RelaxationSolver* solver_ptr)")
Base.@ccallable function ccopt_relaxation_delete_solver(solver_ptr::Ptr{Cvoid})::Cint
    if haskey(libmad_refs, solver_ptr)
        delete!(libmad_refs, solver_ptr)
        return Cint(0)
    else
        return Cint(1)
    end
end

push!(function_sigs, "int ccopt_relaxation_solve(RelaxationSolver* solver_ptr, OptsDict* nlp_opts_ptr, CCOptExecutionStats** stats_ptr_ptr)")
Base.@ccallable function ccopt_relaxation_solve(solver_ptr::Ptr{Cvoid},
                                       nlp_opts_ptr::Ptr{Cvoid},
                                       stats_ptr_ptr::Ptr{Ptr{Cvoid}})::Cint
    solver = unsafe_pointer_to_objref(solver_ptr)# why doesn't this work: wrap_obj($(solver_expr), solver_ptr)
    opts = wrap_obj(OptsDict, nlp_opts_ptr)
    nt_opts = madnlp_to_parameters(opts)
    # Prealloc a stats so we always set a stats_ptr even on rethrown error,
    # TODO(@anton): we should maybe call update! anyway? maybe in the solver itself.
    stats = CCOptExecutionStats(solver)
    status = 0
    try
        stats = solve_homotopy!(solver.rnlp, solver, stats; nt_opts...)
    catch e
        Base.printstyled("THIS IS A PROBLEM: "; color=:red, bold=true)
        Base.showerror(stdout, e)
        Base.show_backtrace(stdout, Base.catch_backtrace())
        status = solver.ipm.status
    finally
        stats_ptr = pointer_from_objref(stats)
        unsafe_store!(stats_ptr_ptr, stats_ptr)
        libmad_refs[stats_ptr] = stats
    end

    return Cint(status)
end
