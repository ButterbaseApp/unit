# Run Avram integration specs separately
# This file is only run when Avram is available as a development dependency
#
# To run these specs:
#   crystal spec spec/avram_integration_spec.cr

require "./spec_helper"
require "avram"
require "./unit/integrations/avram_spec_helper_spec"
require "./unit/integrations/avram/**"

puts "Running Avram integration specs..."
