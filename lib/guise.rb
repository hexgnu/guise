require 'sanitize'
require 'hex-svm'
require 'yaml'
require File.join(File.dirname(__FILE__), 'guise_native')
Dir[File.join(File.dirname(__FILE__), "./guise/*.rb")].each do |requirement|
  require requirement
end