# Ruby test suite for Chrest
# Assumes base of compiled Chrest code is on the CLASSPATH
# e.g. jruby -J-cp bin all-chrest-tests.rb

require "java" 
require "modellers_testing_framework"
include TestFramework

# Import all required classes
import "java.util.ArrayList"

[
  "Chrest", 
  "Node", 
  "MindsEye"
].each do |klass|
  import "jchrest.architecture.#{klass}"
end
[
  "ChessDomain",
  "GenericDomain",
  "ItemSquarePattern",
  "ListPattern",
  "Modality",
  "MindsEyeObject",
  "MindsEyeMoveObjectException",
  "NumberPattern",
  "Pattern",
  "ReinforcementLearning",
  "Scene",
  "Square",
  "StringPattern",
  "TileworldDomain"
].each do |klass|
  import "jchrest.lib.#{klass}"
end

# Pick up all ruby test files except this one
Dir.glob(File.dirname(__FILE__) + "/*.rb") do |file|
  require file unless File.expand_path(file) == File.expand_path(__FILE__)
end

puts "Testing CHREST:"
TestFramework.run_all_tests
