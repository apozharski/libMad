# TODO (@anton) In the future also handle abstract model types???

function generate_create_solver(solname, solver_expr, optsdict_expr; model=CNLPModel{Cdouble,Vector{Cdouble}}, modelname="CNLPModel", suffix=Symbol())

    base_solver = eval(nameof(eval(solver_expr)))
    push!(function_sigs, "int $(solname)$(suffix)_create_solver($(String(nameof(eval(solver_expr))))** solver_ptr_ptr, $(modelname)* nlp_ptr, OptsDict* opts_ptr)")
    
    return quote
        Base.@ccallable function $(Symbol(solname, suffix, :_create_solver))(solver_ptr_ptr::Ptr{Ptr{Cvoid}},
                                                    nlp_ptr::Ptr{Cvoid},
                                                    opts_ptr::Ptr{Cvoid}
                                                    )::Cint
            nlp = unsafe_pointer_to_objref(nlp_ptr) # why doesn't this work: nlp = wrap_obj($(model),nlp_ptr)
            opts = wrap_obj(OptsDict, opts_ptr)
            nt_opts = try
                $(Symbol(solname,:_to_parameters))(opts)
            catch e
                Base.printstyled("ERROR: "; color=:red, bold=true)
                Base.showerror(stdout, e)
                Base.show_backtrace(stdout, Base.catch_backtrace())
                return Cint(-1)
            end
            # see if we have to wrap the model in in a wrapped model:
            nlp = try
                gpuconvert($(base_solver), opts, nlp)
            catch e
                Base.printstyled("ERROR: "; color=:red, bold=true)
                Base.showerror(stdout, e)
                Base.show_backtrace(stdout, Base.catch_backtrace())
                return Cint(-3)
            end
            solver = try
                $(base_solver)(nlp;
                               nt_opts...
                                   )
            catch e
                Base.printstyled("ERROR: "; color=:red, bold=true)
                Base.showerror(stdout, e)
                Base.show_backtrace(stdout, Base.catch_backtrace())
                return Cint(-3)
            end
            solver_ptr = pointer_from_objref(solver)
            unsafe_store!(solver_ptr_ptr, solver_ptr)
            libmad_refs[solver_ptr] = solver

            return Cint(0)
        end

    end
end

function generate_delete_solver(solname, solver_expr, optsdict_expr)
    push!(function_sigs, "int $(solname)_delete_solver($(String(nameof(eval(solver_expr))))* solver_ptr)")
    base_solver = eval(nameof(eval(solver_expr)))
    return quote
        Base.@ccallable function $(Symbol(solname, :_delete_solver))(solver_ptr::Ptr{Cvoid})::Cint
            if haskey(libmad_refs, solver_ptr)
                delete!(libmad_refs, solver_ptr)
                return Cint(0)
            else
                return Cint(1)
            end
        end
    end
end


function generate_solve(solname, solver_expr, optsdict_expr, stats_expr)
    push!(function_sigs, "int $(solname)_solve($(String(nameof(eval(solver_expr))))* solver_ptr, OptsDict* opts_ptr, $(String(nameof(eval(stats_expr))))** stats_ptr_ptr)")
    base_solver = eval(nameof(eval(solver_expr)))
    return quote
        Base.@ccallable function $(Symbol(solname, :_solve))(solver_ptr::Ptr{Cvoid},
                                                             opts_ptr::Ptr{Cvoid},
                                                             stats_ptr_ptr::Ptr{Ptr{Cvoid}})::Cint
            solver = unsafe_pointer_to_objref(solver_ptr)# why doesn't this work: wrap_obj($(solver_expr), solver_ptr)
            opts = wrap_obj(OptsDict, opts_ptr)
            nt_opts = $(Symbol(solname,:_to_parameters))(opts)
            # Prealloc a stats so we always set a stats_ptr even on rethrown error,
            # TODO(@anton): we should maybe call update! anyway? maybe in the solver itself.
            stats = try
                $(stats_expr)(solver)
            catch e
                Base.printstyled("ERROR: "; color=:red, bold=true)
                Base.showerror(stdout, e)
                Base.show_backtrace(stdout, Base.catch_backtrace())
                return Cint(-100)
            end
            status = 0
            try
                stats = MadNLP.solve!(solver, stats; nt_opts...)
            catch e
                Base.printstyled("ERROR: "; color=:red, bold=true)
                Base.showerror(stdout, e)
                Base.show_backtrace(stdout, Base.catch_backtrace())
                status = solver.status
            finally
                stats_ptr = pointer_from_objref(stats)
                unsafe_store!(stats_ptr_ptr, stats_ptr)
                libmad_refs[stats_ptr] = stats
            end

            return Cint(status)
        end
    end
end

# Generic gpu convert that does nothing.
gpuconvert(::Type, opts::OptsDict, nlp::CNLPModel) = nlp

macro solver(solname, solver_expr, optsdict_expr, stats_expr)
    push!(dummy_structs, String(nameof(eval(solver_expr))))
    return esc(
        quote
            $(generate_create_solver(solname, solver_expr, optsdict_expr))
            $(generate_delete_solver(solname, solver_expr, optsdict_expr))
            $(generate_solve(solname, solver_expr, optsdict_expr, stats_expr))
        end
    )
end
