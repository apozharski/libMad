# CPU model
struct CNLPModel <: AbstractNLPModel{Cdouble,Vector{Cdouble}}
    meta::NLPModelMeta{Cdouble, Vector{Cdouble}}
    counters::NLPModels.Counters
    jac_struct::Ptr{Cvoid}
    hess_struct::Ptr{Cvoid}
    eval_f::Ptr{Cvoid}
    eval_g::Ptr{Cvoid}
    eval_grad_f::Ptr{Cvoid}
    eval_jac_g::Ptr{Cvoid}
    eval_h::Ptr{Cvoid}
    user_data::Ptr{Cvoid}
end

# CallbackException
struct CallbackException <: Exception
    callback::Symbol
    value::Cint
end

Base.showerror(io::IO, e::CallbackException) = print(io, "Callback " , e.callback, " returned nonzero value: ", e.value)

push!(dummy_structs, "CNLPModel")
push!(function_sigs, """int libmad_nlpmodel_create(CNLPModel** nlp_ptr_ptr,
                                                   const char* name,
                                                   libmad_int nvar, libmad_int ncon,
                                                   libmad_int nnzj, libmad_int nnzh,
                                                   NlpConstrJacStructure jac_struct, NlpLagHessStructure hess_struct,
                                                   NlpEvalObj eval_f, NlpEvalConstr eval_g,
                                                   NlpEvalObjGrad eval_grad_f, NlpEvalConstrJac eval_jac_g,
                                                   NlpEvalLagHess eval_h,
                                                   void* user_data)"""
      )

Base.@ccallable function libmad_nlpmodel_create(nlp_ptr_ptr::Ptr{Ptr{Cvoid}},
                                                name::Cstring,
                                                nvar::Clonglong, ncon::Clonglong,
                                                nnzj::Clonglong, nnzh::Clonglong,
                                                jac_struct::Ptr{Cvoid}, hess_struct::Ptr{Cvoid},
                                                eval_f::Ptr{Cvoid}, eval_g::Ptr{Cvoid},
                                                eval_grad_f::Ptr{Cvoid}, eval_jac_g::Ptr{Cvoid},
                                                eval_h::Ptr{Cvoid},
                                                user_data::Ptr{Cvoid})::Cint
    meta = try
        NLPModelMeta{Cdouble, Vector{Cdouble}}(
            nvar,
            ncon = ncon,
            nnzj = nnzj,
            nnzh = nnzh,
            name = unsafe_string(name),
            minimize = true
        )
    catch e
        Base.printstyled("THIS IS A PROBLEM: "; color=:red, bold=true)
        Base.showerror(stdout, e)
        Base.show_backtrace(stdout, Base.catch_backtrace())
        return Cint(-1)
    end

    nlp = try
        CNLPModel(
            meta,
            NLPModels.Counters(),
            jac_struct,
            hess_struct,
            eval_f,
            eval_g,
            eval_grad_f,
            eval_jac_g,
            eval_h,
            user_data
        )
    catch e
        Base.printstyled("THIS IS A PROBLEM: "; color=:red, bold=true)
        Base.showerror(stdout, e)
        Base.show_backtrace(stdout, Base.catch_backtrace())
        return Cint(-2)
    end
    nlp_ref = Ref(nlp)
    nlp_ptr = Ptr{Base.RefValue{CNLPModel}}(pointer_from_objref(nlp_ref))
    unsafe_store!(nlp_ptr_ptr, nlp_ptr)
    libmad_refs[nlp_ptr] = nlp_ref
    return Cint(0)
end

# TODO(@anton) This currently can cause weird issues if called out of order with `create_solver`
#              because it only changes the underlying model's numerics and not the wrapped model
#              though that is already broken.
push!(function_sigs, """int libmad_nlpmodel_set_numerics(CNLPModel* nlp_ptr,
                                                         const libmad_real* x0, const libmad_real* y0,
                                                         const libmad_real* lvar, const libmad_real* uvar,
                                                         const libmad_real* lcon, const libmad_real* ucon
                                                        )"""
      )
Base.@ccallable function libmad_nlpmodel_set_numerics(nlp_ptr::Ptr{Cvoid},
                                                      x0::Ptr{Cdouble}, y0::Ptr{Cdouble},
                                                      lvar::Ptr{Cdouble}, uvar::Ptr{Cdouble},
                                                      lcon::Ptr{Cdouble}, ucon::Ptr{Cdouble},
                                                      )::Cint
    nlp = wrap_obj(Base.RefValue{CNLPModel}, nlp_ptr)[]
    if x0 != C_NULL
        nlp.meta.x0 .= wrap_ptr(x0, nlp.meta.nvar)
    end
    if y0 != C_NULL
        nlp.meta.y0 .= wrap_ptr(y0, nlp.meta.ncon)
    end
    if lvar != C_NULL
        nlp.meta.lvar .= wrap_ptr(lvar, nlp.meta.nvar)
    end
    if uvar != C_NULL
        nlp.meta.uvar .= wrap_ptr(uvar, nlp.meta.nvar)
    end
    if lcon != C_NULL
        nlp.meta.lcon .= wrap_ptr(lcon, nlp.meta.ncon)
    end
    if ucon != C_NULL
        nlp.meta.ucon .= wrap_ptr(ucon, nlp.meta.ncon)
    end

    return Cint(0)
