# load mkmf
require 'mkmf'

have_header('libsvm-3.1/svm.h')

# $CFLAGS << " -Wall -Wconversion -O3 -fPIC"
# guise gem with libsvm underneath

extension_name = 'guise_native'

# destination
dir_config(extension_name)
create_header
create_makefile(extension_name)