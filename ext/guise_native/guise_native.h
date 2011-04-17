#include "svm.h"
#define Malloc(type,n) (type *)malloc((n)*sizeof(type))


// Defining a space for information and references about the module to be stored internally
VALUE Guise = Qnil;
struct svm_parameter param;		// set by parse_command_line
struct svm_problem prob;		// set by read_problem
struct svm_model *model;
struct svm_node *x_space;
int cross_validation;
int nr_fold;