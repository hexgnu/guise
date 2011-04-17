require 'sanitize'
require File.join(File.dirname(__FILE__), 'guise_native')
Dir[File.join(File.dirname(__FILE__), "./guise/*.rb")].each do |requirement|
  require requirement
end