end

function NLPModels.jac_structure!(nlp::CNLPModel, I::AbstractVector{T}, J::AbstractVector{T}) where T
    I_ = Base.unsafe_convert(Ptr{Clonglong}, I)
    J_ = Base.unsafe_convert(Ptr{Clonglong}, J)
    ret = ccall(nlp.jac_struct, Cint, (Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Cvoid}), I_, J_, nlp.user_data)
    if ret != Cint(0)
        throw(CallbackException(:jac_structure, ret))
    end
    return I, J
end

function NLPModels.jac_lin_structure!(nlp::CNLPModel, I::AbstractVector{T}, J::AbstractVector{T}) where T
    return I, J
end

function NLPModels.jac_nln_structure!(nlp::CNLPModel, I::AbstractVector{T}, J::AbstractVector{T}) where T
    return jac_structure!(nlp,I,J)
end

function NLPModels.hess_structure!(nlp::CNLPModel, I::AbstractVector{T}, J::AbstractVector{T}) where T
    I_ = Base.unsafe_convert(Ptr{Clonglong}, I)
    J_ = Base.unsafe_convert(Ptr{Clonglong}, J)
    ret = ccall(nlp.hess_struct, Cint, (Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Cvoid}), I_, J_, nlp.user_data)
    if ret != Cint(0)
        throw(CallbackException(:hess_structure, ret))
    end
    return I, J
end

function NLPModels.obj(nlp::CNLPModel, x::AbstractVector)
    x_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, x)
    f = Vector{Cdouble}([0.0])
    ret::Cint = ccall(nlp.eval_f, Cint, (Ptr{Cdouble},Ptr{Cdouble}, Ptr{Cvoid}), x_, f, nlp.user_data)
    if ret != Cint(0)
        throw(CallbackException(:obj, ret))
    end
    return f[1]
end

function NLPModels.cons!(nlp::CNLPModel, x::AbstractVector, c::AbstractVector)
    x_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, x)
    c_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, c)
    ret::Cint = ccall(nlp.eval_g, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}), x_, c_, nlp.user_data)
    if ret != Cint(0)
        throw(CallbackException(:cons, ret))
    end
    return c
end


function NLPModels.grad!(nlp::CNLPModel, x::AbstractVector, g::AbstractVector)
    x_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, x)
    g_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, g)
    ret::Cint = ccall(nlp.eval_grad_f, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}), x_, g_, nlp.user_data)
    if ret != Cint(0)
        throw(CallbackException(:grad, ret))
    end
    return g
end


function NLPModels.jac_coord!(nlp::CNLPModel, x::AbstractVector, J::AbstractVector)
    x_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, x)
    J_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, J)
    ret::Cint = ccall(nlp.eval_jac_g, Cint, (Ptr{Cdouble},Ptr{Cdouble},Ptr{Cvoid}), x_, J_, nlp.user_data)
    if ret != Cint(0)
        throw(CallbackException(:jac_coord, ret))
    end
    return J
end

function NLPModels.jac_lin_coord!(nlp::CNLPModel, x::AbstractVector, J::AbstractVector)
    return J
end

function NLPModels.jac_nln_coord!(nlp::CNLPModel, x::AbstractVector, J::AbstractVector)
    return jac_coord!(nlp,x,J)
end

function NLPModels.hess_coord!(nlp::CNLPModel, x::AbstractVector, y::AbstractVector, H::AbstractVector;
                               obj_weight::Float64=1.0)
    x_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, x)
    y_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, y)
    H_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, H)
    ret::Cint = ccall(nlp.eval_h, Cint,
                      (Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}),
                      obj_weight, x_, y_, H_, nlp.user_data)
    if ret != Cint(0)
        throw(CallbackException(:hess_coord, ret))
    end
    return H
end

function NLPModels.jtprod!(
    nlp::CNLPModel,
    x::AbstractVector,
    v::AbstractVector,
    Jtv::AbstractVector,
)
    # TODO(@anton) do this in a smarter way?
    Jtv[1:nlp.meta.nvar] .= jac(nlp, x)' * v
    return Jtv
end

function NLPModels.jtprod_lin!(
    nlp::CNLPModel,
    x::AbstractVector,
    v::AbstractVector,
    Jtv::AbstractVector,
)
    # TODO(@anton) do this in a smarter way?
    Jtv[1:nlp.meta.nvar] .= jac_lin(nlp, x)' * v
    return Jtv
end

function NLPModels.jtprod_nln!(
    nlp::CNLPModel,
    x::AbstractVector,
    v::AbstractVector,
    Jtv::AbstractVector,
)
    # TODO(@anton) do this in a smarter way?
    Jv[1:nlp.meta.nvar] .= jac_nln(nlp, x)' * v
    return Jtv
end
