# Overall tests of Chrest

# Use this to access the 'check_visual_spatial_field_against_expected' and 
# 'expected_fixations_made' methods for the tests checking the visual-spatial 
# field.
#require 'visual-spatial-field-tests' 

#unit_test "get maximum clock value" do
#  model = Chrest.new(0, GenericDomain.java_class)
#  
#  #Set the learning clock to a value less than the attention clock.
#  model.setAttentionClock(200)
#  model.setLearningClock(199)
#  assert_equal(model.getAttentionClock(), model.getMaximumClockValue())
#  
#  #Now set the learning clock so it is equal to the attention clock.
#  model.setLearningClock(200)
#  assert_equal(model.getAttentionClock(), model.getMaximumClockValue())
#  
#  #Finally, set the learning clock so it is greater than the attention clock.
#  model.setLearningClock(201)
#  assert_equal(model.getLearningClock(), model.getMaximumClockValue())
#end

# Learning affects both the cognitive and attention clocks since information
# needs be sorted and added to LTM (cognition required), after sorting, the 
# retrieved node is also added to STM (attention required).  This test therefore
# focuses on checking the attention and cognitive clocks to see if they are set
# as expected.
process_test "recogniseAndLearn" do
  
  ##################
  ### TEST SETUP ###
  ##################
  
  # Set test time since learning is all about time
  test_time = 0
  
  # Create new CHREST model
  model = Chrest.new(test_time, GenericDomain.java_class)
  
  # Learning parameter setup
  model.setLtmLinkTraversalTime(10)
  model.setFamiliarisationTime(2000)
  model.setDiscriminationTime(10000)
  model.setMaximumSemanticLinkSearchDistance(2)
  model.setTimeToUpdateStm(50)
  model.setRho(1.0) #The model will never randomly refuse to learn.
  
  # Construct patterns to learn.
  patternA = Pattern.makeVisualList(["B", "I", "F"].to_java(:String))
  patternB = Pattern.makeVisualList(["X", "A", "Q"].to_java(:String))
  
  #############
  ### TESTS ###
  #############
  
  # Check that the attention and cognition clocks are setup as expected.
  assert_equal(test_time - 1, model.getAttentionClock(), "see test 1")
  assert_equal(test_time - 1, model.getCognitionClock(), "see test 2")
  
  ##############################################################################
  # Trigger discrimination: new node for 'B' (ref: 3) should be created (node 
  # 3's image will be empty).
  model.recogniseAndLearn(patternA, test_time)
  
  # Since LTM is empty expect for modality root nodes, patternA's modality just
  # needs to be sorted incurring 1 LTM link traversal time cost.
  sorting_time = test_time + model.getLtmLinkTraversalTime()
  
  expected_attention_clock = sorting_time + model.getTimeToUpdateStm()
  expected_cognition_clock = test_time + model.getLtmLinkTraversalTime() + model.getDiscriminationTime()
  assert_equal(expected_attention_clock, model.getAttentionClock(), "see test 3")
  assert_equal(expected_cognition_clock, model.getCognitionClock(), "see test 4")
  
  ##############################################################################
  # Trigger familiarisation: node 3 should have 'B' added to its image.
  test_time = model.getCognitionClock() # Set test time to that the 
                                        # 'recogniseAndLearn' invocation will 
                                        # not be ignored due to cognitive 
                                        # resources not being available at the
                                        # time of invocation.
  model.recogniseAndLearn(patternA, test_time) 
  
  # When patternA is input for learning, its modality will be sorted and then 
  # the test link that connects the modality root to node 3 will be traversed.
  sorting_time = test_time + (model.getLtmLinkTraversalTime() * 2)
  
  expected_attention_clock = sorting_time + model.getTimeToUpdateStm()
  expected_cognition_clock = sorting_time + model.getFamiliarisationTime()
  assert_equal(expected_attention_clock, model.getAttentionClock(), "see test 5")
  assert_equal(expected_cognition_clock, model.getCognitionClock(), "see test 6")
  
  ##############################################################################
  # Check that the model does not learn new information when its cognitive 
  # resources are busy.
  test_time = model.getCognitionClock() - 1
  model.recogniseAndLearn(patternB, test_time)
  
  assert_equal(expected_attention_clock, model.getAttentionClock(), "see test 7")
  assert_equal(expected_cognition_clock, model.getCognitionClock(), "see test 8")
  assert_equal(1, model.getLtmSize(model.getCognitionClock()), "see test 9")

  ##############################################################################
  # Trigger discrimination: new node for 'I' (ref: 4) should be created (node 
  # 4's image will be empty).
  test_time = model.getCognitionClock() # Set test time to that the 
                                        # 'recogniseAndLearn' invocation will 
                                        # not be ignored due to cognitive 
                                        # resources not being available at the
                                        # time of invocation.
  model.recogniseAndLearn(patternA, test_time)
  
  # When patternA is input for learning, its modality will be sorted and then 
  # the test link that connects the modality root to node 3 will be traversed.
  sorting_time = test_time + (model.getLtmLinkTraversalTime() * 2)
  
  expected_attention_clock = sorting_time + model.getTimeToUpdateStm()
  expected_cognition_clock = sorting_time + model.getDiscriminationTime()
  assert_equal(expected_attention_clock, model.getAttentionClock(), "see test 10")
  assert_equal(expected_cognition_clock, model.getCognitionClock(), "see test 11")
  
  ##############################################################################
  # Trigger familiarisation: node 3 should have 'I' added to its image.
  test_time = model.getCognitionClock() # Set test time to that the 
                                        # 'recogniseAndLearn' invocation will 
                                        # not be ignored due to cognitive 
                                        # resources not being available at the
                                        # time of invocation.
  model.recogniseAndLearn(patternA, test_time)
  
  # When patternA is input for learning, its modality will be sorted and then 
  # the test link that connects the modality root to node 3 will be traversed.
  sorting_time = test_time + (model.getLtmLinkTraversalTime() * 2)
  
  expected_attention_clock = sorting_time + model.getTimeToUpdateStm()
  expected_cognition_clock = sorting_time + model.getFamiliarisationTime()
  assert_equal(expected_attention_clock, model.getAttentionClock(), "see test 12")
  assert_equal(expected_cognition_clock, model.getCognitionClock(), "see test 13")
  
  ##############################################################################
  # Trigger discrimination: new node for 'F' (ref: 5) should be created (node 
  # 5's image will be empty).
  test_time = model.getCognitionClock() # Set test time to that the 
                                        # 'recogniseAndLearn' invocation will 
                                        # not be ignored due to cognitive 
                                        # resources not being available at the
                                        # time of invocation.
  model.recogniseAndLearn(patternA, test_time)
  
  # When patternA is input for learning, its modality will be sorted and then 
  # the test link that connects the modality root to node 3 will be traversed.
  sorting_time = test_time + (model.getLtmLinkTraversalTime() * 2)
  
  expected_attention_clock = sorting_time + model.getTimeToUpdateStm()
  expected_cognition_clock = sorting_time + model.getDiscriminationTime()
  assert_equal(expected_attention_clock, model.getAttentionClock(), "see test 14")
  assert_equal(expected_cognition_clock, model.getCognitionClock(), "see test 15")
  
  ##############################################################################
  # Trigger familiarisation: node 3 should have 'F' added to its image.
  test_time = model.getCognitionClock() # Set test time to that the 
                                        # 'recogniseAndLearn' invocation will 
                                        # not be ignored due to cognitive 
                                        # resources not being available at the
                                        # time of invocation.
  model.recogniseAndLearn(patternA, test_time)
  
  # When patternA is input for learning, its modality will be sorted and then 
  # the test link that connects the modality root to node 3 will be traversed.
  sorting_time = test_time + (model.getLtmLinkTraversalTime() * 2)
  
  expected_attention_clock = sorting_time + model.getTimeToUpdateStm()
  expected_cognition_clock = sorting_time + model.getFamiliarisationTime()
  assert_equal(expected_attention_clock, model.getAttentionClock(), "see test 16")
  assert_equal(expected_cognition_clock, model.getCognitionClock(), "see test 17")
  
  ##############################################################################
  # No change triggered: when patternA is input for learning again, the model 
  # should recognise that it has been fully learned so the cognition and 
  # attention clocks should be set to the times associated with recognition only
  # (no learning should occur).
  test_time = model.getCognitionClock() # Set test time to that the 
                                        # 'recogniseAndLearn' invocation will 
                                        # not be ignored due to cognitive 
                                        # resources not being available at the
                                        # time of invocation.
  model.recogniseAndLearn(patternA, test_time)
  
  # When patternA is input for learning, its modality will be sorted and then 
  # the test link that connects the modality root to node 3 will be traversed.
  sorting_time = test_time + (model.getLtmLinkTraversalTime() * 2)
  
  expected_attention_clock = sorting_time + model.getTimeToUpdateStm()
  expected_cognition_clock = sorting_time
  assert_equal(expected_attention_clock, model.getAttentionClock(), "see test 18")
  assert_equal(expected_cognition_clock, model.getCognitionClock(), "see test 19")
end

