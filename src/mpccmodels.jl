# We use directly the MPCCModel type
# For now we only support vertical form
# TODO(@anton) support non-vertical form creation. What is the best way to do that?

push!(dummy_structs, "MPCCModel")
push!(function_sigs, """int libmad_mpccmodel_create(MPCCModel** mpcc_ptr_ptr,
                                                    const char* name,
                                                    libmad_int nvar, libmad_int ncon,
                                                    libmad_int nnzj, libmad_int nnzh,
                                                    libmad_int ncc,
                                                    libmad_int* ind_cc1, libmad_int* ind_cc2,
                                                    NlpConstrJacStructure jac_struct, NlpLagHessStructure hess_struct,
                                                    NlpEvalObj eval_f, NlpEvalConstr eval_g,
                                                    NlpEvalObjGrad eval_grad_f, NlpEvalConstrJac eval_jac_g,
                                                    NlpEvalLagHess eval_h,
                                                    void* user_data)"""
      )
Base.@ccallable function libmad_mpccmodel_create(mpcc_ptr_ptr::Ptr{Ptr{Cvoid}},
                                                 name::Cstring,
                                                 nvar::Clonglong, ncon::Clonglong,
                                                 nnzj::Clonglong, nnzh::Clonglong,
                                                 ncc::Clonglong,
                                                 ind_cc1::Ptr{Clonglong}, ind_cc2::Ptr{Clonglong},
                                                 jac_struct::Ptr{Cvoid}, hess_struct::Ptr{Cvoid},
                                                 eval_f::Ptr{Cvoid}, eval_g::Ptr{Cvoid},
                                                 eval_grad_f::Ptr{Cvoid}, eval_jac_g::Ptr{Cvoid},
                                                 eval_h::Ptr{Cvoid},
                                                 user_data::Ptr{Cvoid})::Cint
    meta = NLPModelMeta(
        nvar,
        ncon = ncon,
        nnzj = nnzj,
        nnzh = nnzh,
        name = unsafe_string(name),
        minimize = true
    )

    nlp = CNLPModel(
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

    # Copy the indices
    ind_vcc1 = IndexSet(undef, ncc)
    ind_vcc2 = IndexSet(undef, ncc)
    ind_vcc1 .= wrap_ptr(ind_cc1, ncc)
    ind_vcc2 .= wrap_ptr(ind_cc2, ncc)

    mpcc = MPCCModelVarVar(ind_vcc1, ind_vcc2)
    mpcc_ptr = Ptr{MPCCModel{Cdouble, Vector{Cdouble}}}(pointer_from_objref(mpcc))
    unsafe_store!(mpcc_ptr_ptr, mpcc_ptr)
    libmad_refs[mpcc_ptr] = mpcc
    return Cint(0)
end
