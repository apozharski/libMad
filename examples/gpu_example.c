#include "libMad.h"
#include <math.h>
#include <stdlib.h>
#include <stdio.h>

int jac_structure(long long* I, long long* J, void* user_data)
{
  I[0] = 1;
  I[1] = 1;
  J[0] = 1;
  J[1] = 2;

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
  *c = x[0] + x[1];

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
  J[0] = 1;
  J[1] = 1;

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
  CNLPModel* nlp_ptr;
  OptsDict* opts_ptr;
  MadNLPSolver* solver_ptr;
  MadNLPExecutionStats* stats_ptr;

  double* x0 = malloc(2*sizeof(double));
  x0[0] = 0; x0[1] = 0;
  double* lvar = malloc(2*sizeof(double));
  lvar[0] = 0; lvar[1] = 0;
  double* uvar = malloc(2*sizeof(double));
  uvar[0] = INFINITY; uvar[1] = INFINITY;
  double* lcon = malloc(1*sizeof(double));
  lcon[0] = -INFINITY;
  double* ucon = malloc(1*sizeof(double));
  ucon[0] = 1;

  libmad_nlpmodel_create(&nlp_ptr, "test_model",
												 2, 1,
												 2, 2,
												 &jac_structure, &hess_structure,
												 &obj, &cons,
												 &grad, &jac_coord,
												 &hess_coord,
												 NULL);
  libmad_nlpmodel_set_numerics(nlp_ptr,
															 x0, NULL,
															 lvar, uvar,
															 lcon, ucon);

  libmad_create_options_dict(&opts_ptr);
  libmad_set_string_option(opts_ptr, "linear_solver", "CUDSSSolver");
  madnlp_create_solver(&solver_ptr, nlp_ptr, opts_ptr);
  madnlp_solve(solver_ptr, opts_ptr, &stats_ptr);

  bool success;
  double* solution = malloc(2*sizeof(double));
  double objective;

  madnlp_get_success(stats_ptr, &success);
  madnlp_get_solution(stats_ptr, solution);
  madnlp_get_obj(stats_ptr, &objective);

  printf("Success: %s\n", success ? "true" : "false");
  printf("Objective: %f\n", objective);
  printf("Solution: [%f, ", solution[0]);
  printf("%f]\n", solution[1]);

  madnlp_delete_solver(solver_ptr);

  madnlp_delete_stats(stats_ptr);
  return 0;
}
