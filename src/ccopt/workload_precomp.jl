using MadNLP
using Base: unsafe_convert
# Built from MadNLP_c: https://github.com/jgillis/madnlp_c
ncc::Int64 = 1

@setup_workload begin
    c_jac_struct = @cfunction(jac_struct, Cint, (Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Cvoid}))
    c_hess_struct = @cfunction(hess_struct, Cint, (Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Cvoid}))
    c_eval_f = @cfunction(eval_f, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
    c_eval_g = @cfunction(eval_g, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
    c_eval_grad_f = @cfunction(eval_grad_f, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
    c_eval_jac_g = @cfunction(eval_jac_g, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
    c_eval_h = @cfunction(eval_h, Cint, (Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))

    # Structures
    opts_ptr_vec = Vector{Ptr{Cvoid}}([C_NULL])
    opts_ptr = opts_ptr_vec[1]
    opts_ptr_ptr = pointer(opts_ptr_vec)
    mpcc_opts_ptr_vec = Vector{Ptr{Cvoid}}([C_NULL])
    mpcc_opts_ptr = mpcc_opts_ptr_vec[1]
    mpcc_opts_ptr_ptr = pointer(mpcc_opts_ptr_vec)
    nlp_ptr_vec = Vector{Ptr{Cvoid}}([C_NULL])
    nlp_ptr = nlp_ptr_vec[1]
    nlp_ptr_ptr = pointer(nlp_ptr_vec)
    mpcc_ptr_vec = Vector{Ptr{Cvoid}}([C_NULL])
    mpcc_ptr = mpcc_ptr_vec[1]
    mpcc_ptr_ptr = pointer(mpcc_ptr_vec)
    solver_ptr_vec = Vector{Ptr{Cvoid}}([C_NULL])
    solver_ptr = solver_ptr_vec[1]
    solver_ptr_ptr = pointer(solver_ptr_vec)
    stats_ptr_vec = Vector{Ptr{Cvoid}}([C_NULL])
    stats_ptr = stats_ptr_vec[1]
    stats_ptr_ptr = pointer(stats_ptr_vec)

    o_success = Vector{Cuchar}([false])
    o_obj = Vector{Cdouble}(undef, 1)
    o_solution = Vector{Cdouble}(undef, 2)
    o_multipliers_L = Vector{Cdouble}(undef, 2)
    o_multipliers_U = Vector{Cdouble}(undef, 2)
    o_constraints = Vector{Cdouble}(undef, 1)
    o_multipliers = Vector{Cdouble}(undef, 1)
    o_multipliers_x1 = Vector{Cdouble}(undef, 1)
    o_multipliers_x2 = Vector{Cdouble}(undef, 1)

    x0 = Vector{Cdouble}([1.0, 1.0])

    lvar = Vector{Cdouble}([0, 0])
    uvar = Vector{Cdouble}([Inf, Inf])
    lcon = Vector{Cdouble}([0.0])
    ucon = Vector{Cdouble}([0.0])
    ind_cc1 = Vector{Clonglong}([1])
    ind_cc2 = Vector{Clonglong}([2])
    cctypes = Vector{Clonglong}([0])
    # until we figure out a workaround for HSL we cannot precompile those solvers
    linear_solvers = ["CHOLMODSolver", "LapackCPUSolver", "LDLSolver", "MumpsSolver", "UmfpackSolver"]
    for ls in linear_solvers
        for kkt in keys(KKT_DICT)
            println("kkt: $(kkt), linear solver: $(ls)")
            GC.@preserve x0 lvar uvar lcon ucon begin
                @compile_workload begin
                    try
                        _name = "aname"
                        libMad.libmad_nlpmodel_create(nlp_ptr_ptr,
                                                      unsafe_convert(Cstring,_name),
                                                      nvar, ncon,
                                                      2, 3,
                                                      c_jac_struct, c_hess_struct,
                                                      c_eval_f, c_eval_g,
                                                      c_eval_grad_f, c_eval_jac_g,
                                                      c_eval_h,
                                                      Ptr{Cvoid}(C_NULL)
                                                      )
                        nlp_ptr = nlp_ptr_vec[1]
                        libMad.libmad_nlpmodel_set_numerics(nlp_ptr,
                                                           pointer(x0), Ptr{Cdouble}(C_NULL),
                                                           pointer(lvar), pointer(uvar),
                                                           pointer(lcon), pointer(ucon)
                                                           )
                        nlp_ptr = nlp_ptr_vec[1]
                        libMad.libmad_mpccmodel_create(mpcc_ptr_ptr,
                                                       nlp_ptr,
                                                       ncc,
                                                       pointer(ind_cc1), pointer(ind_cc2),
                                                       pointer(cctypes)
                                                       )
                        mpcc_ptr = mpcc_ptr_vec[1]
                        libMad.libmad_create_options_dict(opts_ptr_ptr)
                        opts_ptr = opts_ptr_vec[1]
                        libMad.libmad_create_options_dict(mpcc_opts_ptr_ptr)
                        mpcc_opts_ptr = mpcc_opts_ptr_vec[1]

                        _tol = "tol"
                        _max_iter = "max_iter"
                        _print_level = "print_level"
                        _callback = "callback"
                        _linear_solver = "linear_solver"
                        _SparseCallback = "SparseCallback"
                        _hessian_constant = "hessian_constant"
                        libMad.libmad_set_double_option(opts_ptr, unsafe_convert(Cstring,_tol), Cdouble(1e-6))
                        libMad.libmad_set_int64_option(opts_ptr, unsafe_convert(Cstring,_max_iter), 2000)
                        libMad.libmad_set_string_option(opts_ptr, unsafe_convert(Cstring,_callback), unsafe_convert(Cstring,_SparseCallback))
                        libMad.libmad_set_int64_option(opts_ptr, unsafe_convert(Cstring,_print_level), Clonglong(MadNLP.ERROR))
                        libMad.libmad_set_string_option(opts_ptr, unsafe_convert(Cstring,_linear_solver), unsafe_convert(Cstring,ls))
                        libMad.libmad_set_bool_option(opts_ptr, unsafe_convert(Cstring,_hessian_constant), false)

                        libMad.ccopt_relaxation_create_solver(solver_ptr_ptr, mpcc_ptr, opts_ptr, mpcc_opts_ptr)
                        solver_ptr = solver_ptr_vec[1]
                        libMad.ccopt_relaxation_solve(solver_ptr, opts_ptr, stats_ptr_ptr)
                        stats_ptr = stats_ptr_vec[1]

                        libMad.ccopt_relaxation_get_success(stats_ptr, pointer(o_success))
                        libMad.ccopt_relaxation_get_obj(stats_ptr, pointer(o_obj))
                        libMad.ccopt_relaxation_get_solution(stats_ptr, pointer(o_solution))
                        libMad.ccopt_relaxation_get_multipliers(stats_ptr, pointer(o_multipliers))
                        libMad.ccopt_relaxation_get_constraints(stats_ptr, pointer(o_constraints))
                        libMad.ccopt_relaxation_get_multipliers_L(stats_ptr, pointer(o_multipliers_L))
                        libMad.ccopt_relaxation_get_multipliers_U(stats_ptr, pointer(o_multipliers_U))
                        libMad.ccopt_relaxation_get_multipliers_x1(stats_ptr, pointer(o_multipliers_x1))
                        libMad.ccopt_relaxation_get_multipliers_x2(stats_ptr, pointer(o_multipliers_x2))

                        println("success: $(o_success)")
                        println("obj: $(o_obj)")
                        println("solution: $(o_solution)")
                        println("multipliers: $(o_multipliers)")
                        println("constraints: $(o_constraints)")
                        println("multipliers_U: $(o_multipliers_U)")
                        println("multipliers_L: $(o_multipliers_L)")
                        println("multipliers_x2: $(o_multipliers_x1)")
                        println("multipliers_x2: $(o_multipliers_x2)")

                        libMad.ccopt_relaxation_delete_solver(solver_ptr)
                    catch e
                        Base.printstyled("WARN: "; color=:red, bold=true)
                        Base.showerror(stdout, e)
                        Base.show_backtrace(stdout, Base.catch_backtrace())
                        println("$((ls, kkt)) failed")
                    finally
                    end
                end
            end
        end
    end
end
