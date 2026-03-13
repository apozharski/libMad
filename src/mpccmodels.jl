# We use directly the MPCCModel type
# For now we only support vertical form
# TODO(@anton) support non-vertical form creation. What is the best way to do that?

push!(dummy_structs, "MPCCModel")
push!(function_sigs, """int libmad_mpccmodel_create(MPCCModel** mpcc_ptr_ptr,
                                                    CNLPModel* nlp_ptr,
                                                    libmad_int ncc,
                                                    const libmad_int* ind_cc1, const libmad_int* ind_cc2,
                                                    const libmad_int* cctypes
                                                    )"""
      )
Base.@ccallable function libmad_mpccmodel_create(mpcc_ptr_ptr::Ptr{Ptr{Cvoid}},
                                                 nlp_ptr::Ptr{Cvoid},
                                                 ncc::Clonglong,
                                                 ind_cc1_ptr::Ptr{Clonglong}, ind_cc2_ptr::Ptr{Clonglong},
                                                 cctypes_ptr::Ptr{Clonglong},
                                                 )::Cint
    nlp = wrap_obj(CNLPModel, nlp_ptr)

    # Copy the indices
    # TODO(@anton) is this inefficient?
    ind_cc1 = IndexSet(undef, ncc)
    ind_cc2 = IndexSet(undef, ncc)
    ind_cc1 .= wrap_ptr(ind_cc1_ptr, ncc)
    ind_cc2 .= wrap_ptr(ind_cc2_ptr, ncc)
    cctypes = Vector{.CCType}(undef, ncc)
    cctypes_raw = wrap_ptr(cctypes_ptr, ncc)
    for i=1:ncc
        cctypes[i] = .CCType(cctypes_raw[i])
    end

    mpcc = MPCCModel(nlp, ind_cc1, ind_cc2, cctypes)
    mpcc_ptr = Ptr{MPCCModel{Cdouble, Vector{Cdouble}}}(pointer_from_objref(mpcc))
    unsafe_store!(mpcc_ptr_ptr, mpcc_ptr)
    libmad_refs[mpcc_ptr] = mpcc
    return Cint(0)
end

push!(function_sigs, """int libmad_mpccmodel_set_numerics(MPCCModel* mpcc_ptr,
                                                          const libmad_real* x0, const libmad_real* y0,
                                                          const libmad_real* lvar, const libmad_real* uvar,
                                                          const libmad_real* lcon, const libmad_real* ucon
                                                          )"""
      )
Base.@ccallable function libmad_mpccmodel_set_numerics(mpcc_ptr::Ptr{Cvoid},
                                                       x0::Ptr{Cdouble}, y0::Ptr{Cdouble},
                                                       lvar::Ptr{Cdouble}, uvar::Ptr{Cdouble},
                                                       lcon::Ptr{Cdouble}, ucon::Ptr{Cdouble},
                                                       )::Cint
    mpcc = wrap_obj(MPCCModel, mpcc_ptr)
    if x0 != C_NULL
        mpcc.meta.x0 .= wrap_ptr(x0, mpcc.meta.nvar)
    end
    if y0 != C_NULL
        mpcc.meta.y0 .= wrap_ptr(y0, mpcc.meta.ncon)
    end
    if lvar != C_NULL
        mpcc.meta.lvar .= wrap_ptr(lvar, mpcc.meta.nvar)
    end
    if uvar != C_NULL
        mpcc.meta.uvar .= wrap_ptr(uvar, mpcc.meta.nvar)
    end
    if lcon != C_NULL
        mpcc.meta.lcon .= wrap_ptr(lcon, mpcc.meta.ncon)
    end
    if ucon != C_NULL
        mpcc.meta.ucon .= wrap_ptr(ucon, mpcc.meta.ncon)
    end

    return Cint(0)
end