#process_test "base case" do
#  model = Chrest.new
#  emptyList = Pattern.makeVisualList([].to_java(:int))
#  assert_true(Pattern.makeVisualList(["Root"].to_java(:String)).equals(model.recognise(emptyList, 0).getImage))
#end
#
#process_test "learning case 1" do
#  # Every item that is learnt must first be learnt at the top-level,
#  # as a primitive.  Learning that top-level node is done with an empty image.
#  model = Chrest.new
#  emptyList = Pattern.makeVisualList([].to_java(:int))
#  list = Pattern.makeVisualList([1,2,3,4].to_java(:int))
#  list.setFinished
#  prim = Pattern.makeVisualList([1].to_java(:int))
#  prim_test = Pattern.makeVisualList([1].to_java(:int))
#  prim.setFinished
#
#  model.recogniseAndLearn list
#  assert_equal(1, model.getLtmByModality(list).getChildren.size)
#
#  firstChild = model.getLtmByModality(list).getChildren.get(0)
#  assert_false(emptyList.equals(firstChild.getChildNode.getContents))
#  assert_true(firstChild.getTest.equals(prim_test))
#  assert_true(firstChild.getChildNode.getContents.equals(prim_test))
#  assert_true(firstChild.getChildNode.getImage.equals(emptyList))
#end
#
#process_test "learning case 2" do
#  # Same as 'learning case 1', but using item-on-square instead of simple numbers
#  model = Chrest.new
#  emptyList = ListPattern.new
#  list = ListPattern.new
#  list.add ItemSquarePattern.new("P", 1, 2)
#  list.add ItemSquarePattern.new("P", 2, 2)
#  list.add ItemSquarePattern.new("P", 3, 2)
#  list.add ItemSquarePattern.new("P", 4, 2)
#  list.setFinished
#  prim= ListPattern.new
#  prim.add ItemSquarePattern.new("P", 1, 2)
#  prim_test = prim.clone
#  prim.setFinished
#
#  model.recogniseAndLearn list
#  assert_equal(1, model.getLtmByModality(list).getChildren.size)
#
#  firstChild = model.getLtmByModality(list).getChildren.get(0)
#  assert_false(emptyList.equals(firstChild.getChildNode.getContents))
#  assert_true(firstChild.getTest.equals(prim_test))
#  assert_true(firstChild.getChildNode.getContents.equals(prim_test))
#  assert_true(firstChild.getChildNode.getImage.equals(emptyList))
#end
#
#process_test "simple retrieval 1" do
#  # Check that after learning a primitive, the model will retrieve 
#  # that node on trying to recognise the list
#  model = Chrest.new
#  list = Pattern.makeVisualList([1,2,3,4].to_java(:int))
#  list.setFinished
#  emptyList = Pattern.makeVisualList([].to_java(:int))
#  prim = Pattern.makeVisualList([1].to_java(:int))
#  prim_test = Pattern.makeVisualList([1].to_java(:int))
#  prim.setFinished
#
#  model.recogniseAndLearn(list, 0)
#  node = model.recognise(list, 0)
#
#  assert_false emptyList.equals(node.getContents)
#  assert_true prim_test.equals(node.getContents)
#  assert_true emptyList.equals(node.getImage)
#end
#
#process_test "simple learning 2" do
#  model = Chrest.new
#  list = Pattern.makeVisualList([1,2,3,4].to_java(:int))
#  list2 = Pattern.makeVisualList([2,3,4].to_java(:int))
#  list3 = Pattern.makeVisualList([1,3,4].to_java(:int))
#  list3_test = Pattern.makeVisualList([1,3].to_java(:int))
#  emptyList = Pattern.makeVisualList([].to_java(:int))
#  prim1 = Pattern.makeVisualList [1].to_java(:int)
#  prim2 = Pattern.makeVisualList [2].to_java(:int)
#
#  model.recogniseAndLearn list2
#  model.recogniseAndLearn list
#  assert_equal(2, model.getLtmByModality(list).getChildren.size)
#  # check most recent becomes the first child node
#  assert_true prim1.equals(model.getLtmByModality(list).getChildren.get(0).getChildNode.getContents)
#  assert_true prim2.equals(model.getLtmByModality(list).getChildren.get(1).getChildNode.getContents)
#  # force discriminate from node 0
#  # by first overlearning
#  model.recogniseAndLearn list
#  model.recogniseAndLearn list
#  assert_true model.recognise(list, 0).getImage.equals(Pattern.makeVisualList([1,2].to_java(:int)))
#  node = model.getLtmByModality(list).getChildren.get(0).getChildNode
#  assert_equal(0, node.getChildren.size)
#  model.recogniseAndLearn list3 # first learn the '3' to use as test
#  model.recogniseAndLearn list3 # now trigger discrimination
#  assert_equal(1, node.getChildren.size)
#  assert_true list3_test.equals(node.getChildren.get(0).getChildNode.getImage)
#  assert_true list3_test.equals(node.getChildren.get(0).getChildNode.getContents)
#  # and familiarise
#  node = node.getChildren.get(0).getChildNode
#  model.recogniseAndLearn list3
#  model.recogniseAndLearn list3
#  assert_true list3.equals(node.getImage)
#end
#
#process_test "check learning of < $ >" do
#  model = Chrest.new
#  list1 = Pattern.makeVisualList(["A", "B", "C"].to_java(:String))
#  list2 = Pattern.makeVisualList(["A", "B"].to_java(:String))
#  8.times do 
#    model.recogniseAndLearn list1
#  end
#  assert_true list1.equals(model.recallPattern(list1, model.getLearningClock()))
#  assert_true list1.equals(model.recallPattern(list2, model.getLearningClock()))
#  node = model.recognise(list2, model.getLearningClock())
#  assert_true list1.equals(node.getImage)
#  # learning should result in discrimination with < $ >
#  model.recogniseAndLearn(list2, model.getLearningClock())
#  assert_equal(1, node.getChildren.size)
#end
#
#process_test "full learning" do 
#  model = Chrest.new
#  list1 = Pattern.makeVisualList([3,4].to_java(:int))
#  list2 = Pattern.makeVisualList([1,2].to_java(:int))
#
#  20.times do 
#    model.recogniseAndLearn list1
#    model.recogniseAndLearn list2
#  end
#
#  assert_true list1.equals(model.recallPattern(list1, model.getLearningClock()))
#  assert_true list2.equals(model.recallPattern(list2, model.getLearningClock()))
#end
#
##The aim of this test is to check for the correct operation of setting a CHREST
##instance's "_reinforcementLearningTheory" variable.  The following tests are
##run:
## 1) After creating a new CHREST instance, its "_reinforcementLearningTheory" 
## variable should be set to null.
## 2) You should be able to set a CHREST instance's "_reinforcementLearningTheory" 
## variable if it is currently set to null.
## 3) You should not be able to set a CHREST instance's "_reinforcementLearningTheory"
## variable if it is not currently set to null.
#process_test "set reinforcement learning theory" do
#  model = Chrest.new
#  
#  #Test 1.
#  validReinforcementLearningTheories = ReinforcementLearning.getReinforcementLearningTheories()
#  assert_equal("null", model.getReinforcementLearningTheory, "See test 1.")
#  
#  #Test 2.
#  model.setReinforcementLearningTheory(validReinforcementLearningTheories[0])
#  assert_equal(validReinforcementLearningTheories[0].to_s, model.getReinforcementLearningTheory, "See test 2.")
#  
#  #Test 3.
#  model.setReinforcementLearningTheory(nil)
#  assert_equal(validReinforcementLearningTheories[0].to_s, model.getReinforcementLearningTheory, "See test 3.")
#end
#
##The aim of this test is to check for the correct operation of all implemented
##reinforcement theories in the jchrest.lib.ReinforcementLearning class in the
##CHREST architecture. A visual and action pattern are created and fully
##committed to LTM before associating them (thus creating a production).  The
##following tests are then run:
##
## 1) The action should be a production for the visual node.
## 2) The value of the production should be set to 0.0.
## 3) Too few variables are passed to a reinforcement learning theory.  This 
##    should result in boolean 'false' being returned.
## 4) Too many variables are passed to a reinforcement learning theory.  This 
##    should result in boolean 'false' being returned.
## 5) Passing the correct number of variables to a reinforcement learning theory 
##    should return:
##    a) Boolean true.
##    b) An expected value.
## 6) Applying the value returned in 5 to the production created earlier should
##    result in the production's value equalling an expected value.
#process_test "reinforcement theory tests" do
#  
#  #Retrieve all currently implemented reinforcement learning theories.
#  reinforcement_learning_theories = ReinforcementLearning.getReinforcementLearningTheories()
#  
#  #Construct a test visual pattern.
#  visual_pattern = Pattern.makeVisualList [1].to_java(:int)
#  visual_pattern_string = visual_pattern.toString
#  
#  #Construct a test action pattern.
#  action_pattern = Pattern.makeActionList ["A"].to_java(:string)
#  action_pattern_string = action_pattern.toString
#  
#  #Test each reinforcement learning theory implemented in the CHREST 
#  #architecture.
#  reinforcement_learning_theories.each do |reinforcement_learning_theory|
#    
#    #Create a new CHREST model instance and set its reinforcement learning 
#    #theory to the one that is to be tested.
#    model = Chrest.new
#    model.setReinforcementLearningTheory(reinforcement_learning_theory)
#    reinforcement_learning_theory_name = reinforcement_learning_theory.toString
#  
#    #Learn visual and action patterns.
#    visual_chunk_string = ""
#    until visual_chunk_string.eql?(visual_pattern_string)
#      visual_chunk_string = model.recogniseAndLearn(visual_pattern, model.getLearningClock()).getImage().toString()
#    end
#    
#    action_chunk_string = ""
#    until action_chunk_string.eql?(action_pattern_string)
#      action_chunk_string = model.recogniseAndLearn(action_pattern, model.getLearningClock()).getImage().toString()
#    end
#
#    model.associateAndLearn(visual_pattern, action_pattern, model.getLearningClock())
#    
#    productions = model.recognise(visual_pattern, model.getLearningClock()).getProductions()
#    assert_equal(1, productions.size(), "occurred when checking the number of productions returned")
#    
#    action_chunk_is_production = false
#    production_value = 0.0
#    for production in productions.entrySet()
#      if production.getKey().getImage().toString().eql?(action_chunk_string)
#        action_chunk_is_production = true
#        production_value = production.getValue()
#      end
#    end
#    
#    assert_true(action_chunk_is_production, "occurred when checking if the action is a production.")
#    assert_equal(0.0, production_value, "occurred when checking the production's value")
#  
#    #Depending upon the model's current reinforcement learning theory, 5 
#    #variables should be created:
#    # 1) tooLittleVariables = an array of numbers whose length is less than the
#    #    number of variables needed by the current reinforcement theory to 
#    #    calculate a reinforcement value.
#    # 2) tooManyVariables = an array of numbers whose length is more than the
#    #    number of variables needed by the current reinforcement theory to 
#    #    calculate a reinforcement value.
#    # 3) correctVariables = an array of arrays.  Each inner array's length 
#    #    should equal the number of variables needed by the current 
#    #    reinforcement learning theory.
#    # 4) expectedCalculationValues = an array of numbers that should specify
#    #    the value returned by a reinforcement learning theory has been 
#    #    calculated.  There is a direct mapping between this array's indexes 
#    #    and the indexes of the "correctVariables" array i.e. the variables in 
#    #    index 0 of the "correctVariables" array should produce the variable 
#    #    stored in index 0 of the "expectedCalculationValues" array.
#    # 5) expectedReinforcementValues = an array of numbers that should specify 
#    #    the value returned by a reinforcement learning theory after a 
#    #    reinforcement value has been calculated AND added to the current 
#    #    reinforcement value between the visual node and action node.  There is 
#    #    a direct mapping between this array's indexes and the indexes of the 
#    #    "correctVariables" array i.e. the variables in index 0 of the 
#    #    "correctVariables" array should produce the variable stored in index 0 
#    #    of the "expectedReinforcementValues" array after adding the calculated
#    #    reinforcement value to the current reinforcement value between the 
#    #    visual and action node.
#    too_few = []
#    too_many = []
#    just_right = []
#    expected_reinforcement_values = []
#    expected_production_values = []
#    case 
#      when reinforcement_learning_theory_name.casecmp("profit_sharing_with_discount_rate").zero?
#        too_few = [1].to_java(:Double)
#        too_many = [1,2,3,4,5].to_java(:Double)
#        just_right = [
#          [1,0.5,2,2].to_java(:Double),
#          [1,0.5,2,1].to_java(:Double)
#        ]
#        expected_reinforcement_values = [1,0.5].to_java(:Double)
#        expected_production_values = [1,1.5].to_java(:Double)
#    end
#    
#    #Tests 4 and 5.
#    assert_false(reinforcement_learning_theory.correctNumberOfVariables(too_few), "FOR " + reinforcement_learning_theory_name + ": The number of variables in the 'tooFewVariables' parameter is not incorrect.")
#    assert_false(reinforcement_learning_theory.correctNumberOfVariables(too_many), "FOR " + reinforcement_learning_theory_name + ": The number of variables in the 'tooManyVariables' parameter is not incorrect.")
#    
#    #Tests 6, 7 and 8.
#    index = 0
#    just_right.each do |variables|
#      assert_true(reinforcement_learning_theory.correctNumberOfVariables(variables), "FOR " + reinforcement_learning_theory_name + ": The number of variables in item " + index.to_s + " of the 'correctvariables' parameter is incorrect.")
#      
#      reinforcement_value = reinforcement_learning_theory.calculateReinforcementValue(variables)
#      assert_equal(expected_reinforcement_values[index], reinforcement_value, "occurred when checking the reinforcement value returned by the " + reinforcement_learning_theory_name  + " theory.")
#      
#      model.reinforceProduction(visual_pattern, action_pattern, variables, model.getLearningClock())
#      production_value = model.recognise(visual_pattern, model.getLearningClock()).getProductions().values()[0]
#      assert_equal(expected_production_values[index], production_value, ".")
#      index += 1
#    end
#  end
#end
#
#################################################################################
## Tests that the Scenes recalled after scanning a Scene at various points in 
## time are as expected.  Also tests that a visual-spatial field generated by the
## original Scene is updated as expected after moving objects in the 
## visual-spatial field and scanning the resulting Scene generated.  This is done 
## by modelling the following scenario:
## 
## 1) A Scene is created and scanned by CHREST and the Scene recalled is tested
##    to see if it is as expected: the recalled Scene should contain no 
##    recognised objects (completely blind).
## 2) CHREST learns two list patterns: the first refers to objects that will be
##    recognised when the Scene is scanned again and when the visual-spatial 
##    field is first generated from the original Scene.  The second refers to 
##    objects that will be recognised when objects have been moved in the 
##    visual-spatial field and a Scene is generated from the resulting 
##    visual-spatial field and scanned again.
## 3) The original Scene is scanned again after learning the list patterns and 
##    the recalled Scene is tested: the recalled Scene should contain two 
##    recognised objects.
## 4) CHREST constructs a visual-spatial field from the original Scene and both 
##    the visual-spatial field constructed and the Scene generated by getting the
##    contents of the visual-spatial field as a Scene are checked to see if they
##    are as expected: two of the objects should be recognised.
## 3) Objects on the visual-spatial field are moved and both the resulting 
##    visual-spatial field and the Scene generated by getting the contents of the 
##    visual-spatial field as a Scene are checked to see if they are as expected: 
##    none of the objects should be recognised.
## 4) Objects on the visual-spatial field are moved again and both the resulting 
##    visual-spatial field and the Scene generated by getting the contents of the 
##    visual-spatial field as a Scene are checked to see if they are as expected:
##    one of the previously recognised objects should now be recognised again 
##    along with an object that was not previously recognised at any point in 
##    this test.
##    
## The initial Scene used is illustrated below ("x" represents a blind square, 
## real objects are denoted by their identifiers and their class are in 
## parenthesis).
## 
##                  --------
## 4     x      x   | 2(A) |  x      x
##           ----------------------
## 3     x   | 1(B) |      |      |  x
##    ------------------------------------
## 2  |      | 0(A) |      | 3(D) |      |
##    ------------------------------------
## 1     x   |      |      |      |  x
##           ----------------------
## 0     x      x   | 4(G) |  x      x
##                  --------
##       0      1      2      3      4     COORDINATES
#process_test "scan_scene (no creator in scene)" do
#  
#  #####################################
#  ##### UBIQUITOUS TEST VARIABLES #####
#  #####################################
#  
#  objects = [
#    ["0", "A"],
#    ["1", "B"],
#    ["2", "A"],
#    ["3", "D"],
#    ["4", "G"]
#  ]
#  
#  # Test clock, the time by which all CHREST and visual-spatial field operations
#  # are coordinated by.
#  domain_time = 0
#  
#  # Visual-spatial field parameters
#  object_encoding_time = 10
#  empty_square_encoding_time = 5
#  access_time = 100
#  object_movement_time = 50
#  recognised_object_lifespan = 40000
#  unrecognised_object_lifespan = 20000
#  number_fixations = 20
#  
#  ###########################
#  ##### CONSTRUCT SCENE #####
#  ###########################
#  
#  scene = Scene.new("scene", 5, 5, nil)
#  scene.addItemToSquare(2, 0, objects[4][0], objects[4][1])
#  scene.addItemToSquare(1, 1, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(2, 1, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(3, 1, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(0, 2, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(1, 2, objects[0][0], objects[0][1])
#  scene.addItemToSquare(2, 2, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(3, 2, objects[3][0], objects[3][1])
#  scene.addItemToSquare(4, 2, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(1, 3, objects[1][0], objects[1][1])
#  scene.addItemToSquare(2, 3, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(3, 3, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(2, 4, objects[2][0], objects[2][1])
#  
#  ##############################
#  ##### INSTANTIATE CHREST #####
#  ##############################
#  
#  model = Chrest.new
#  model.setDomain(GenericDomain.new(model))
#  model.getPerceiver().setFieldOfView(1)
#  
#  ######################################
#  ##### SCAN SCENE AND TEST RECALL #####
#  ######################################
#  
#  recalled_scene = model.scanScene(scene, number_fixations, true, domain_time, false)
#  
#  expected_recalled_scene = Array.new
#  for col in 0...scene.getWidth()
#    expected_recalled_scene.push(Array.new)
#    for row in 0...scene.getHeight()
#      expected_recalled_scene[col].push([
#        Scene.getBlindSquareToken(),
#        Scene.getBlindSquareToken()
#      ])
#    end
#  end
#  
#  check_scene_against_expected(recalled_scene, expected_recalled_scene, "before learning.")
#  
#  ###########################
#  ##### CHREST LEARNING #####
#  ###########################
#  
#  # Create a list pattern that is recognised in the original scene state:
#  # <[A 1 2][B 1 3]>
#  list_pattern_1 = ListPattern.new
#  list_pattern_1.add(ItemSquarePattern.new(objects[0][1], 1, 2))
#  list_pattern_1.add(ItemSquarePattern.new(objects[1][1], 1, 3))
#  
#  # Create a list pattern that isn't recognised in the original scene state but 
#  # will be after B is moved: <[B 3 1][A 2 4]>
#  list_pattern_2 = ListPattern.new
#  list_pattern_2.add(ItemSquarePattern.new(objects[1][1], 3, 3))
#  list_pattern_2.add(ItemSquarePattern.new(objects[2][1], 2, 4))
#  
#  list_patterns_to_learn = Array.new
#  list_patterns_to_learn.push(list_pattern_1)
#  list_patterns_to_learn.push(list_pattern_2)
#  
#  for list_pattern in list_patterns_to_learn
#    recognised_chunk = model.recogniseAndLearn(list_pattern, domain_time).getImage()
#    until recognised_chunk.contains(list_pattern.getItem(list_pattern.size()-1))
#      recognised_chunk = model.recogniseAndLearn(list_pattern, domain_time).getImage()
#      domain_time += 1
#    end
#  end
#  
#  ######################################
#  ##### SCAN SCENE AND TEST RECALL #####
#  ######################################
#  
#  # Since CHREST's fixations are somewhat random when scanning a scene, it may 
#  # be that, after scanning the scene in question, objects 0 and 1 are not 
#  # recognised.  So, in order to test the contents of the expected recalled 
#  # scene reliably after scanning, scan the scene until CHREST's STM contains 
#  # the first list pattern learned before.
#  visual_stm_contents_as_expected = false
#  expected_stm_contents = list_patterns_to_learn[0].toString()
#  
#  until visual_stm_contents_as_expected do
#    recalled_scene = model.scanScene(scene, number_fixations, true, domain_time, false)
#    
#    stm = model.getVisualStm()
#    stm_contents = ""
#    for i in (stm.getCount() - 1).downto(0)
#      chunk = stm.getItem(i)
#      if( !chunk.equals(model.getVisualLtm()) )
#        if(!chunk.getImage().isEmpty())
#          stm_contents += chunk.getImage().toString()
#        end
#      end
#    end
#
#    expected_stm_contents == stm_contents ? visual_stm_contents_as_expected = true : nil
#  end
#  
#  # The scene recalled should be entirely blind except for objects on 
#  # coordinates (1, 2) and (1, 3)
#  expected_recalled_scene = Array.new
#  for col in 0...scene.getWidth()
#    expected_recalled_scene.push(Array.new)
#    for row in 0...scene.getHeight()
#      expected_recalled_scene[col].push([
#        Scene.getBlindSquareToken(),
#        Scene.getBlindSquareToken()
#      ])
#    end
#  end
#  
#  expected_recalled_scene[1][2][0] = objects[0][0]
#  expected_recalled_scene[1][2][1] = objects[0][1]
#  
#  expected_recalled_scene[1][3][0] = objects[1][0]
#  expected_recalled_scene[1][3][1] = objects[1][1]
#  
#  check_scene_against_expected(recalled_scene, expected_recalled_scene, "after learning.")
#  
#  ############################################
#  ##### INSTANTIATE VISUAL-SPATIAL FIELD #####
#  ############################################
#
#  visual_spatial_field_creation_time = domain_time
#  
#  visual_stm_contents_as_expected = false
#  expected_stm_contents = list_patterns_to_learn[0].toString()
#  
#  expected_fixations_made = false
#  fixations_expected = [
#    [2, 0],
#    [1, 2],
#    [3, 2],
#    [1, 3],
#    [2, 4]
#  ]
#
#  # Need to ensure that the visual-spatial field is instantiated according to 
#  # what has been learned in order to set expected test output correctly.
#  until visual_stm_contents_as_expected and expected_fixations_made do
#    
#    visual_stm_contents_as_expected = false
#    expected_fixations_made = false
#
#    # Set creation time to the current domain time (this is important in 
#    # calculating a lot of test variables below).
#    visual_spatial_field_creation_time = domain_time
#
#    # Construct the visual-spatial field.
#    visual_spatial_field = VisualSpatialField.new(
#      model,
#      scene, 
#      object_encoding_time,
#      empty_square_encoding_time,
#      access_time, 
#      object_movement_time, 
#      recognised_object_lifespan,
#      unrecognised_object_lifespan,
#      number_fixations,
#      domain_time,
#      false,
#      false
#    )
#
#    # Get contents of STM (will have been populated during object 
#    # recognition during visual-spatial field construction) and remove root 
#    # nodes and nodes with empty images.  This will leave retrieved chunks 
#    # that have non-empty images, i.e. these images should contain the 
#    # list-patterns learned by the model.
#    stm = model.getVisualStm()
#    stm_contents = ""
#    for i in (stm.getCount() - 1).downto(0)
#      chunk = stm.getItem(i)
#      if( !chunk.equals(model.getVisualLtm()) )
#        if(!chunk.getImage().isEmpty())
#          stm_contents += chunk.getImage().toString()
#        end
#      end
#    end
#
#    # Check if STM contents are as expected, if they are, set the flag that
#    # controls when the model is ready for testing to true.
#    expected_stm_contents == stm_contents ? visual_stm_contents_as_expected = true : nil
#    
#    expected_fixations_made = expected_fixations_made?(model, fixations_expected)
#
#    # Advance domain time to the time that the visual-spatial field will be 
#    # completely instantiated so that the model's attention will be free 
#    # should a new visual-field need to be constructed.
#    domain_time = model.getAttentionClock
#  end
#  
#  #####################################
#  ##### TEST VISUAL-SPATIAL FIELD #####
#  #####################################
#  
#  # The first VisualSpatialFieldObject on each coordinate is expected to be a 
#  # blind square.
#  expected_visual_spatial_field_object_properties = Array.new
#  for col in 0...scene.getWidth()
#    expected_visual_spatial_field_object_properties.push(Array.new)
#    for row in 0...scene.getHeight()
#      expected_visual_spatial_field_object_properties[col].push(Array.new)
#      expected_visual_spatial_field_object_properties[col][row].push([
#        Scene.getBlindSquareToken, #Expected ID
#        Scene.getBlindSquareToken, #Expected class
#        visual_spatial_field_creation_time + access_time, #Expected creation time.
#        nil, #Expected lifespan (not exact terminus) of the object.
#        false, #Expected recognised status
#        false # Expected ghost status
#      ])
#    end
#  end
#  
#  # Set expected values for coordinates containing recognised objects first.
#  expected_visual_spatial_field_object_properties[1][2][0][3] = visual_spatial_field_creation_time + access_time + object_encoding_time
#  expected_visual_spatial_field_object_properties[1][2].push([
#    objects[0][0],
#    objects[0][1],
#    visual_spatial_field_creation_time + access_time + object_encoding_time,
#    visual_spatial_field_creation_time + access_time + object_encoding_time + recognised_object_lifespan,
#    true,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[1][3][0][3] = visual_spatial_field_creation_time + access_time + object_encoding_time
#  expected_visual_spatial_field_object_properties[1][3].push([
#    objects[1][0],
#    objects[1][1],
#    visual_spatial_field_creation_time + access_time + object_encoding_time,
#    visual_spatial_field_creation_time + access_time + object_encoding_time + recognised_object_lifespan,
#    true,
#    false
#  ])
#
#  # Set expected values for coordinates containing unrecognised objects second. 
#  expected_visual_spatial_field_object_properties[2][0][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 2)
#  expected_visual_spatial_field_object_properties[2][0].push([
#    objects[4][0],
#    objects[4][1],
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[1][1][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + empty_square_encoding_time
#  expected_visual_spatial_field_object_properties[1][1].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + empty_square_encoding_time,
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + empty_square_encoding_time + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[2][1][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 2)
#  expected_visual_spatial_field_object_properties[2][1].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 2),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 2) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[3][1][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 3)
#  expected_visual_spatial_field_object_properties[3][1].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 3),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 3) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[0][2][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 4)
#  expected_visual_spatial_field_object_properties[0][2].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 4),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 4) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[2][2][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 5)
#  expected_visual_spatial_field_object_properties[2][2].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 5),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 5) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[3][2][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 5)
#  expected_visual_spatial_field_object_properties[3][2].push([
#    objects[3][0],
#    objects[3][1],
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 5),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 5) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[4][2][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 6)
#  expected_visual_spatial_field_object_properties[4][2].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 6),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 6) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[2][3][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 7)
#  expected_visual_spatial_field_object_properties[2][3].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 7),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 7) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[3][3][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 8)
#  expected_visual_spatial_field_object_properties[3][3].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 8),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 8) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[2][4][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 4) + (empty_square_encoding_time * 8)
#  expected_visual_spatial_field_object_properties[2][4].push([
#    objects[2][0],
#    objects[2][1],
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 4) + (empty_square_encoding_time * 8),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 4) + (empty_square_encoding_time * 8) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  check_visual_spatial_field_against_expected(
#    visual_spatial_field, 
#    expected_visual_spatial_field_object_properties,
#    model.getAttentionClock(),
#    "before moving objects."
#  )
#  
#  ########################
#  ##### MOVE OBJECTS #####
#  ########################
#  
#  # <[A 1 2][B 1 3]> are recognised in the visual-spatial field now so move 
#  # these objects so that they should be unrecognisable when the scene is next 
#  # scanned.  The resulting visual-spatial field should look like the following:
#  #
#  #                  --------
#  # 4     x      x   | 2(A) |  x      x
#  #           ----------------------
#  # 3     x   |      |      |      |  x
#  #    ------------------------------------
#  # 2  | 0(A) |      |      | 3(D) |      |
#  #    ------------------------------------
#  # 1     x   |      |      | 1(B) |  x
#  #           ----------------------
#  # 0     x      x   | 4(G) |  x      x
#  #                  --------
#  #       0      1      2      3      4     COORDINATES
#  a_move = ArrayList.new
#  a_move.add(ItemSquarePattern.new(objects[0][0], 1, 2))
#  a_move.add(ItemSquarePattern.new(objects[0][0], 0, 2))
#  
#  b_move = ArrayList.new
#  b_move.add(ItemSquarePattern.new(objects[1][0], 1, 3))
#  b_move.add(ItemSquarePattern.new(objects[1][0], 3, 1))
#  
#  a_and_b_moves = ArrayList.new
#  a_and_b_moves.add(a_move)
#  a_and_b_moves.add(b_move)
#  
#  time_move_requested = model.getAttentionClock()
#  visual_spatial_field.moveObjects(a_and_b_moves, time_move_requested, false)
#  
#  ######################################
#  ##### SCAN SCENE AND TEST RECALL #####
#  ######################################
#  
#  time_of_scan = model.getAttentionClock()
#  recalled_scene = model.scanScene(visual_spatial_field.getAsScene(time_of_scan, false), 20, true, time_of_scan, false)
#  
#  expected_recalled_scene = Array.new
#  for col in 0...scene.getWidth()
#    expected_recalled_scene.push(Array.new)
#    for row in 0...scene.getHeight()
#      expected_recalled_scene[col].push([
#        Scene.getBlindSquareToken(),
#        Scene.getBlindSquareToken()
#      ])
#    end
#  end
#  
#  check_scene_against_expected(recalled_scene, expected_recalled_scene, "after first move sequence.")
#  
#  #####################################
#  ##### TEST VISUAL-SPATIAL FIELD #####
#  #####################################
#  
#  # Assume at first that each VisualSpatialObject will have a terminus equal to 
#  # that of an unrecognised object.  Only set the terminus for 
#  # VisualSpatialObjects that are supposed to have a terminus (not currently set
#  # to null) and that are alive when the scene is scanned.
#  for col in 0...expected_visual_spatial_field_object_properties.count
#    for row in 0...expected_visual_spatial_field_object_properties[col].count
#      for object in 0...expected_visual_spatial_field_object_properties[col][row].count
#        terminus = expected_visual_spatial_field_object_properties[col][row][object][3]
#        if terminus != nil and terminus >= time_of_scan
#          terminus = time_of_scan + unrecognised_object_lifespan
#          expected_visual_spatial_field_object_properties[col][row][object][3] = terminus
#        end
#      end
#    end
#  end
#  
#  # Now the expected values for objects manipulated during the object move are
#  # set below.
#  
#  ##### SET EXPECTED TEST VALUES RELATED TO OBJECT 0 MOVEMENT #####
#  
#  # Set terminus of object 0 on (1, 2); the "pick-up" phase of the movement.
#  expected_visual_spatial_field_object_properties[1][2][1][3] = time_move_requested + access_time
#  
#  # Set expected values for the empty square placed on (1, 2) after object 0 is 
#  # "picked-up".
#  expected_visual_spatial_field_object_properties[1][2].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    time_move_requested + access_time,
#    time_of_scan + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#  
#  # Set terminus of empty square on (0, 2); the "putting-down" phase of movement
#  # where the coordinates are no longer considered to be empty.
#  expected_visual_spatial_field_object_properties[0][2][1][3] = time_move_requested + access_time + object_movement_time
#  
#  # Set expected values for object 0 on (0, 2); the "putting-down" phase of 
#  # movement where the object being moved is placed on its destination 
#  # coordinates.
#  expected_visual_spatial_field_object_properties[0][2].push([
#    objects[0][0],
#    objects[0][1],
#    time_move_requested + access_time + object_movement_time,
#    time_of_scan + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  ##### SET EXPECTED TEST VALUES RELATED TO OBJECT 1 MOVEMENT #####
#  
#  # Set terminus of object 1 on (1, 3); the "pick-up" phase of the movement.
#  expected_visual_spatial_field_object_properties[1][3][1][3] = time_move_requested + access_time + object_movement_time
#  
#  # Set expected values for the empty square placed on (1, 3) after object 0 is 
#  # "picked-up".
#  expected_visual_spatial_field_object_properties[1][3].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    time_move_requested + access_time + object_movement_time,
#    time_of_scan + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  # Set terminus of empty square on (3, 1); the "putting-down" phase of movement
#  # where the coordinates are no longer considered to be empty.
#  expected_visual_spatial_field_object_properties[3][1][1][3] = time_move_requested + access_time + (object_movement_time * 2)
#  
#  # Set expected values for object 1 on (3, 1); the "putting-down" phase of 
#  # movement where the object being moved is placed on its destination 
#  # coordinates.
#  expected_visual_spatial_field_object_properties[3][1].push([
#    objects[1][0],
#    objects[1][1],
#    time_move_requested + access_time + (object_movement_time * 2),
#    time_move_requested + access_time + (object_movement_time * 2) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#  
#  check_visual_spatial_field_against_expected(
#    visual_spatial_field, 
#    expected_visual_spatial_field_object_properties,
#    model.getAttentionClock(),
#    "after first move sequence."
#  )
#  
#  #######################
#  ##### MOVE OBJECT #####
#  #######################
#  
#  # Move object 1 so that it is recognised (see the second list pattern learned)
#  # along with object 2 when the scene is scanned again.  The resulting 
#  # visual-spatial field should look like the following:
#  # 
#  #                  --------
#  # 4     x      x   | 2(A) |  x      x
#  #           ----------------------
#  # 3     x   |      |      | 1(B) |  x
#  #    ------------------------------------
#  # 2  | 0(A) |      |      | 3(D) |      |
#  #    ------------------------------------
#  # 1     x   |      |      |      |  x
#  #           ----------------------
#  # 0     x      x   | 4(G) |  x      x
#  #                  --------
#  #       0      1      2      3      4     COORDINATES
#  b_move = ArrayList.new
#  b_move.add(ItemSquarePattern.new(objects[1][0], 3, 1))
#  b_move.add(ItemSquarePattern.new(objects[1][0], 3, 3))
#  
#  move_sequence = ArrayList.new
#  move_sequence.add(b_move)
#  
#  time_move_requested = model.getAttentionClock()
#  visual_spatial_field.moveObjects(move_sequence, time_move_requested, false)
#  
#  ######################################
#  ##### SCAN SCENE AND TEST RECALL #####
#  ######################################
#  
#  time_of_scan = model.getAttentionClock()
#  
#  # In this case, it should be ensured that objects 1 and 2 are recognised when 
#  # the visual-spatial field is scanned (due to the random-nature of eye 
#  # fixation during scene scanning).  This ensures that expected test output can
#  # be correctly defined.
#  visual_stm_contents_as_expected = false
#  expected_stm_contents = list_patterns_to_learn[1].toString()
#  recalled_scene = nil
#  
#  until visual_stm_contents_as_expected do
#    recalled_scene = model.scanScene(visual_spatial_field.getAsScene(time_of_scan, false), 20, true, time_of_scan, false)
#
#    # Get contents of STM (will have been populated during object 
#    # recognition during visual-spatial field construction) and remove root 
#    # nodes and nodes with empty images.  This will leave retrieved chunks 
#    # that have non-empty images, i.e. these images should contain the 
#    # list-patterns learned by the model.
#    stm = model.getVisualStm()
#    stm_contents = ""
#    for i in (stm.getCount() - 1).downto(0)
#      chunk = stm.getItem(i)
#      if( !chunk.equals(model.getVisualLtm()) )
#        if(!chunk.getImage().isEmpty())
#          stm_contents += chunk.getImage().toString()
#        end
#      end
#    end
#
#    # Check if STM contents are as expected, if they are, set the flag that
#    # controls when the model is ready for testing to true.
#    expected_stm_contents == stm_contents ? visual_stm_contents_as_expected = true : nil
#  end
#  
#  expected_recalled_scene = Array.new
#  for col in 0...scene.getWidth()
#    expected_recalled_scene.push(Array.new)
#    for row in 0...scene.getHeight()
#      expected_recalled_scene[col].push([
#        Scene.getBlindSquareToken(),
#        Scene.getBlindSquareToken()
#      ])
#    end
#  end
#  
#  expected_recalled_scene[3][3][0] = objects[1][0]
#  expected_recalled_scene[3][3][1] = objects[1][1]
#  
#  expected_recalled_scene[2][4][0] = objects[2][0]
#  expected_recalled_scene[2][4][1] = objects[2][1]
#  
#  check_scene_against_expected(recalled_scene, expected_recalled_scene, "after second move sequence.")
#  
#  #####################################
#  ##### TEST VISUAL-SPATIAL FIELD #####
#  #####################################
#  
#  # Assume at first that each VisualSpatialObject will have a terminus equal to 
#  # that of an unrecognised object.  Only set the terminus for 
#  # VisualSpatialObjects that are supposed to have a terminus (not currently set
#  # to null) and that are alive when the scene is scanned.
#  for col in 0...expected_visual_spatial_field_object_properties.count
#    for row in 0...expected_visual_spatial_field_object_properties[col].count
#      for object in 0...expected_visual_spatial_field_object_properties[col][row].count
#        terminus = expected_visual_spatial_field_object_properties[col][row][object][3]
#        if terminus != nil and terminus >= time_of_scan
#          terminus = time_of_scan + unrecognised_object_lifespan
#          expected_visual_spatial_field_object_properties[col][row][object][3] = terminus
#        end
#      end
#    end
#  end
#  
#  # Now the expected values for objects manipulated during the object move are
#  # set below.
#  
#  ##### SET EXPECTED TEST VALUES RELATED TO OBJECT 1 MOVEMENT #####
#  
#  # Set terminus of object 1 on (3, 1); the "pick-up" phase of the movement.
#  expected_visual_spatial_field_object_properties[3][1][2][3] = time_move_requested + access_time
#  
#  # Set expected values for the empty square placed on (3, 1) after object 0 is 
#  # "picked-up".
#  expected_visual_spatial_field_object_properties[3][1].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    time_move_requested + access_time,
#    time_of_scan + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  # Set terminus of empty square on (3, 3); the "putting-down" phase of movement
#  # where the coordinates are no longer considered to be empty.
#  expected_visual_spatial_field_object_properties[3][3][1][3] = time_move_requested + access_time + object_movement_time
#  
#  # Set expected values for object 1 on (3, 3); the "putting-down" phase of 
#  # movement where the object being moved is placed on its destination 
#  # coordinates.  Note that this object should be recognised after the scene is
#  # scanned so its expected terminus and recognised status should be set 
#  # accordingly.
#  expected_visual_spatial_field_object_properties[3][3].push([
#    objects[1][0],
#    objects[1][1],
#    time_move_requested + access_time + object_movement_time,
#    time_of_scan + recognised_object_lifespan,
#    true,
#    false
#  ])
#
#  # Object 2 on (2, 4) should now be recognised due to object 1's movement.
#  expected_visual_spatial_field_object_properties[2][4][1][3] = time_move_requested + access_time + object_movement_time + recognised_object_lifespan
#  expected_visual_spatial_field_object_properties[2][4][1][4] = true
#  
#  check_visual_spatial_field_against_expected(
#    visual_spatial_field, 
#    expected_visual_spatial_field_object_properties,
#    model.getAttentionClock(),
#    "after the second object movement."
#  )
#end
#
#################################################################################
## Tests that the Scenes recalled after scanning a Scene at various points in 
## time are as expected.  Also tests that a visual-spatial field generated by the
## original Scene is updated as expected after moving objects in the 
## visual-spatial field and scanning the resulting Scene generated.  This is done 
## by modelling the following scenario:
## 
## 1) A Scene is created and scanned by CHREST and the Scene recalled is tested
##    to see if it is as expected: the recalled Scene should contain no 
##    recognised objects (completely blind).
## 2) CHREST learns two list patterns: the first refers to objects that will be
##    recognised when the Scene is scanned again and when the visual-spatial 
##    field is first generated from the original Scene.  The second refers to 
##    objects that will be recognised when objects have been moved in the 
##    visual-spatial field and a Scene is generated from the resulting 
##    visual-spatial field and scanned again.
## 3) The original Scene is scanned again after learning the list patterns and 
##    the recalled Scene is tested: the recalled Scene should contain two 
##    recognised objects.
## 4) CHREST constructs a visual-spatial field from the original Scene and both 
##    the visual-spatial field constructed and the Scene generated by getting the
##    contents of the visual-spatial field as a Scene are checked to see if they
##    are as expected: two of the objects should be recognised.
## 3) Objects on the visual-spatial field are moved and both the resulting 
##    visual-spatial field and the Scene generated by getting the contents of the 
##    visual-spatial field as a Scene are checked to see if they are as expected: 
##    none of the objects should be recognised.
## 4) Objects on the visual-spatial field are moved again and both the resulting 
##    visual-spatial field and the Scene generated by getting the contents of the 
##    visual-spatial field as a Scene are checked to see if they are as expected:
##    one of the previously recognised objects should now be recognised again 
##    along with an object that was not previously recognised at any point in 
##    this test.
##    
## The initial Scene used is illustrated below ("x" represents a blind square, 
## real objects are denoted by their identifiers and their class are in 
## parenthesis).
## 
##                  --------
## 4     x      x   | 2(A) |  x      x
##           ----------------------
## 3     x   | 1(B) |      |      |  x
##    ------------------------------------
## 2  |      | 0(A) |5(SLF)| 3(D) |      |
##    ------------------------------------
## 1     x   |      |      |      |  x
##           ----------------------
## 0     x      x   | 4(G) |  x      x
##                  --------
##       0      1      2      3      4     COORDINATES
#process_test "scan_scene (creator in scene)" do
#  
#  #####################################
#  ##### UBIQUITOUS TEST VARIABLES #####
#  #####################################
#  
#  objects = [
#    ["0", "A"],
#    ["1", "B"],
#    ["2", "A"],
#    ["3", "D"],
#    ["4", "G"],
#    ["5", Scene.getCreatorToken()],
#    ["6", "C"]
#  ]
#  
#  # Test clock, the time by which all CHREST and visual-spatial field operations
#  # are coordinated by.
#  domain_time = 0
#  
#  # Visual-spatial field parameters
#  object_encoding_time = 10
#  empty_square_encoding_time = 5
#  access_time = 100
#  object_movement_time = 50
#  recognised_object_lifespan = 40000
#  unrecognised_object_lifespan = 20000
#  number_fixations = 20
#  
#  ###########################
#  ##### CONSTRUCT SCENE #####
#  ###########################
#  
#  scene = Scene.new("scene", 5, 5, nil)
#  scene.addItemToSquare(2, 0, objects[4][0], objects[4][1])
#  scene.addItemToSquare(1, 1, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(2, 1, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(3, 1, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(0, 2, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(1, 2, objects[0][0], objects[0][1])
#  scene.addItemToSquare(2, 2, objects[5][0], objects[5][1])
#  scene.addItemToSquare(3, 2, objects[3][0], objects[3][1])
#  scene.addItemToSquare(4, 2, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(1, 3, objects[1][0], objects[1][1])
#  scene.addItemToSquare(2, 3, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(3, 3, Scene.getEmptySquareToken(), Scene.getEmptySquareToken())
#  scene.addItemToSquare(2, 4, objects[2][0], objects[2][1])
#  
#  ##############################
#  ##### INSTANTIATE CHREST #####
#  ##############################
#  
#  model = Chrest.new
#  model.setDomain(GenericDomain.new(model))
#  model.getPerceiver().setFieldOfView(1)
#  
#  ######################################
#  ##### SCAN SCENE AND TEST RECALL #####
#  ######################################
#  
#  recalled_scene = model.scanScene(scene, number_fixations, true, domain_time, false)
#  
#  expected_recalled_scene = Array.new
#  for col in 0...scene.getWidth()
#    expected_recalled_scene.push(Array.new)
#    for row in 0...scene.getHeight()
#      expected_recalled_scene[col].push([
#        (col == 2 and row == 2) ? objects[5][0] : Scene.getBlindSquareToken(),
#        (col == 2 and row == 2) ? objects[5][1] : Scene.getBlindSquareToken()
#      ])
#    end
#  end
#  
#  check_scene_against_expected(recalled_scene, expected_recalled_scene, "before learning.")
#  
#  ###########################
#  ##### CHREST LEARNING #####
#  ###########################
#  
#  # Create a list pattern that is recognised in the original scene state:
#  # <[A -1 0][B -1 1]>
#  list_pattern_1 = ListPattern.new
#  list_pattern_1.add(ItemSquarePattern.new(objects[0][1], -1, 0))
#  list_pattern_1.add(ItemSquarePattern.new(objects[1][1], -1, 1))
#  
#  # Create a list pattern that isn't recognised in the original scene state but 
#  # will be after B is moved: <[B 1 -1][A 0 2]>
#  list_pattern_2 = ListPattern.new
#  list_pattern_2.add(ItemSquarePattern.new(objects[1][1], 1, -1))
#  list_pattern_2.add(ItemSquarePattern.new(objects[2][1], 0, 2))
#  
#  list_patterns_to_learn = Array.new
#  list_patterns_to_learn.push(list_pattern_1)
#  list_patterns_to_learn.push(list_pattern_2)
#  
#  for list_pattern in list_patterns_to_learn
#    recognised_chunk = model.recogniseAndLearn(list_pattern, domain_time).getImage()
#    until recognised_chunk.contains(list_pattern.getItem(list_pattern.size()-1))
#      recognised_chunk = model.recogniseAndLearn(list_pattern, domain_time).getImage()
#      domain_time += 1
#    end
#  end
#  
#  ######################################
#  ##### SCAN SCENE AND TEST RECALL #####
#  ######################################
#  
#  # Since CHREST's fixations are somewhat random when scanning a scene, it may 
#  # be that, after scanning the scene in question, objects 0 and 1 are not 
#  # recognised.  So, in order to test the contents of the expected recalled 
#  # scene reliably after scanning, scan the scene until CHREST's STM contains 
#  # the first list pattern learned before.
#  visual_stm_contents_as_expected = false
#  expected_stm_contents = list_patterns_to_learn[0].toString()
#  
#  until visual_stm_contents_as_expected do
#    recalled_scene = model.scanScene(scene, number_fixations, true, domain_time, false)
#    
#    stm = model.getVisualStm()
#    stm_contents = ""
#    for i in (stm.getCount() - 1).downto(0)
#      chunk = stm.getItem(i)
#      if( !chunk.equals(model.getVisualLtm()) )
#        if(!chunk.getImage().isEmpty())
#          stm_contents += chunk.getImage().toString()
#        end
#      end
#    end
#
#    expected_stm_contents == stm_contents ? visual_stm_contents_as_expected = true : nil
#  end
#  
#  # The scene recalled should be entirely blind except for objects on 
#  # coordinates (1, 2) and (1, 3)
#  expected_recalled_scene = Array.new
#  for col in 0...scene.getWidth()
#    expected_recalled_scene.push(Array.new)
#    for row in 0...scene.getHeight()
#      expected_recalled_scene[col].push([
#        (col == 2 and row == 2) ? objects[5][0] : Scene.getBlindSquareToken(),
#        (col == 2 and row == 2) ? objects[5][1] : Scene.getBlindSquareToken()
#      ])
#    end
#  end
#  
#  expected_recalled_scene[1][2][0] = objects[0][0]
#  expected_recalled_scene[1][2][1] = objects[0][1]
#  
#  expected_recalled_scene[1][3][0] = objects[1][0]
#  expected_recalled_scene[1][3][1] = objects[1][1]
#  
#  check_scene_against_expected(recalled_scene, expected_recalled_scene, "after learning.")
#  
#  ############################################
#  ##### INSTANTIATE VISUAL-SPATIAL FIELD #####
#  ############################################
#
#  visual_spatial_field_creation_time = domain_time
#  
#  visual_stm_contents_as_expected = false
#  expected_stm_contents = list_patterns_to_learn[0].toString()
#  
#  expected_fixations_made = false
#  fixations_expected = [
#    [2, 0],
#    [1, 2],
#    [2, 2],
#    [3, 2],
#    [1, 3],
#    [2, 4]
#  ]
#
#  # Need to ensure that the visual-spatial field is instantiated according to 
#  # what has been learned in order to set expected test output correctly.
#  until visual_stm_contents_as_expected and expected_fixations_made do
#    
#    visual_stm_contents_as_expected = false
#    expected_fixations_made = false
#    
#    # Set creation time to the current domain time (this is important in 
#    # calculating a lot of test variables below).
#    visual_spatial_field_creation_time = domain_time
#
#    # Construct the visual-spatial field.
#    visual_spatial_field = VisualSpatialField.new(
#      model,
#      scene, 
#      object_encoding_time,
#      empty_square_encoding_time,
#      access_time, 
#      object_movement_time, 
#      recognised_object_lifespan,
#      unrecognised_object_lifespan,
#      number_fixations,
#      domain_time,
#      false,
#      false
#    )
#
#    # Get contents of STM (will have been populated during object 
#    # recognition during visual-spatial field construction) and remove root 
#    # nodes and nodes with empty images.  This will leave retrieved chunks 
#    # that have non-empty images, i.e. these images should contain the 
#    # list-patterns learned by the model.
#    stm = model.getVisualStm()
#    stm_contents = ""
#    for i in (stm.getCount() - 1).downto(0)
#      chunk = stm.getItem(i)
#      if( !chunk.equals(model.getVisualLtm()) )
#        if(!chunk.getImage().isEmpty())
#          stm_contents += chunk.getImage().toString()
#        end
#      end
#    end
#
#    # Check if STM contents are as expected, if they are, set the flag that
#    # controls when the model is ready for testing to true.
#    expected_stm_contents == stm_contents ? visual_stm_contents_as_expected = true : nil
#    
#    expected_fixations_made = expected_fixations_made?(model, fixations_expected)
#
#    # Advance domain time to the time that the visual-spatial field will be 
#    # completely instantiated so that the model's attention will be free 
#    # should a new visual-field need to be constructed.
#    domain_time = model.getAttentionClock
#  end
#  
#  #####################################
#  ##### TEST VISUAL-SPATIAL FIELD #####
#  #####################################
#  
#  # The first VisualSpatialFieldObject on each coordinate is expected to be a 
#  # blind square.
#  expected_visual_spatial_field_object_properties = Array.new
#  for col in 0...scene.getWidth()
#    expected_visual_spatial_field_object_properties.push(Array.new)
#    for row in 0...scene.getHeight()
#      expected_visual_spatial_field_object_properties[col].push(Array.new)
#      expected_visual_spatial_field_object_properties[col][row].push([
#        (col == 2 and row == 2) ? objects[5][0] : Scene.getBlindSquareToken, #Expected ID
#        (col == 2 and row == 2) ? objects[5][1] : Scene.getBlindSquareToken, #Expected class
#        visual_spatial_field_creation_time + access_time, #Expected creation time.
#        nil, #Expected lifespan (not exact terminus) of the object.
#        false, #Expected recognised status
#        false # Expected ghost status
#      ])
#    end
#  end
#  
#  # Set expected values for coordinates containing recognised objects first.
#  expected_visual_spatial_field_object_properties[1][2][0][3] = visual_spatial_field_creation_time + access_time + object_encoding_time
#  expected_visual_spatial_field_object_properties[1][2].push([
#    objects[0][0],
#    objects[0][1],
#    visual_spatial_field_creation_time + access_time + object_encoding_time,
#    visual_spatial_field_creation_time + access_time + object_encoding_time + recognised_object_lifespan,
#    true,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[1][3][0][3] = visual_spatial_field_creation_time + access_time + object_encoding_time
#  expected_visual_spatial_field_object_properties[1][3].push([
#    objects[1][0],
#    objects[1][1],
#    visual_spatial_field_creation_time + access_time + object_encoding_time,
#    visual_spatial_field_creation_time + access_time + object_encoding_time + recognised_object_lifespan,
#    true,
#    false
#  ])
#
#  # Set expected values for coordinates containing unrecognised objects second. 
#  expected_visual_spatial_field_object_properties[2][0][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 2)
#  expected_visual_spatial_field_object_properties[2][0].push([
#    objects[4][0],
#    objects[4][1],
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[1][1][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + empty_square_encoding_time
#  expected_visual_spatial_field_object_properties[1][1].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + empty_square_encoding_time,
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + empty_square_encoding_time + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[2][1][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 2)
#  expected_visual_spatial_field_object_properties[2][1].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 2),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 2) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[3][1][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 3)
#  expected_visual_spatial_field_object_properties[3][1].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 3),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 3) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[0][2][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 4)
#  expected_visual_spatial_field_object_properties[0][2].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 4),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 2) + (empty_square_encoding_time * 4) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[3][2][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 4)
#  expected_visual_spatial_field_object_properties[3][2].push([
#    objects[3][0],
#    objects[3][1],
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 4),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 4) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[4][2][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 5)
#  expected_visual_spatial_field_object_properties[4][2].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 5),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 5) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[2][3][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 6)
#  expected_visual_spatial_field_object_properties[2][3].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 6),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 6) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[3][3][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 7)
#  expected_visual_spatial_field_object_properties[3][3].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 7),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 3) + (empty_square_encoding_time * 7) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  expected_visual_spatial_field_object_properties[2][4][0][3] = visual_spatial_field_creation_time + access_time + (object_encoding_time * 4) + (empty_square_encoding_time * 7)
#  expected_visual_spatial_field_object_properties[2][4].push([
#    objects[2][0],
#    objects[2][1],
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 4) + (empty_square_encoding_time * 7),
#    visual_spatial_field_creation_time + access_time + (object_encoding_time * 4) + (empty_square_encoding_time * 7) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  check_visual_spatial_field_against_expected(
#    visual_spatial_field, 
#    expected_visual_spatial_field_object_properties,
#    model.getAttentionClock(),
#    "before moving objects."
#  )
#  
#  ########################
#  ##### MOVE OBJECTS #####
#  ########################
#  
#  # <[A 1 2][B 1 3]> are recognised in the visual-spatial field now so move 
#  # these objects so that they should be unrecognisable when the scene is next 
#  # scanned.  The resulting visual-spatial field should look like the following:
#  #
#  #                  --------
#  # 4     x      x   | 2(A) |  x      x
#  #           ----------------------
#  # 3     x   |      |      | 1(B) |  x
#  #    ------------------------------------
#  # 2  | 0(A) |      |      | 3(D) |      |
#  #    ------------------------------------
#  # 1     x   |      |      |      |  x
#  #           ----------------------
#  # 0     x      x   | 4(G) |  x      x
#  #                  --------
#  #       0      1      2      3      4     COORDINATES
#  a_move = ArrayList.new
#  a_move.add(ItemSquarePattern.new(objects[0][0], 1, 2))
#  a_move.add(ItemSquarePattern.new(objects[0][0], 0, 2))
#  
#  b_move = ArrayList.new
#  b_move.add(ItemSquarePattern.new(objects[1][0], 1, 3))
#  b_move.add(ItemSquarePattern.new(objects[1][0], 3, 3))
#  
#  a_and_b_moves = ArrayList.new
#  a_and_b_moves.add(a_move)
#  a_and_b_moves.add(b_move)
#  
#  time_move_requested = model.getAttentionClock()
#  visual_spatial_field.moveObjects(a_and_b_moves, time_move_requested, false)
#  time_moves_completed = model.getAttentionClock()
#  
#  ######################################
#  ##### SCAN SCENE AND TEST RECALL #####
#  ######################################
#  
#  recalled_scene = model.scanScene(visual_spatial_field.getAsScene(time_moves_completed, false), 20, true, time_moves_completed, false)
#  time_of_scan = time_moves_completed
#  
#  expected_recalled_scene = Array.new
#  for col in 0...scene.getWidth()
#    expected_recalled_scene.push(Array.new)
#    for row in 0...scene.getHeight()
#      expected_recalled_scene[col].push([
#        (col == 2 and row == 2) ? objects[5][0] : Scene.getBlindSquareToken(),
#        (col == 2 and row == 2) ? objects[5][1] : Scene.getBlindSquareToken()
#      ])
#    end
#  end
#  
#  check_scene_against_expected(recalled_scene, expected_recalled_scene, "after first move sequence.")
#  
#  #####################################
#  ##### TEST VISUAL-SPATIAL FIELD #####
#  #####################################
#  
#  # Assume at first that each VisualSpatialObject will have a terminus equal to 
#  # that of an unrecognised object.  Only set the terminus for 
#  # VisualSpatialObjects that are supposed to have a terminus (not currently set
#  # to null) and that are alive when the scene is scanned.
#  for col in 0...expected_visual_spatial_field_object_properties.count
#    for row in 0...expected_visual_spatial_field_object_properties[col].count
#      for object in 0...expected_visual_spatial_field_object_properties[col][row].count
#        terminus = expected_visual_spatial_field_object_properties[col][row][object][3]
#        if terminus != nil and terminus >= time_of_scan
#          terminus = time_of_scan + unrecognised_object_lifespan
#          expected_visual_spatial_field_object_properties[col][row][object][3] = terminus
#        end
#      end
#    end
#  end
#  
#  # Now the expected values for objects manipulated during the object move are
#  # set below.
#  
#  ##### SET EXPECTED TEST VALUES RELATED TO OBJECT 0 MOVEMENT #####
#  
#  # Set terminus of object 0 on (1, 2); the "pick-up" phase of the movement.
#  expected_visual_spatial_field_object_properties[1][2][1][3] = time_move_requested + access_time
#  
#  # Set expected values for the empty square placed on (1, 2) after object 0 is 
#  # "picked-up".
#  expected_visual_spatial_field_object_properties[1][2].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    time_move_requested + access_time,
#    time_of_scan + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#  
#  # Set terminus of empty square on (0, 2); the "putting-down" phase of movement
#  # where the coordinates are no longer considered to be empty.
#  expected_visual_spatial_field_object_properties[0][2][1][3] = time_move_requested + access_time + object_movement_time
#  
#  # Set expected values for object 0 on (0, 2); the "putting-down" phase of 
#  # movement where the object being moved is placed on its destination 
#  # coordinates.
#  expected_visual_spatial_field_object_properties[0][2].push([
#    objects[0][0],
#    objects[0][1],
#    time_move_requested + access_time + object_movement_time,
#    time_of_scan + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  ##### SET EXPECTED TEST VALUES RELATED TO OBJECT 1 MOVEMENT #####
#  
#  # Set terminus of object 1 on (1, 3); the "pick-up" phase of the movement.
#  expected_visual_spatial_field_object_properties[1][3][1][3] = time_move_requested + access_time + object_movement_time
#  
#  # Set expected values for the empty square placed on (1, 3) after object 0 is 
#  # "picked-up".
#  expected_visual_spatial_field_object_properties[1][3].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    time_move_requested + access_time + object_movement_time,
#    time_of_scan + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  # Set terminus of empty square on (3, 3); the "putting-down" phase of movement
#  # where the coordinates are no longer considered to be empty.
#  expected_visual_spatial_field_object_properties[3][3][1][3] = time_move_requested + access_time + (object_movement_time * 2)
#  
#  # Set expected values for object 1 on (3, 3); the "putting-down" phase of 
#  # movement where the object being moved is placed on its destination 
#  # coordinates.
#  expected_visual_spatial_field_object_properties[3][3].push([
#    objects[1][0],
#    objects[1][1],
#    time_move_requested + access_time + (object_movement_time * 2),
#    time_move_requested + access_time + (object_movement_time * 2) + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#  
#  check_visual_spatial_field_against_expected(
#    visual_spatial_field, 
#    expected_visual_spatial_field_object_properties,
#    model.getAttentionClock(),
#    "after first move sequence."
#  )
#  
#  #######################
#  ##### MOVE OBJECT #####
#  #######################
#  
#  # Move object 1 so that it is recognised (see the second list pattern learned)
#  # along with object 2 when the scene is scanned again.  The resulting 
#  # visual-spatial field should look like the following:
#  # 
#  #                  --------
#  # 4     x      x   | 2(A) |  x      x
#  #           ----------------------
#  # 3     x   |      |      |      |  x
#  #    ------------------------------------
#  # 2  | 0(A) |      |      | 3(D) |      |
#  #    ------------------------------------
#  # 1     x   |      |      | 1(B) |  x
#  #           ----------------------
#  # 0     x      x   | 4(G) |  x      x
#  #                  --------
#  #       0      1      2      3      4     COORDINATES
#  b_move = ArrayList.new
#  b_move.add(ItemSquarePattern.new(objects[1][0], 3, 3))
#  b_move.add(ItemSquarePattern.new(objects[1][0], 3, 1))
#  
#  move_sequence = ArrayList.new
#  move_sequence.add(b_move)
#  
#  time_move_requested = model.getAttentionClock()
#  visual_spatial_field.moveObjects(move_sequence, time_move_requested, false)
#  
#  ######################################
#  ##### SCAN SCENE AND TEST RECALL #####
#  ######################################
#  
#  time_of_scan = model.getAttentionClock()
#  
#  # In this case, it should be ensured that objects 1 and 2 are recognised when 
#  # the visual-spatial field is scanned (due to the random-nature of eye 
#  # fixation during scene scanning).  This ensures that expected test output can
#  # be correctly defined.
#  visual_stm_contents_as_expected = false
#  expected_stm_contents = list_patterns_to_learn[1].toString()
#  recalled_scene = nil
#  
#  until visual_stm_contents_as_expected do
#    recalled_scene = model.scanScene(visual_spatial_field.getAsScene(time_of_scan, false), 20, true, time_of_scan, false)
#
#    # Get contents of STM (will have been populated during object 
#    # recognition during visual-spatial field construction) and remove root 
#    # nodes and nodes with empty images.  This will leave retrieved chunks 
#    # that have non-empty images, i.e. these images should contain the 
#    # list-patterns learned by the model.
#    stm = model.getVisualStm()
#    stm_contents = ""
#    for i in (stm.getCount() - 1).downto(0)
#      chunk = stm.getItem(i)
#      if( !chunk.equals(model.getVisualLtm()) )
#        if(!chunk.getImage().isEmpty())
#          stm_contents += chunk.getImage().toString()
#        end
#      end
#    end
#
#    # Check if STM contents are as expected, if they are, set the flag that
#    # controls when the model is ready for testing to true.
#    expected_stm_contents == stm_contents ? visual_stm_contents_as_expected = true : nil
#  end
#  
#  expected_recalled_scene = Array.new
#  for col in 0...scene.getWidth()
#    expected_recalled_scene.push(Array.new)
#    for row in 0...scene.getHeight()
#      expected_recalled_scene[col].push([
#        (col == 2 and row == 2) ? objects[5][0] : Scene.getBlindSquareToken(),
#        (col == 2 and row == 2) ? objects[5][1] : Scene.getBlindSquareToken()
#      ])
#    end
#  end
#  
#  expected_recalled_scene[3][1][0] = objects[1][0]
#  expected_recalled_scene[3][1][1] = objects[1][1]
#  
#  expected_recalled_scene[2][4][0] = objects[2][0]
#  expected_recalled_scene[2][4][1] = objects[2][1]
#  
#  check_scene_against_expected(recalled_scene, expected_recalled_scene, "after second move sequence.")
#  
#  #####################################
#  ##### TEST VISUAL-SPATIAL FIELD #####
#  #####################################
#  
#  # Assume at first that each VisualSpatialObject will have a terminus equal to 
#  # that of an unrecognised object.  Only set the terminus for 
#  # VisualSpatialObjects that are supposed to have a terminus (not currently set
#  # to null) and that are alive when the scene is scanned.
#  for col in 0...expected_visual_spatial_field_object_properties.count
#    for row in 0...expected_visual_spatial_field_object_properties[col].count
#      for object in 0...expected_visual_spatial_field_object_properties[col][row].count
#        terminus = expected_visual_spatial_field_object_properties[col][row][object][3]
#        if terminus != nil and terminus >= time_of_scan
#          terminus = time_of_scan + unrecognised_object_lifespan
#          expected_visual_spatial_field_object_properties[col][row][object][3] = terminus
#        end
#      end
#    end
#  end
#  
#  # Now the expected values for objects manipulated during the object move are
#  # set below.
#  
#  ##### SET EXPECTED TEST VALUES RELATED TO OBJECT 1 MOVEMENT #####
#  
#  # Set terminus of object 1 on (3, 3); the "pick-up" phase of the movement.
#  expected_visual_spatial_field_object_properties[3][3][2][3] = time_move_requested + access_time
#  
#  # Set expected values for the empty square placed on (3, 3) after object 0 is 
#  # "picked-up".
#  expected_visual_spatial_field_object_properties[3][3].push([
#    Scene.getEmptySquareToken(),
#    Scene.getEmptySquareToken(),
#    time_move_requested + access_time,
#    time_of_scan + unrecognised_object_lifespan,
#    false,
#    false
#  ])
#
#  # Set terminus of empty square on (3, 1); the "putting-down" phase of movement
#  # where the coordinates are no longer considered to be empty.
#  expected_visual_spatial_field_object_properties[3][1][1][3] = time_move_requested + access_time + object_movement_time
#  
#  # Set expected values for object 1 on (3, 1); the "putting-down" phase of 
#  # movement where the object being moved is placed on its destination 
#  # coordinates.  Note that this object should be recognised after the scene is
#  # scanned so its expected terminus and recognised status should be set 
#  # accordingly.
#  expected_visual_spatial_field_object_properties[3][1].push([
#    objects[1][0],
#    objects[1][1],
#    time_move_requested + access_time + object_movement_time,
#    time_of_scan + recognised_object_lifespan,
#    true,
#    false
#  ])
#
#  # Object 2 on (2, 4) should now be recognised due to object 1's movement.
#  expected_visual_spatial_field_object_properties[2][4][1][3] = time_move_requested + access_time + object_movement_time + recognised_object_lifespan
#  expected_visual_spatial_field_object_properties[2][4][1][4] = true
#  
#  check_visual_spatial_field_against_expected(
#    visual_spatial_field, 
#    expected_visual_spatial_field_object_properties,
#    model.getAttentionClock(),
#    "after the second object movement."
#  )
#end
#
## Tests for correct operation of Chrest.getProductionsCount() and 
## Node.getProductionCount() by:
## 
## 1. Creating a LTM network where the number of visual LTM nodes and the depth 
##    of visual LTM is > 1.
## 2. Creating an action LTM node to enable production creation.
## 3. Creating productions for each visual node created in step 1 with the action
##    node created in step 2.
## 4. Calculating the number of productions in visual LTM manually and storing 
##    the result.
## 5. Comparing the result of 4 with the output of invoking the 
##    "getProductionsCount" function.
##
## This ensures that:
##
## a) The Chrest.getProductionsCount() works correctly since the total number of
##    productions in LTM is checked.
## b) To produce the correct value for a) the recursive variant of the 
##    Node.getProductionCount() method must work since getting the value for a) 
##    is dependent upon the recursive aspects of the method operating correctly.
## c) To produce the correct value for a) the non-recursive variant of the 
##    Node.getProductionCount() method must work since getting the value for a) 
##    is dependent upon the non-recursive aspects of the method operating 
##    correctly.
#unit_test "getProductionsCount" do
#  
#  #############
#  ### SETUP ###
#  #############
#  model = Chrest.new
#  
#  visual_pattern_1 = ListPattern.new(Modality::VISUAL)
#  visual_pattern_1.add(ItemSquarePattern.new("A", 0, 0))
#  visual_pattern_1.add(ItemSquarePattern.new("B", 0, 1))
#  visual_pattern_1.add(ItemSquarePattern.new("C", 0, 2))
#  visual_pattern_1.setFinished()
#  
#  visual_pattern_2 = ListPattern.new(Modality::VISUAL)
#  visual_pattern_2.add(ItemSquarePattern.new("A", 0, 0))
#  visual_pattern_2.add(ItemSquarePattern.new("C", 0, 2))
#  visual_pattern_2.add(ItemSquarePattern.new("B", 0, 1))
#  visual_pattern_2.add(ItemSquarePattern.new("D", 0, 3))
#  visual_pattern_2.setFinished()
#  
#  visual_pattern_3 = ListPattern.new(Modality::VISUAL)
#  visual_pattern_3.add(ItemSquarePattern.new("A", 0, 0))
#  visual_pattern_3.add(ItemSquarePattern.new("D", 0, 3))
#  visual_pattern_3.add(ItemSquarePattern.new("C", 0, 2))
#  visual_pattern_3.add(ItemSquarePattern.new("B", 0, 1))
#  visual_pattern_3.setFinished()
#  
#  visual_pattern_4 = ListPattern.new(Modality::VISUAL)
#  visual_pattern_4.add(ItemSquarePattern.new("G", 0, 0))
#  visual_pattern_4.add(ItemSquarePattern.new("F", 0, 1))
#  visual_pattern_4.setFinished()
#  
#  visual_pattern_5 = ListPattern.new(Modality::VISUAL)
#  visual_pattern_5.add(ItemSquarePattern.new("D", 0, 3))
#  visual_pattern_5.add(ItemSquarePattern.new("B", 0, 1))
#  visual_pattern_5.setFinished()
#  
#  visual_pattern_6 = ListPattern.new(Modality::VISUAL)
#  visual_pattern_6.add(ItemSquarePattern.new("D", 0, 3))
#  visual_pattern_6.setFinished()
#  
#  action_pattern = ListPattern.new(Modality::ACTION)
#  action_pattern.add(ItemSquarePattern.new("PUSH", 0, 1))
#  
#  list_patterns_to_learn = [
#    visual_pattern_1,
#    visual_pattern_2,
#    visual_pattern_3,
#    visual_pattern_4,
#    visual_pattern_5,
#    visual_pattern_6,
#    action_pattern
#  ]
#  
#  ######################################
#  ### CREATE VISUAL/ACTION LTM NODES ###
#  ######################################
#  
#  for i in 0...list_patterns_to_learn.size
#    list_pattern_to_learn = list_patterns_to_learn[i]
#    i = 1
#    until i == 50
#      model.recogniseAndLearn(list_pattern_to_learn, model.getLearningClock)
#      i += 1
#    end
#  end
#  
#  ##########################
#  ### CREATE PRODUCTIONS ###
#  ##########################
#  
#  for i in 0...list_patterns_to_learn.size - 1
#    list_pattern_to_learn = list_patterns_to_learn[i]
#    until model.recognise(list_pattern_to_learn, model.getLearningClock).getProductions().size() == 1
#      model.associateAndLearn(list_pattern_to_learn, action_pattern, model.getLearningClock).getImage.toString()
#    end
#  end
#  
#  ##################################################
#  ### CALCULATE NUMBER OF PRODUCTIONS "MANUALLY" ###
#  ##################################################
#  
#  number_productions = 0
#  for i in 0...list_patterns_to_learn.size - 1
#    list_pattern = list_patterns_to_learn[i]
#    number_productions += model.recognise(list_pattern, model.getLearningClock).getProductions().size
#  end
#
#  ############
#  ### TEST ###
#  ############
#  
#  assert_equal(number_productions, model.getProductionCount())
#end
#
#def check_scene_against_expected(scene, expected_scene, test_description)
#  for row in 0...scene.getHeight()
#    for col in 0...scene.getWidth()
#      error_message_postscript = "for the object on col " + col.to_s + ", row " + row.to_s + " in the Scene with name: '" + scene.getName() + "' " + test_description
#      scene_object = scene.getSquareContents(col, row)
#      
#      assert_equal(expected_scene[col][row][0], scene_object.getIdentifier(), "occurred when checking the identifier " + error_message_postscript)
#      assert_equal(expected_scene[col][row][1], scene_object.getObjectClass(), "occurred when checking the object class " + error_message_postscript)
#    end
#  end
#end