// Include the Ruby headers and goodies
#include "ruby.h"
#include "guise_native.h"


VALUE svm_model_to_struct(const struct svm_model *model);
void i_pointer_to_ary(VALUE ary, int *p);
void d_pointer_to_ary(VALUE ary, double *p);
void do_cross_validation();
// Prototype for the initialization method - Ruby calls this, not you
void Init_guise();
void set_params();

static VALUE load_model(VALUE self, VALUE rows) {
	const char *error_msg;
	/*
	* Defines the problem space
	* 
	*/
	if (TYPE(rows) == T_ARRAY) {
		prob.l = RARRAY_LEN(rows);
		long elements = 0;
		int max_index, inst_max_index, i, j;
		char *endptr;
		char *idx, *val, *label;
		
		VALUE *ary = RARRAY_PTR(rows);
		VALUE id_x = rb_str_intern(rb_str_new2("x"));
		VALUE id_y = rb_str_intern(rb_str_new2("y"));
		/* 
		 * Each row is a struct and has a y and x
		 * y is a label
		 * x is an array
		 */
		for (i = 0; i < prob.l; i++) {
			VALUE *values = RARRAY_PTR(rb_struct_aref(ary[i], id_x));
			elements += RARRAY_LEN(values);
			++elements;
		}
			
		
		
		prob.y = Malloc(double,prob.l);
		prob.x = Malloc(struct svm_node *,prob.l);
		x_space = Malloc(struct svm_node,elements);
		
		for (i = 0; i < prob.l; i++) {
			VALUE label = rb_struct_aref(ary[i], id_y); //label
			VALUE *values = RARRAY_PTR(rb_struct_aref(ary[i], id_x)); //values pointer array
			
			
			//The row must be a struct otherwise an error is thrown
			if (TYPE(ary[i]) == T_STRUCT) {
				inst_max_index = -1;
				prob.x[i] = &x_space[j];
								
				if(TYPE(label) != T_FIXNUM) {
					rb_raise(rb_eException, "Y must be a Fixnum");
				}
				
				prob.y[i] = NUM2DBL(label);
				
				for (j = 0; j < RARRAY_LEN(values); j++) {
					x_space[j].index = values[j];
					inst_max_index = x_space[j].index;
					x_space[j].value = 1.0;
				}
				if(inst_max_index > max_index)
				{
					max_index = inst_max_index;
				}

				x_space[j++].index = -1;
			} else {
				rb_raise(rb_eException, "Must be a struct inside of the rows");
			}
		}

		if(param.gamma == 0 && max_index > 0)
		{
			param.gamma = 1.0/max_index;	
		}
		
		error_msg = svm_check_parameter(&prob,&param);
		if(error_msg)
		{
			rb_raise(rb_eException, error_msg);
			return 1;
		}
		if(cross_validation)
		{
			do_cross_validation();
		} else {
			model = svm_train(&prob,&param); //returns svm_model
			if(svm_save_model("foo.txt",model)) {
				rb_raise(rb_eException, "Must be an array");
			}
			//rb_model = svm_model_to_struct(model);
			svm_free_and_destroy_model(&model);		
	    }
	
		svm_destroy_param(&param);
		free(prob.y);
		free(prob.x);
		free(x_space);

		return 0;
	} else {
		rb_raise(rb_eException, "Must be an array");
		return -1;
	}
}


/**
 * int nr_class;		 number of classes, = 2 in regression/one class svm
 * int l;			 total #SV
 * struct svm_node **SV;   SVs (SV[l]) 
 * double **sv_coef;	coefficients for SVs in decision functions (sv_coef[k-1][l]) 
 * double *rho;		 constants in decision functions (rho[k*(k-1)/2])
 * double *probA;  pariwise probability information 
 * double *probB;
 * for classification only
 * int *label;		label of each class (label[k])
 * int *nSV;		number of SVs for each class (nSV[k])
 *  nSV[0] + nSV[1] + ... + nSV[k-1] = l
 * int free_sv;	 1 if svm_model is created by svm_load_model
 *			     0 if svm_model is created by svm_train 
 */
VALUE svm_model_to_struct(const struct svm_model *model) {
	// VALUE rho = rb_ary_new();
	// VALUE label = rb_ary_new();
	// VALUE nSV = rb_ary_new();
	// VALUE h_mod = rb_hash_new();
	// i_pointer_to_ary(label, model->label);
	// d_pointer_to_ary(rho, model->rho);
	// i_pointer_to_ary(nSV, model->nSV);
	// rb_hash_aset(h_mod, rb_str_new2("svm_type"), rb_str_new2("c_svc"));
	// rb_hash_aset(h_mod, rb_str_new2("kernel"), rb_str_new2("rbf"));
	// rb_hash_aset(h_mod, rb_str_new2("gamma"), INT2NUM(param.gamma));
	// rb_hash_aset(h_mod, rb_str_new2("nr_class"), INT2NUM(model->nr_class));
	// rb_hash_aset(h_mod, rb_str_new2("rho"), rho);
	// rb_hash_aset(h_mod, rb_str_new2("label"), label);
	// rb_hash_aset(h_mod, rb_str_new2("nSV"), nSV);
	// 
	// return h_mod;
}

void i_pointer_to_ary(VALUE ary, int *p) {
	int i;
	for(i = 0; p[i]; i++) {
		rb_ary_push(ary, INT2NUM(p[i]));
	}
}

void d_pointer_to_ary(VALUE ary, double *d) {
	int i;
	for (i=0; d[i]; i++) {
		rb_ary_push(ary, rb_float_new(d[i]));
	}
}


void Init_guise_native() {
	set_params();
	
	VALUE mGuise = rb_define_module("Guise");
	
	VALUE cTraining = rb_define_class_under(mGuise, "Model", rb_cObject);
	rb_define_module_function(cTraining, "load", load_model, 1);
}


void set_params() {
	param.svm_type = C_SVC;
	param.kernel_type = RBF;
	param.degree = 3;
	param.gamma = 0;	// 1/num_features
	param.coef0 = 0;
	param.nu = 0.5;
	param.cache_size = 100;
	param.C = 1;
	param.eps = 1e-3;
	param.p = 0.1;
	param.shrinking = 1;
	param.probability = 0;
	param.nr_weight = 0;
	param.weight_label = NULL;
	param.weight = NULL;
	cross_validation = 0;
}

void do_cross_validation()
{
	int i;
	int total_correct = 0;
	double total_error = 0;
	double sumv = 0, sumy = 0, sumvv = 0, sumyy = 0, sumvy = 0;
	double *target = Malloc(double,prob.l);

	svm_cross_validation(&prob,&param,nr_fold,target);
	if(param.svm_type == EPSILON_SVR ||
	   param.svm_type == NU_SVR)
	{
		for(i=0;i<prob.l;i++)
		{
			double y = prob.y[i];
			double v = target[i];
			total_error += (v-y)*(v-y);
			sumv += v;
			sumy += y;
			sumvv += v*v;
			sumyy += y*y;
			sumvy += v*y;
		}
		printf("Cross Validation Mean squared error = %g\n",total_error/prob.l);
		printf("Cross Validation Squared correlation coefficient = %g\n",
			((prob.l*sumvy-sumv*sumy)*(prob.l*sumvy-sumv*sumy))/
			((prob.l*sumvv-sumv*sumv)*(prob.l*sumyy-sumy*sumy))
			);
	}
	else
	{
		for(i=0;i<prob.l;i++)
			if(target[i] == prob.y[i])
				++total_correct;
		printf("Cross Validation Accuracy = %g%%\n",100.0*total_correct/prob.l);
	}
	free(target);
}


