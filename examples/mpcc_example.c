#include "libMad.h"
#include <math.h>
#include <stdlib.h>
#include <stdio.h>

int jac_structure(long long* I, long long* J, void* user_data)
{
  return 0;
}

int hess_structure(long long* I, long long* J, void* user_data)
{
  I[0] = 1;
  I[1] = 2;
  J[0] = 1;
  J[1] = 2;

  return 0;
}

int obj(const double* x, double* f, void* user_data)
{
  *f = 0.5*((x[0]-2)*(x[0]-2) + (x[1]-2)*(x[1]-2));
  return 0;
}

int cons(const double* x, double* c, void* user_data)
{
  return 0;
}

int grad(const double* x, double* g, void* user_data)
{
  g[0] = x[0] - 2;
  g[1] = x[1] - 2;

  return 0;
}

int jac_coord(const double* x, double* J, void* user_data)
{
  return 0;
}

int hess_coord(double obj_weight, const double* x, const double* y, double* H, void* user_data)
{
  H[0] = 1;
  H[1] = 1;

  return 0;
}

int main(int argc, char** argv)
{
  CMPCCModel* mpcc_ptr;
  CNLPModel* nlp_ptr;
  OptsDict* nlp_opts_ptr;
  OptsDict* mpcc_opts_ptr;
  RelaxationSolver* solver_ptr;
  CCOptExecutionStats* stats_ptr;

  double* x0 = malloc(2*sizeof(double));
  x0[0] = 0.5; x0[1] = 0.2;
  double* lvar = malloc(2*sizeof(double));
  lvar[0] = 0; lvar[1] = 0;
  double* uvar = malloc(2*sizeof(double));
  uvar[0] = INFINITY; uvar[1] = INFINITY;
  double* lcon = malloc(0*sizeof(double));
  double* ucon = malloc(0*sizeof(double));
  long long int* ind_cc1 = malloc(1*sizeof(long long int));
  ind_cc1[0] = 1;
  long long int* ind_cc2 = malloc(1*sizeof(long long int));
  ind_cc2[0] = 2;
	long long int* cctypes = malloc(1*sizeof(long long int));
	cctypes[0] = LIBMAD_MADMPEC_VARVAR;

  libmad_nlpmodel_create(&nlp_ptr, "test_model",
												 2, 0,
												 0, 2,
												 &jac_structure, &hess_structure,
												 &obj, &cons,
												 &grad, &jac_coord,
												 &hess_coord,
												 NULL);

  libmad_nlpmodel_set_numerics(nlp_ptr,
															 x0, NULL,
															 lvar, uvar,
															 lcon, ucon);
	libmad_mpccmodel_create(&mpcc_ptr,
													nlp_ptr,
													1,
													ind_cc1, ind_cc2,
													cctypes);

  libmad_create_options_dict(&nlp_opts_ptr);
  libmad_create_options_dict(&mpcc_opts_ptr);
  ccopt_relaxation_create_solver(&solver_ptr, mpcc_ptr, nlp_opts_ptr, mpcc_opts_ptr);
  ccopt_relaxation_solve(solver_ptr, nlp_opts_ptr, &stats_ptr);

  bool success;
  double* solution = malloc(2*sizeof(double));
  double objective;

  ccopt_relaxation_get_success(stats_ptr, &success);
  ccopt_relaxation_get_solution(stats_ptr, solution);
  ccopt_relaxation_get_obj(stats_ptr, &objective);

  printf("Success: %s\n", success ? "true" : "false");
  printf("Objective: %f\n", objective);
  printf("Solution: [%f, ", solution[0]);
  printf("%f]\n", solution[1]);

  ccopt_relaxation_delete_solver(solver_ptr);

  ccopt_relaxation_delete_stats(stats_ptr);
  return 0;
}
