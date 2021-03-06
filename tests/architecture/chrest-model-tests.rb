# Makes visual-spatial-field-tests helper methods available for use here
require_relative "visual-spatial-field-tests.rb" 

################################################################################
################################################################################
#################################### TESTS #####################################
################################################################################
################################################################################

################################################################################
#
# Scenario Descriptions
# =====================
#
# - Scenario 1
#   ~ Cognition isn't free
#   
# - Scenario 2
#   ~ Cognition is free
#   ~ Node to associate from is a root node
# 
# - Scenario 3
#   ~ Cognition is free
#   ~ Node to associate from is not a root node
#   ~ Node to associate to is a root node
#   
# - Scenario 4
#   ~ Cognition is free
#   ~ Node to associate from is not a root node
#   ~ Node to associate to is not a root node
#   
#   ~ Node to associate from modality is VISUAL and node to associate to 
#     modality is ACTION
#   ~ Association already exists
#
# - Scenario 5
#   ~ Cognition is free
#   ~ Node to associate from is not a root node
#   ~ Node to associate to is not a root node
#   
#   ~ Node to associate from modality is VISUAL and node to associate to 
#     modality is ACTION
#   ~ Association does not already exist
#   
# - Scenario 6
#   ~ Cognition is free
#   ~ Node to associate from is not a root node
#   ~ Node to associate to is not a root node
#   
#   ~ Node to associate from modality is VISUAL and node to associate to 
#     modality is VERBAL
#   ~ Association already exists
#
# - Scenario 7
#   ~ Cognition is free
#   ~ Node to associate from is not a root node
#   ~ Node to associate to is not a root node
#   
#   ~ Node to associate from modality is VISUAL and node to associate to 
#     modality is VERBAL
#   ~ Association does not already exist
#   
# The following scenarios are now repeated with each type of Modality specified
# in CHREST.  
# 
# - Scenario 8/12/16
#   ~ Cognition is free
#   ~ Node to associate from is not a root node
#   ~ Node to associate to is not a root node
#   
#   ~ Node to associate from modality is equal to node to associate from 
#     modality.
#   ~ Node to associate from and node to associate to images are not similar
#
# - Scenario 9/13/17
#   ~ Cognition is free
#   ~ Node to associate from is not a root node
#   ~ Node to associate to is not a root node
#   
#   ~ Node to associate from modality is equal to node to associate from 
#     modality.
#   ~ Node to associate from and node to associate to images are similar
#   ~ Node to associate from already linked to node to associate to
#   ~ Node to associate to not already linked to node to associate from
#     
# - Scenario 10/14/18
#   ~ Cognition is free
#   ~ Node to associate from is not a root node
#   ~ Node to associate to is not a root node
#   
#   ~ Node to associate from modality is equal to node to associate from 
#     modality.
#   ~ Node to associate from and node to associate to images are similar
#   ~ Node to associate from not already linked to node to associate to
#   ~ Node to associate to already linked to node to associate from
#
# - Scenario 11/15/19
#   ~ Cognition is free
#   ~ Node to associate from is not a root node
#   ~ Node to associate to is not a root node
#   
#   ~ Node to associate from modality is equal to node to associate from 
#     modality.
#   ~ Node to associate from and node to associate to images are similar
#   ~ Node to associate from not already linked to node to associate to
#   ~ Node to associate to not already linked to node to associate from
#
# Expected Outcomes
# =================
#
# - The following scenarios should report false and the cognition clock of the 
#   CHREST model should not differ from the time the function is requested.
#   ~ 1, 2, 3, 4, 6, 8, 12, 16
#   
# - The following scenarios should report true but and the cognition clock of 
#   the CHREST model should be set to the time indicated.
#   ~ Scenario 5
#     > Time function requested + time to add production
#     
#   ~ Scenario 7
#     > Time function requested + time to add naming link
#     
#   ~ Scenarios 9/10/13/14/17/18
#     > Time function requested + node comparison time + time to add semantic 
#       link
#     
#   ~ Scenarios 11/15/19
#     > Time function requested + node comparison time + (time to add semantic 
#       link * 2)
process_test "associateNodes" do
  
  Chrest.class_eval{
    field_accessor :_addProductionTime, 
    :_cognitionClock, 
    :_namingLinkCreationTime,
    :_nodeComparisonTime,
    :_nodeImageSimilarityThreshold,
    :_semanticLinkCreationTime
  }
  
  associate_nodes_method = Chrest.java_class.declared_method(:associateNodes, Node.java_class, Node.java_class, Java::int)
  associate_nodes_method.accessible = true
  
  Node.class_eval{
    field_accessor :_namedByHistory, :_productionHistory, :_semanticLinksHistory
  }
  node_root_node_field = Node.java_class.declared_field("_rootNode")
  node_root_node_field.accessible = true
  
  for scenario in 1..19
    time = 0
    model = Chrest.new(time, true)
    
    if scenario == 1 then model._cognitionClock = time + 5 end
    
    ############################
    ##### CONSTRUCT NODE 1 #####
    ############################
    
    # Set modality
    node_1_modality = Modality::VISUAL
    if [12..15].include?(scenario) then node_1_modality = Modality::ACTION end
    if [16..19].include?(scenario) then node_1_modality = Modality::VERBAL end
    
    node_1_contents_and_image = ListPattern.new(node_1_modality)
    node_1 = Node.new(model, node_1_contents_and_image, node_1_contents_and_image, time)
    node_root_node_field.set_value(node_1, (scenario == 2 ? true : false)) 
    
    ############################
    ##### CONSTRUCT NODE 2 #####
    ############################
    
    node_2_modality = Modality::VISUAL
    if [4,5].include?(scenario) || [12..15].include?(scenario) then node_2_modality = Modality::ACTION end
    if [6,7].include?(scenario) || [16..19].include?(scenario) then node_2_modality = Modality::VERBAL end
    
    node_2_contents_and_image = ListPattern.new(node_2_modality)
    node_2 = Node.new(model, node_2_contents_and_image, node_2_contents_and_image, time)
    node_root_node_field.set_value(node_2, (scenario == 3 ? true : false))
    
    ########################################
    ##### SET-UP EXISTING ASSOCIATIONS #####
    ########################################
    
    if [4,6,9,13,17].include?(scenario)
      if scenario == 4 
        association_with_node_2 = HashMap.new()
        association_with_node_2.put(node_2, 0.0)
        association_history = HistoryTreeMap.new()
        association_history.put(time, association_with_node_2)
        node_1._productionHistory = association_history
      elsif scenario == 6
        association_history = HistoryTreeMap.new()
        association_history.put(time, node_2)
        node_1._namedByHistory = association_history
      else
        association_with_node_2 = ArrayList.new()
        association_with_node_2.add(node_2)
        association_history = HistoryTreeMap.new()
        association_history.put(time, association_with_node_2)
        node_1._semanticLinksHistory = association_history
      end
    end
    
    if [10,14,18].include?(scenario)
      association_with_node_1 = ArrayList.new()
      association_with_node_1.add(node_1)
      association_history = HistoryTreeMap.new()
      association_history.put(time, association_with_node_1)
      node_2._semanticLinksHistory = association_history
    end
    
    ####################################
    ##### SET SIMILARITY THRESHOLD #####
    ####################################
    
    if [8,12,16].include?(scenario)
      model._nodeImageSimilarityThreshold = 1
    else
      model._nodeImageSimilarityThreshold = 0
    end
    
    ###########################
    ##### INVOKE FUNCTION #####
    ###########################
    
    result = associate_nodes_method.invoke(model, node_1, node_2, time)
    
    #################################
    ##### SET EXPECTED OUTCOMES #####
    #################################
    
    expected_result = true
    if [1,2,3,4,6,8,12,16].include?(scenario) then expected_result = false end
    
    expected_cognition_clock = -1
    if scenario == 1
      expected_cognition_clock = time + 5
    elsif scenario == 5
      expected_cognition_clock = time + model._addProductionTime
    elsif scenario == 7
      expected_cognition_clock = time + model._namingLinkCreationTime
    elsif [9,10,13,14,17,18].include?(scenario)
      expected_cognition_clock = time + model._nodeComparisonTime + model._semanticLinkCreationTime
    elsif [11,15,19].include?(scenario)
      expected_cognition_clock = time + model._nodeComparisonTime + (model._semanticLinkCreationTime * 2)
    end
    
    #################
    ##### TESTS #####
    #################
    
    assert_equal(expected_result, result, "occurred when checking the result in scenario " + scenario.to_s)
    assert_equal(expected_cognition_clock, model._cognitionClock, "occurred when checking the cognition clock in scenario " + scenario.to_s)
  end
  
end

################################################################################
# Tests the "Chrest.reinforceProduction()" function using a number of different
# scenarios:
#  
# - Scenario 1
#   ~ No action STM exists at time function invoked.
#
# - Scenario 2
#   ~ Action STM exists at time function invoked.
#   ~ No visual STM exists at time function invoked.
#
# - Scenario 3
#   ~ Action STM exists at time function invoked.
#   ~ Visual STM exists at time function invoked.
#   ~ Action node specified does not have Action modality.
#
# - Scenario 4
#   ~ Action STM exists at time function invoked.
#   ~ Visual STM exists at time function invoked.
#   ~ Action node specified has Action modality.
#   ~ Visual node specified does not have Visual modality.
#
# - Scenario 5
#   ~ Action STM exists at time function invoked.
#   ~ Visual STM exists at time function invoked.
#   ~ Action node specified has Action modality.
#   ~ Visual node specified has Visual modality.
#   ~ Attention is not free at time function invoked.
#
# - Scenario 6
#   ~ Action STM exists at time function invoked.
#   ~ Visual STM exists at time function invoked.
#   ~ Action node specified has Action modality.
#   ~ Visual node specified has Visual modality.
#   ~ Attention is free at time function invoked.
#   ~ Action node not present in action STM.
#
# - Scenario 7
#   ~ Action STM exists at time function invoked.
#   ~ Visual STM exists at time function invoked.
#   ~ Action node specified has Action modality.
#   ~ Visual node specified has Visual modality.
#   ~ Attention is free at time function invoked.
#   ~ Action node present in action STM.
#   ~ Visual node not present in visual STM.
#
# - Scenario 8
#   ~ Action STM exists at time function invoked.
#   ~ Visual STM exists at time function invoked.
#   ~ Action node specified has Action modality.
#   ~ Visual node specified has Visual modality.
#   ~ Attention is free at time function invoked.
#   ~ Action node present in action STM.
#   ~ Visual node present in visual STM.
#   ~ Cognition isn't free at the time specified.
#   
# - Scenario 9
#   ~ Action STM exists at time function invoked.
#   ~ Visual STM exists at time function invoked.
#   ~ Action node specified has Action modality.
#   ~ Visual node specified has Visual modality.
#   ~ Attention is free at time function invoked.
#   ~ Action node present in action STM.
#   ~ Visual node present in visual STM.
#   ~ Cognition is free at the time specified.
#   ~ Production reinforcement isn't successful (production doesn't exist)
#
# - Scenario 10
#   ~ Action STM exists at time function invoked.
#   ~ Visual STM exists at time function invoked.
#   ~ Action node specified has Action modality.
#   ~ Visual node specified has Visual modality.
#   ~ Attention is free at time function invoked.
#   ~ Action node present in action STM.
#   ~ Visual node present in visual STM.
#   ~ Cognition is free at the time specified.
#   ~ Production reinforcement is successful.
#
# The function is expected to alter the attention and cognition clocks of the 
# CHREST model it is invoked in context of (if certain scenarios occur) and the
# return value of the function should differ depending on the scenario.  
# Therefore, the attention clock and cognition clock of the CHREST model this
# function is invoked in context of is checked after each scenario along with
# the return value of the function itself.
#
# Expected Outcomes
# =================
# 
# - Attention clock
#   ~ Scenarios 1-4: should not be altered from its initial value
#   ~ Scenario 5: should be set to the time it is "manually" set to by the test
#   ~ Scenario 6-10: should be set to the time taken to search through the 
#                    contents of action and visual STM (time taken to retrieve a 
#                    STM item multiplied by the number of Nodes in action and 
#                    visual STM).
#                    
# - Cognition clock
#   ~ Scenario 8: should be set to the time it is "manually" set to by the test
#   ~ Scenarios 1-9 (excluding 8): should not be altered from its initial value
#   ~ Scenario 10: should be set to the attention clock's value plus the time
#                  taken to reinforce a production
#                  
# - Value returned by function
#   ~ Scenarios 1-9: should return false
#   ~ Scenario 10: should return true
process_test "reinforce_production" do
  
  #######################################################
  ##### SET-UP ACEESS TO PRIVATE INSTANCE VARIABLES #####
  #######################################################
  
  # Chrest model field access
  Chrest.class_eval{
    field_accessor :_reinforcementLearningTheory,
    :_actionStm, 
    :_visualStm, 
    :_attentionClock, 
    :_cognitionClock, 
    :_timeToRetrieveItemFromStm,
    :_reinforceProductionTime
  }
  
  ##### Stm field access
  stm_item_history_field = Stm.java_class.declared_field("_itemHistory")
  stm_item_history_field.accessible = true
  
  ##### Node field access
  Node.class_eval{
    field_accessor :_productionHistory
  }
  
  node_modality_field = Node.java_class.declared_field("_modality")
  node_modality_field.accessible = true
  
  node_reference_field = Node.java_class.declared_field("_reference")
  node_reference_field.accessible = true
  
  #####################
  ##### TEST LOOP #####
  #####################
  100.times do
    for scenario in 1..10
      
      # Create CHREST model.
      time = 0
      model = Chrest.new(time, false)
      model._reinforcementLearningTheory = ReinforcementLearning::Theory::PROFIT_SHARING_WITH_DISCOUNT_RATE
      
      # Set the time the function is to be invoked (do this now since other 
      # times depend on this being set).
      time_function_invoked = time + 50
      
      ###################################
      ##### CREATE PRODUCTION Nodes #####
      ###################################
      
      # Set the time the Nodes are created to a random time between the time the
      # CHREST model is created and the time the function is invoked - 2 since
      # the production between the visual and action Nodes needs to be added.
      # The time the production is created needs to be after the creation time 
      # of the Nodes but before the time the production should be reinforced. 
      # The subtraction of 2 from the time the function is invoked gives some 
      # time for this.
      time_nodes_created = rand(time...(time_function_invoked - 2))
      action_node = Node.new(model, ListPattern.new(Modality::ACTION), ListPattern.new(Modality::ACTION), time_nodes_created)
      visual_node = Node.new(model, ListPattern.new(Modality::VISUAL), ListPattern.new(Modality::VISUAL), time_nodes_created)
      if scenario == 3 then node_modality_field.set_value(action_node, Modality::VISUAL) end
      if scenario == 4 then node_modality_field.set_value(visual_node, Modality::ACTION) end
      
      ########################
      ##### POPULATE STM #####
      ########################
      
      action_stm_item_history = stm_item_history_field.value(model._actionStm)
      action_stm_items = ArrayList.new()
      
      visual_stm_item_history = stm_item_history_field.value(model._visualStm)
      visual_stm_items = ArrayList.new()
      
      # Put 2 action/visual Nodes in action/visual STM before the action/visual 
      # Node used in the production is added so the function has to cycle when 
      # locating the action/visual Node used in the production.
      for i in 1..4
        
        # First 2 Nodes should have action modality, last 2 should have visual
        # modality.
        node = Node.new(
          model, 
          ListPattern.new( ((i == 1 || i == 2) ? Modality::ACTION : Modality::VISUAL) ), 
          ListPattern.new( ((i == 1 || i == 2) ? Modality::ACTION : Modality::VISUAL) ), 
          time_nodes_created
        )
        
        # Set the Node's reference so that it differs from the action/visual 
        # Nodes to be used in the production. To do this, add the local "i" 
        # variable to the visual Node's reference.  Since this was the last Node
        # created, any subsequent references will not equal the action/visual 
        # Node's references that are to be used in the production.
        node_reference_field.set_value(
          node, 
          node_reference_field.value(visual_node) + i
        )
        
        ((i == 1 || i == 2) ? action_stm_items.add(node) : visual_stm_items.add(node))
      end
      
      if scenario != 6 then action_stm_items.add(action_node) end
      if scenario != 7 then visual_stm_items.add(visual_node) end
      
      action_stm_item_history.put(time_nodes_created, action_stm_items)
      visual_stm_item_history.put(time_nodes_created, visual_stm_items)
      
      ##### Set action/visual STM item histories so they don't exist at the time
      ##### the function is invoked (if the scenario specifies this).
      stm_exists_after_function_invoked = HistoryTreeMap.new()
      stm_exists_after_function_invoked.put(time_function_invoked + 10000, ArrayList.new())
      
      if scenario == 1 then stm_item_history_field.set_value(model._actionStm, stm_exists_after_function_invoked) end
      if scenario == 2 then stm_item_history_field.set_value(model._visualStm, stm_exists_after_function_invoked) end
      
      # Set attention clock (if necessary)
      unavailable_attention_time = time_function_invoked + 10000
      if scenario == 5 then model._attentionClock = unavailable_attention_time end
      
      # Set cognition clock (if necessary)
      unavailable_cognition_time = time_function_invoked + 10000
      if scenario == 8 then model._cognitionClock = unavailable_cognition_time end
      
      #############################
      ##### CREATE PRODUCTION #####
      #############################
      
      if scenario != 9
        visual_node_productions = HashMap.new()
        visual_node_productions.put(action_node, (1.0).to_java(:Double))
        visual_node._productionHistory.put(time_nodes_created + 1, visual_node_productions)
      end
      
      ###########################
      ##### INVOKE FUNCTION #####
      ###########################
      
      reinforcement_calculation_variables = [1.0, 0.5, 1.0, 1.0].to_java(:Double)
      result = model.reinforceProduction(visual_node, action_node, reinforcement_calculation_variables, time_function_invoked)
      
      ##################################
      ##### SET EXPECTED VARIABLES #####
      ##################################
      
      # Set the expected return value.
      expected_result = (scenario == 10 ? true : false)
      
      # Set the expected attention clock value.
      expected_attention_clock = (time_function_invoked + (model._timeToRetrieveItemFromStm * 6))
      if scenario.between?(1,4)
        expected_attention_clock = -1
      elsif scenario == 5 
        expected_attention_clock = unavailable_attention_time
      elsif scenario == 6 || scenario == 7
        expected_attention_clock = (time_function_invoked + (model._timeToRetrieveItemFromStm * 5))
      end
      
      # Set the expected cognition clock value.
      expected_cognition_clock = -1
      if scenario == 8 then expected_cognition_clock = unavailable_cognition_time end
      if scenario == 10 then expected_cognition_clock = (expected_attention_clock + model._reinforceProductionTime) end
      
      #################
      ##### TESTS #####
      #################
      
      assert_equal(expected_result, result, "occurred when checking the result of invoking the function in scenario " + scenario.to_s)
      assert_equal(expected_attention_clock, model._attentionClock, "occurred when checking the attention clock in scenario " + scenario.to_s)
      assert_equal(expected_cognition_clock, model._cognitionClock, "occurred when checking the cognition clock in scenario " + scenario.to_s)
    end
  end
end

#unit_test "get maximum clock value" do
#  model = Chrest.new(0, GenericDomain.java_class)
#  
#  Set the learning clock to a value less than the attention clock.
#  model.setAttentionClock(200)
#  model.setLearningClock(199)
#  assert_equal(model.getAttentionClock(), model.getMaximumClockValue())
#  
#  Now set the learning clock so it is equal to the attention clock.
#  model.setLearningClock(200)
#  assert_equal(model.getAttentionClock(), model.getMaximumClockValue())
#  
#  Finally, set the learning clock so it is greater than the attention clock.
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
  model = Chrest.new(test_time, false)
  
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


################################################################################
# Tests the "Chrest.getInitialFixation()" method.
# 
# Scenario Details
# ================
# 
# - Scenario 1
#   ~ Attention is not free
#
# - Scenario 2
#   ~ Attention is free
#   ~ CHREST model is performing fixations
#
# - Scenario 3
#   ~ Attention is free
#   ~ CHREST model is not performing fixations
#   
# Expected Outcomes
# =================
# 
# - Scenario 1: no Fixation returned.
# - Scenario 2: no Fixation returned.
# - Scenario 3: Fixation returned.
#
unit_test "get_initial_fixation" do
  
  ###############################################################
  ##### SET-UP ACCESS TO PRIVATE METHODS/INSTANCE VARIABLES #####
  ###############################################################
  
  # The "getInitialFixation" method in a jchrest.architecture.Chrest instance is
  # private so it needs to be made accessible.
  method = Chrest.java_class.declared_method(:getInitialFixation, Java::int)
  method.accessible = true
  
  # The following jchrest.architecture.Chrest variables need to be made 
  # accessible so that they can be both set and checked.
  Chrest.class_eval{
    field_accessor :_attentionClock, :_performingFixations, :_visualStm
  }
  
  # Need access to the jchrest.architecture.Perceiver associated with the 
  # jchrest.architecture.Chrest model used in the test so that the test can 
  # set and check the the data structure that stores Fixations attempted by the 
  # Perceiver and the counter that stores what Fixation the Perceiver should 
  # learn from.
  chrest_perceiver_field = Chrest.java_class.declared_field("_perceiver")
  chrest_perceiver_field.accessible = true
  
  # Need access to the time the initial fixation is decided upon since this 
  # should be the time the attention clock is set to in scenario 3.
  fixation_time_decided_upon_field = Fixation.java_class.declared_field("_timeDecidedUpon")
  fixation_time_decided_upon_field.accessible = true
  
  # Need access to the jchrest.architecture.Perceiver _fixationToLearnFrom 
  # variable so it can be set and checked.
  Perceiver.class_eval{
    field_accessor :_fixationToLearnFrom
  }
  
  # Need access to the jchrest.architecture.Perceiver _fixations variable so it 
  # can be set and checked.
  perceiver_fixations_field = Perceiver.java_class.declared_field("_fixations");
  perceiver_fixations_field.accessible = true
  
  #########################
  ##### SCENARIO LOOP #####
  #########################
  
  for scenario in 1..3
    50.times do
      
      ###################################
      ##### SET-UP Chrest AND TIMES #####
      ###################################
      
      time = 0
      
      # Randomly choose if the CHREST model is learning object locations 
      # relative to itself or not, this shouldn't affect anything in the test.
      model = Chrest.new(time, [true, false].sample)
      
      # Set the time the function is invoked since the test requires that this 
      # be known in order to set up variables correctly.
      time_method_invoked = time + 50
      
      ########################################
      ##### POPULATE Perceiver FIXATIONS #####
      ########################################
      
      # Create new Fixations and add to a list
      fixations = ArrayList.new()
      4.times do
        fixations.add(PeripheralItemFixation.new(model, 3, time))
      end
      
      # Add list as value to map. Time last Fixation made should be before the
      # function is invoked.
      fixations_history = HistoryTreeMap.new()
      fixations_history.put(time, fixations)
      
      # Set the map to be perceiver fixations
      perceiver_fixations_field.set_value(chrest_perceiver_field.value(model), fixations_history)
      
      # Set the Perceiver's "_fixationToLearnFrom" instance variable since this
      # should be reset if the initial Fixation is scheduled successfully.
      chrest_perceiver_field.value(model)._fixationToLearnFrom = 3
      
      ###########################################
      ##### SET SCENARIO-SPECIFIC VARIABLES #####
      ###########################################
      
      if scenario == 1 then model._attentionClock = time_method_invoked + 100 end
      if scenario == 2 then model._performingFixations = true end
      
      ###########################
      ##### INVOKE FUNCTION #####
      ###########################
      
      result = method.invoke(model, time_method_invoked.to_java(:int))
      
      #################
      ##### TESTS #####
      #################
      
      # Check function return value
      assert_true(
        (scenario == 3 ? result != nil : result == nil), 
        "occurred when checking the result of the function in scenario " + 
        scenario.to_s
      )
      
      # Check attention clock
      expected_attention_clock = nil
      if scenario == 1 then expected_attention_clock = time_method_invoked + 100 end
      if scenario == 2 then expected_attention_clock = -1 end
      if scenario == 3 then expected_attention_clock = fixation_time_decided_upon_field.value(result) end
      assert_equal(
        expected_attention_clock,
        model._attentionClock, 
        "occurred when checking the attention clock in scenario " + scenario.to_s
      )
      
      # Check if model is now performing fixations
      expected_performing_fixations = (scenario == 1 ? false : true)
      assert_equal(
        expected_performing_fixations,
        model._performingFixations,
        "occurred when checking if the model is performing Fixations in " +
        "scenario " + scenario.to_s
      )
      
      # Check Perceiver fixations
      perceiver_fixations = perceiver_fixations_field.value(chrest_perceiver_field.value(model)).floorEntry(time_method_invoked.to_java(:int)).getValue()
      assert_true( 
        (scenario == 3 ? 
          perceiver_fixations.isEmpty() :
          !perceiver_fixations.isEmpty()
        ),
        "occurred when checking the Perceiver's Fixations in scenario " + scenario.to_s
      )
      
      # Check Perceiver's fixation to learn from counter
      expected_fixation_to_learn_from = (scenario == 3 ? 0 : 3)
      assert_equal(
        expected_fixation_to_learn_from,
        chrest_perceiver_field.value(model)._fixationToLearnFrom,
        "occurred when checking the Fixation to learn from in scenario " + scenario.to_s
      )
    end
  end
end

################################################################################
# Tests the "Chrest.getNonInitialFixation()" method using various scenarios that
# should cover all potential configurations of variables intrinsic to the 
# method's operation.
# 
# Scenario Details
# ================
# 
# - Scenario 1
#   ~ Attention not free
#   
# - Scenario 2
#   ~ The CHREST model is not performing fixations currently
#   
# - Scenario 3
#   ~ Number fixations scheduled + number fixations attempted = max fixations
#   
# - Scenario 4
#   ~ Number fixations scheduled + number fixations attempted > max fixations
# 
# - Scenario 5
#   ~ Domain specifics stipulates fixations should not be added
#
# - Scenario 6
#   ~ All OK.
#
unit_test "get_non_initial_fixation" do
  
  ###############################################################
  ##### SET-UP ACCESS TO PRIVATE METHODS/INSTANCE VARIABLES #####
  ###############################################################
  
  # The "getNonInitialFixation" method in a jchrest.architecture.Chrest instance 
  # is private so it needs to be made accessible.
  method = Chrest.java_class.declared_method(:getNonInitialFixation, Java::int, Java::int, Java::int)
  method.accessible = true
  
  # Need to set what domain the CHREST model uses to enable scenario-specific
  # behaviour and the test needs to set and check the attention clock of the
  # CHREST model used in the test.
  Chrest.class_eval{
    field_accessor :_domainSpecifics, :_attentionClock, :_performingFixations
  }
  
  # Need access to the time the non-initial fixation is decided upon since this 
  # should be the time the attention clock is set to in scenario 5.
  fixation_time_decided_upon_field = Fixation.java_class.declared_field("_timeDecidedUpon")
  fixation_time_decided_upon_field.accessible = true
  
  for scenario in 1..6
    50.times do
      
      ###############################
      ##### SET-UP Chrest MODEL #####
      ###############################
      
      time = 0
      
      # Randomly choose if the CHREST model is learning object locations 
      # relative to itself or not, this shouldn't affect anything in the test.
      model = Chrest.new(time, [true, false].sample)
      
      ####################################################
      ##### CONSTRUCT DOMAIN AND SET TO Chrest MODEL #####
      ####################################################
      
      # Set the maximum number of domain fixations to a variable since this is 
      # needed to set the number of fixations scheduled/attempted below.
      max_domain_fixations = 5
      
      # Override the GenericDomain.shouldAddNewFixation method so that it will 
      # return whatever a new local variable called "add_new_fixation" is set 
      # to.  This variable should be able to be set on a per-scenario basis so
      # implement a method to do this in the overridden GenericDomain class.
      domain = Class.new(GenericDomain) {
        @add_new_fixation
        
        def setAddNewFixation(x)
          @add_new_fixation = x
        end
        
        def shouldAddNewFixation(x)
          return @add_new_fixation
        end
      }.new(model, max_domain_fixations, 3)
      
      # Set the overridden GenericDomain class to be used by the CHREST model.
      model._domainSpecifics = domain
      
      ###########################################
      ##### SET SCENARIO-SPECIFIC VARIABLES #####
      ###########################################
      
      # By default the variables should be set to enable a Fixation to be 
      # successfully returned.
      time_method_invoked = time + 50
      number_fixations_scheduled = max_domain_fixations - 2
      number_fixations_attempted = 1
      add_new_fixation = true
      
      if scenario == 1 then model._attentionClock = time_method_invoked + 100 end
      model._performingFixations = (scenario == 2 ? false : true)
      if scenario == 3 then number_fixations_attempted = 2 end
      if scenario == 4 then number_fixations_attempted = 3 end
      if scenario == 5 then add_new_fixation = false end
      
      # Need to set whether the overridden GenericDomain class will return true
      # or false when queried regarding if a new Fixation should be added.
      domain.setAddNewFixation(add_new_fixation)
      
      ###########################
      ##### INVOKE FUNCTION #####
      ###########################
      
      result = method.invoke(model, time_method_invoked, number_fixations_scheduled, number_fixations_attempted)
      
      #################
      ##### TESTS #####
      #################
      
      # Check result of method
      assert_true(
        (scenario == 6 ? 
          result != nil :
          result == nil
        ),
        "occurred when checking the result of the method in scenario " + scenario.to_s
      )
      
      # Check attention clock of CHREST model
      expected_attention_clock = -1
      if scenario == 1 then expected_attention_clock = time_method_invoked + 100 end
      if scenario == 6 then expected_attention_clock = fixation_time_decided_upon_field.value(result) end
      
      assert_equal(
        expected_attention_clock,
        model._attentionClock,
        "occurred when checking the attention clock in scenario " + scenario.to_s
      )
    end
  end
end

################################################################################
# Tests the "Chrest.perform_scheduled_fixations()" method using a number of 
# scenarios that should cover all possible scenarios this method will encounter.
#
# Scenario Descriptions and Expected Outcomes
# ===========================================
# 
# - Scenario 1
#   ~ The Fixation list to be passed to the method as a parameter contains one 
#     Fixation whose performance time is set to null.
#   ~ Expected outcome:
#     + No exception thrown by method since no Fixation in the input has a 
#       performance time less than the time the method is invoked.
#     + Empty list returned since no Fixations were attempted.
#     + Fixations should not be learned from.
#     + Fixation should not be added to Perceiver's attempted Fixation data
#       structure.
#     + The CHREST model's "_fixationsAttemptedInCurrentSet" variable should 
#       equal 0 since there is no attempt made to perform the Fixation.
#   
# - Scenario 2
#   ~ The Fixation list to be passed to the method as a parameter contains one 
#     Fixation whose performance time is set in the future relative to the time 
#     passed as an input parameter to the method.
#   ~ Expected outcome:
#     + No exception thrown by method since no Fixation in the input has a 
#       performance time less than the time the method is invoked.
#     + Empty list returned since no Fixations were attempted.
#     + Fixations should not be learned from.
#     + Fixation should not be added to Perceiver's attempted Fixation data
#       structure.
#     + The CHREST model's "_fixationsAttemptedInCurrentSet" variable should 
#       equal 0 since there is no attempt made to perform the Fixation.
#     
# - Scenario 3
#   ~ The Fixation list to be passed to the method as a parameter contains one 
#     Fixation whose performance time is set in the past relative to the time 
#     passed as an input parameter to the method.
#   ~ Expected outcome:
#     + An exception should be thrown by method since the Fixation in the input 
#       has a performance time less than the time the method is invoked.
#     + No output from the method.
#     + Fixations should not be learned from.
#     + Fixation should not be added to Perceiver's attempted Fixation data
#       structure.
#     + The CHREST model's "_fixationsAttemptedInCurrentSet" variable should 
#       equal 0 since there is no attempt made to perform the Fixation.
#
# - Scenario 4
#   ~ The Fixation list to be passed to the method as a parameter contains one 
#     Fixation whose performance time is set to the time passed as an input 
#     parameter to the method.  The Scene to fixate on means that the Fixation
#     can not be performed successfully, however.
#   ~ Expected outcome:
#     + No exception thrown by method since no Fixation in the input has a 
#       performance time less than the time the method is invoked.
#     + List containing the Fixation since it was attempted.
#     + Fixations should not be learned from.
#     + Fixation should be added to Perceiver's attempted Fixation data
#       structure.
#     + The CHREST model's "_fixationsAttemptedInCurrentSet" variable should 
#       be incremented by 1 since an attempt is made to perform the Fixation.
#
# - Scenario 5
#   ~ The Fixation list to be passed to the method as a parameter contains one 
#     Fixation whose performance time is set to the time passed as an input 
#     parameter to the method.  The Scene to fixate on means that the Fixation
#     can be performed successfully, however, the Fixation will fixate on a 
#     SceneObject that has already been fixated on when it is performed.  The 
#     domain-specifics of the CHREST model states that new Fixations should not 
#     be learned from.
#   ~ Expected outcome:
#     + No exception thrown by method since no Fixation in the input has a 
#       performance time less than the time the method is invoked.
#     + List containing the Fixation since it was attempted.
#     + Fixations should be learned from since a SceneObject has been fixated on
#       more than once by two Fixations in the same set (regardless of what the 
#       domain-specifics stipulate).
#     + Fixation should be added to Perceiver's attempted Fixation data
#       structure.
#     + The CHREST model's "_fixationsAttemptedInCurrentSet" variable should 
#       be incremented by 1 since an attempt is made to perform the Fixation.
#
# - Scenario 6
#   ~ The Fixation list to be passed to the method as a parameter contains one 
#     Fixation whose performance time is set to the time passed as an input 
#     parameter to the method.  The Scene to fixate on means that the Fixation
#     can be performed successfully, however, the Fixation will fixate on a 
#     Square that has already been fixated on when it is performed.  The 
#     domain-specifics of the CHREST model states that new Fixations should not 
#     be learned from.
#   ~ Expected outcome:
#     + No exception thrown by method since no Fixation in the input has a 
#       performance time less than the time the method is invoked.
#     + List containing the Fixation since it was attempted.
#     + Fixations should be learned from since a Square has been fixated on
#       more than once by two Fixations in the same set (regardless of what the 
#       domain-specifics stipulate).
#     + Fixation should be added to Perceiver's attempted Fixation data
#       structure.
#     + The CHREST model's "_fixationsAttemptedInCurrentSet" variable should 
#       be incremented by 1 since an attempt is made to perform the Fixation.
#       
# - Scenario 7 
#   ~ The Fixation list to be passed to the method as a parameter contains one 
#     Fixation whose performance time is set to the time passed as an input 
#     parameter to the method.  The Scene to fixate on means that the Fixation
#     can be performed successfully, and the Fixation will not fixate on a 
#     SceneObject or Square that has already been fixated on.  The 
#     domain-specifics of the CHREST model states that new Fixations should not 
#     be learned from.
#   ~ Expected outcome:
#     + No exception thrown by method since no Fixation in the input has a 
#       performance time less than the time the method is invoked.
#     + List containing the Fixation since it was attempted.
#     + Fixations should not learned from since the domain-specifics stipulate
#       that Fixations should not be learned from and the SceneObject/Square 
#       fixated on have not been fixated on by any other Fixation in this set.
#     + Fixation should be added to Perceiver's attempted Fixation data
#       structure.
#     + The CHREST model's "_fixationsAttemptedInCurrentSet" variable should 
#       be incremented by 1 since an attempt is made to perform the Fixation.
#       
# - Scenario 8
#   ~ The Fixation list to be passed to the method as a parameter contains one 
#     Fixation whose performance time is set to the time passed as an input 
#     parameter to the method.  The Scene to fixate on means that the Fixation
#     can be performed successfully, and the Fixation will not fixate on a 
#     SceneObject or Square that has already been fixated on. However, the 
#     domain-specifics of the CHREST model states that new Fixations should be 
#     learned from.
#   ~ Expected outcome:
#     + No exception thrown by method since no Fixation in the input has a 
#       performance time less than the time the method is invoked.
#     + List containing the Fixation since its performance time is equal to
#       the time the method is invoked.
#     + Fixations should be learned from since the domain-specifics stipulate
#       that Fixations should be learned from (regardless of whether the 
#       SceneObject and Square have never been fixated on before by a Fixation
#       performed in the current set).
#     + Fixation should be added to Perceiver's attempted Fixation data
#       structure.
#     + The CHREST model's "_fixationsAttemptedInCurrentSet" variable should 
#       be incremented by 1 since an attempt is made to perform the Fixation.
#   
# - Scenario 9 
#   ~ The Fixation list to be passed to the method as a parameter contains two 
#     Fixations whose performance time is set to the time passed as an input 
#     parameter to the method.  The Scenes to fixate on means that both 
#     Fixations can be performed successfully, and neither Fixation will fixate
#     on a SceneObject or Square that has already been fixated on. However, the 
#     domain-specifics of the CHREST model states that new Fixations should be 
#     learned from.
#   ~ Expected outcome:
#     + No exception thrown by method since no Fixation in the input has a 
#       performance time less than the time the method is invoked.
#     + List containing both Fixations since their performance time is equal to
#       the time the method is invoked.
#     + Fixations should be learned from since the domain-specifics stipulate
#       that Fixations should be learned from (regardless of whether the 
#       SceneObject and Square have never been fixated on before by a Fixation
#       performed in the current set).
#     + Only the first Fixation should be added to Perceiver's attempted 
#       Fixation data structure.  The second should be abandoned.
#     + The CHREST model's "_fixationsAttemptedInCurrentSet" variable should 
#       be incremented by 1 since the only Fixation whose performance is 
#       attempted is the first Fixation.
#
# - Scenario 10
#   ~ The Fixation list to be passed to the method as a parameter contains two 
#     Fixations whose performance time is set to the time passed as an input 
#     parameter to the method.  The Scenes to fixate on means that only the 
#     second Fixation can be performed successfully.  If they were performed,
#     neither Fixation would fixate on a SceneObject or Square that has already 
#     been fixated on. However, the domain-specifics of the CHREST model states 
#     that new Fixations should be learned from.
#   ~ Expected outcome:
#     + No exception thrown by method since no Fixation in the input has a 
#       performance time less than the time the method is invoked.
#     + List containing both Fixations since their performance time is equal to
#       the time the method is invoked.
#     + Fixations should be learned from since the domain-specifics stipulate
#       that Fixations should be learned from (regardless of whether the 
#       SceneObject and Square have never been fixated on before by a Fixation
#       performed in the current set).
#     + Only the first Fixation should be added to Perceiver's attempted 
#       Fixation data structure.  The second should be abandoned.
#     + The CHREST model's "_fixationsAttemptedInCurrentSet" variable should 
#       be incremented by 1 since the only Fixation whose performance is 
#       attempted is the first Fixation.
#
# Since the method takes into consideration previous Fixations, in most scenarios
unit_test "perform_scheduled_fixations" do
  
  ###############################################################
  ##### SET-UP ACCESS TO PRIVATE METHODS/INSTANCE VARIABLES #####
  ###############################################################
  
  # The "performScheduledFixations" method in a jchrest.architecture.Chrest 
  # instance is private so it needs to be made accessible.
  method = Chrest.java_class.declared_method(:performScheduledFixations, List, Scene, Java::int)
  method.accessible = true
  
  Chrest.class_eval{
    field_accessor :_domainSpecifics, :_fixationsAttemptedInCurrentSet
  }
  
  chrest_perceiver_field = Chrest.java_class.declared_field("_perceiver")
  chrest_perceiver_field.accessible = true
  
  fixation_reference_field = Fixation.java_class.declared_field("_reference")
  fixation_reference_field.accessible = true
  
  Fixation.class_eval{
    field_accessor :_timeDecidedUpon, 
      :_performanceTime,
      :_performed,
      :_scene,
      :_colFixatedOn,
      :_rowFixatedOn,
      :_objectSeen
  }
  
  Scene.class_eval{
    field_accessor :_scene
  }
  
  perceiver_fixations_field = Perceiver.java_class.declared_field("_fixations")
  perceiver_fixations_field.accessible = true
  
  Perceiver.class_eval{
    field_accessor :_fixationToLearnFrom
  }
  
  for scenario in 1..10
    
    50.times do
      
      ##################################################
      ##### CONSTRUCT CHREST AND METHOD PARAMETERS #####
      ##################################################
      
      # Construct CHREST model.
      time = 0
      model_learning_object_locations_relative_to_self = [true, false].sample
      model = Chrest.new(time, model_learning_object_locations_relative_to_self)
      
      # Create Fixation list to be passed to the method.
      fixations_scheduled = ArrayList.new()
      
      # Construct the Scene to Fixate on
      scene_to_fixate_on = Scene.new("scene_to_fixate_on", 3, 3, 0, 0, nil)
      
      # Set time method will be invoked (other test variables depend on this 
      # being known now).
      time_method_invoked = time + 200
      
      ###############################################
      ##### CONSTRUCT FIRST FIXATION TO BE MADE #####
      ###############################################
      
      time_fixation_1_decided_upon = time + 50
      fixation_1 = CentralFixation.new(time_fixation_1_decided_upon)
      if scenario == 1
        fixation_1._performanceTime = nil
      elsif scenario == 2  
        fixation_1._performanceTime = time_method_invoked + 100  
      elsif scenario == 3  
        fixation_1._performanceTime = time_method_invoked - 10 
      else
        fixation_1._performanceTime = time_method_invoked
      end
      
      # Ensure that, in all other scenarios except 4 and 10, the first Fixation
      # will be performed successfully (in scenarios 4 and 10, the Square 
      # fixated on will be blind since all Squares in a Scene are blind when a
      # Scene is constructed, this will cause a CentralFixation to fail when an
      # attempt to make it is made).
      if ![4,10].include?(scenario)
        scene_to_fixate_on._scene.get(1).set(1, SceneObject.new("0", "A"))
      end
      
      # Add first Fixation to Fixation list to be passed to the method.
      fixations_scheduled.add(fixation_1)
      
      ################################################################
      ##### CONSTRUCT SCENE FIXATED ON BY PREVIOUS FIXATION MADE #####
      ################################################################
      
      # In scenarios 6 and 10, domain coordinates will be the same as the Scene 
      # to fixate on but different otherwise.
      previous_fixation_scene = Scene.new(
        "scene_previously_fixated_on", 
        3, 
        3, 
        ([6,10].include?(scenario) ? 0 : 1),
        ([6,10].include?(scenario) ? 0 : 1), 
        nil
      )
      
      previous_fixation_scene._scene.get(1).set(1, 
        scenario == 5 ? SceneObject.new("0", "A") : #Different domain coordinates fixated on but SceneObject fixated on previously
        scenario == 6 ? SceneObject.new(Scene::EMPTY_SQUARE_TOKEN) : #Same domain coordinates fixated on but different SceneObject fixated on previously
        SceneObject.new("1", "A") #Different domain coordinates and SceneObject fixated on
      ) 
      
      #########################################################################
      ##### ADD CREATOR TO SCENE TO FIXATE ON AND PREVIOUS FIXATION SCENE #####
      #########################################################################
      
      # If the model is learning object locations relative to itself then a
      # Creator token should be in the Scene otherwise an exception will be 
      # thrown by the Perceiver when fixations are learned from since, if the 
      # model is learning object locations relative to itself, it expects a
      # Creator token in every Scene fixated on.  Thus, an exception may be 
      # thrown in a scenario other than 3 which is not expected in context of 
      # this test and undesirable.
      if model_learning_object_locations_relative_to_self
        scene_to_fixate_on._scene.get(2).set(2, SceneObject.new(Scene::CREATOR_TOKEN))
        previous_fixation_scene._scene.get(2).set(2, SceneObject.new(Scene::CREATOR_TOKEN))
      end
      
      ############################################################
      ##### CONSTRUCT PREVIOUS FIXATION AND ADD TO PERCEIVER #####
      ############################################################
      
      # Construct previous Fixation
      previous_fixation = CentralFixation.new(time + 10)
      previous_fixation._performanceTime = rand((previous_fixation._timeDecidedUpon + 1)...time_fixation_1_decided_upon)
      previous_fixation._performed = true
      previous_fixation._scene = previous_fixation_scene
      previous_fixation._colFixatedOn = 1
      previous_fixation._rowFixatedOn = 1
      previous_fixation._objectSeen = previous_fixation_scene._scene.get(previous_fixation._colFixatedOn).get(previous_fixation._rowFixatedOn)
      
      # Add to Perceiver
      previous_fixations = ArrayList.new()
      previous_fixations.add(previous_fixation)
      fixations_attempted_history = HistoryTreeMap.new()
      fixations_attempted_history.put(previous_fixation._performanceTime, previous_fixations)
      perceiver_fixations_field.set_value(chrest_perceiver_field.value(model), fixations_attempted_history)
      
      ############################
      ##### CONSTRUCT DOMAIN #####
      ############################
      
      # Override the GenericDomain.shouldLearnFromNewFixations method so that it 
      # will return whatever a new local variable called 
      # "learn_from_new_fixations" is set to.  This variable should be able to 
      # be set on a per-scenario basis so implement a method to do this in the 
      # overridden GenericDomain class.
      domain = Class.new(GenericDomain) {
        @learn_from_new_fixations = false
        
        def setLearnFromNewFixations(x)
          @learn_from_new_fixations = x
        end
        
        def shouldLearnFromNewFixations(x)
          return @learn_from_new_fixations
        end
      }.new(model, 10, 3)
      
      if scenario.between?(8,10) 
        domain.setLearnFromNewFixations(true) 
      end
      
      # Set the overridden GenericDomain class to be used by the CHREST model.
      model._domainSpecifics = domain
      
      ###############################################
      ##### ADD SECOND FIXATION TO BE PERFORMED #####
      ###############################################
      
      time_fixation_2_decided_upon = nil
      if scenario > 8
        time_fixation_2_decided_upon = time_fixation_1_decided_upon + 10
        fixation_2 = PeripheralSquareFixation.new(model, time_fixation_2_decided_upon)
        fixation_2._performanceTime = time_method_invoked
        fixations_scheduled.add(fixation_2)
        
        # Second fixation needs to be able to succeed in scenario 10 (it'll never
        # actually be performed but do this for realism) so add an empty square
        # on the "periphery" of the previous fixation's fixation point.  When 
        # the PeripheralSquareFixation is made, it should ignore the Creator in
        # the Scene (if present), ignore the Square previously fixated on and
        # fixate on (0, 0) since all other Squares are blind.
        if scenario == 10 then scene_to_fixate_on._scene.get(0).set(0, SceneObject.new(Scene::EMPTY_SQUARE_TOKEN)) end
      end
      
      #########################
      ##### INVOKE METHOD #####
      #########################
      
      method_return_value = nil
      exception_thrown = false
      begin
        method_return_value = method.invoke(model, fixations_scheduled, scene_to_fixate_on, time_method_invoked)
      rescue
        exception_thrown = true
      end
      
      # For some reason, the method's result value needs to be cast to the 
      # correct type.  Possibly because there's some "under-the-hood" work by
      # method.invoke() that wraps the return value.  Since a generic type is 
      # returned too it appears that JRuby can't handle this appropriately 
      # (despite "puts method_return_value.java_class" returning 
      # "java.util.ArrayList" when method_return_value is non-null).  So, if the 
      # cast isn't performed, JRuby complains that the "size" method that's 
      # invoked on the non-null method_return_value isn't a valid method for the 
      # object.
      if method_return_value != nil then method_return_value = method_return_value.to_java(ArrayList) end
      
      #################
      ##### TESTS #####
      #################
      
      ###### Check if exception thrown
      expected_exception_thrown = (scenario == 3 ? true : false)
      assert_equal(
        expected_exception_thrown, 
        exception_thrown, 
        "occurred when checking if an exception is thrown by the method in " +
        "scenario " + scenario.to_s
      )
      
      ##### Check method return value if exception is not thrown
      if !exception_thrown
        
        # Check return value size
        expected_method_return_value_size = 1
        if [1,2].include?(scenario) then expected_method_return_value_size = 0 end
        if [9,10].include?(scenario) then expected_method_return_value_size = 2 end
        
        assert_equal(
          expected_method_return_value_size,
          method_return_value.size,
          "occurred when checking the size of the value returned by the method in scenario " + scenario.to_s
        )
      
        # Check return value contents
        expected_method_return_value_contents = ArrayList.new()
        if [4..8].include?(scenario) 
          expected_method_return_value_contents.add(fixation_1)
        elsif [9,10].include?(scenario)
          expected_method_return_value_contents.add(fixation_1)
          expected_method_return_value_contents.add(fixation_2)
        end
        for i in 0...expected_method_return_value_contents.size()
          assert_equal(
            expected_method_return_value_contents.get(i).toString(),
            method_return_value.get(i).toString(),
            "occurred when checking Fixation " + i.to_s + " in scenario " + scenario.to_s
          )
        end
      end
      
      ##### Check if Fixations learned from
      expected_fixation_to_learn_from_counter = 0
      if [5,6,8,9].include?(scenario) then expected_fixation_to_learn_from_counter = 1 end
        
      assert_equal(
        expected_fixation_to_learn_from_counter,
        chrest_perceiver_field.value(model)._fixationToLearnFrom,
        "occurred when checking the Perceiver's _fixationToLearnFrom variable in scenario " + scenario.to_s
      )
        
      ##### Check Perceiver's fixations
      expected_perceiver_fixations = ArrayList.new()
        
      # The previous_fixation is always added, regardless of the scenario so
      # this should always be expected.
      expected_perceiver_fixations.add(previous_fixation)
        
      # Except in scenarios 1-3, fixation_1 is expected to exist in the
      # Perceiver's attempted Fixations data structure at the time the 
      # method is invoked.
      if scenario > 3
        expected_fixation = CentralFixation.new(0)
        fixation_reference_field.set_value(expected_fixation, fixation_reference_field.value(fixation_1))
        expected_fixation._timeDecidedUpon = time_fixation_1_decided_upon
        expected_fixation._performanceTime = time_method_invoked
        expected_fixation._scene = scene_to_fixate_on

        if ![4,10].include?(scenario)
          expected_fixation._performed = true
          expected_fixation._colFixatedOn = 1
          expected_fixation._rowFixatedOn = 1
          expected_fixation._objectSeen = scene_to_fixate_on._scene.get(expected_fixation._colFixatedOn).get(expected_fixation._rowFixatedOn)
        end

        expected_perceiver_fixations.add(expected_fixation)
      end
        
      perceiver_fixations = perceiver_fixations_field.value(chrest_perceiver_field.value(model)).floorEntry(time_method_invoked.to_java(:int)).getValue()

      assert_equal(
        expected_perceiver_fixations.size(),
        perceiver_fixations.size(),
        "occurred when checking the size of the Perceiver's attempted Fixations data structure in scenario " + scenario.to_s
      )

      for i in 0...expected_perceiver_fixations.size()
        assert_equal(
          expected_perceiver_fixations.get(i).toString,
          perceiver_fixations.get(i).toString,
          "occurred when checking if Fixation " + i.to_s + " in the " +
          "Perceiver's attempted Fixations data structure is as expected in " +
          "scenario " + scenario.to_s
        )
      end
      
      # Check Chrest._fixationsAttemptedInCurrentSet 
      expected_fixations_attempted_in_current_set = (
        scenario.between?(1,3) ? 0 :
        1
      )
      assert_equal(
        expected_fixations_attempted_in_current_set,
        model._fixationsAttemptedInCurrentSet,
        "occurred when checking the _fixationsAttemptedInCurrentSet model " +
        "parameter in scenario " + scenario.to_s
      )
    end
  end
end

################################################################################
# Tests the "Chrest.tagVisualSpatialFieldObjectsFixatedOnAsRecognised()" method
# using various scenarios that should simulate every possible scenario this 
# method will have to handle.  
# 
# Every set of Scenarios is repeated twice:
# 
# - Repeat 1: CHREST model is not learning object locations relative to self 
# - Repeat 2: CHREST model is learning object locations relative to self
# 
# The VisualSpatialField used in these tests is as follows 
# (VisualSpatialFieldObjects are denoted by their identifier followed by their 
# type in parenthesis):
#
# Visual-Spatial Field Used
# =========================
# 
# NOTE: VisualSpatialFieldObject with identifier "0" is the creator.  This will
#       not be present in repeat 1.
#  
#       |--------|--------|--------|--------|--------|
# 4   6 |        |        |  6(F)  |        |        |
#       |--------|--------|--------|--------|--------|
# 3   5 |        |  4(D)  |        |  2(B)  |        |
#       |--------|--------|--------|--------|--------|
# 2   4 |  5(E)  |        | 0(CRT) |        |  7(G)  |
#       |--------|--------|--------|--------|--------|
# 1   3 |        |  1(A)  |        |  3(C)  |        |
#       |--------|--------|--------|--------|--------|
# 0   2 |        |        |  8(H)  |        |        |
#       |--------|--------|--------|--------|--------|
#           2        3        4        5        6     DOMAIN-COORDINATES
#           0        1        2        3        4     VISUAL-SPATIAL FIELD COORDINATES
# 
# Scenario Details
# ================
# 
# - Scenario 1
#   ~ Input Fixation has not been performed.
#
# - Scenario 2
#   ~ Input Fixation has been performed.
#   ~ Scene fixated on by input Fixation does not represent a visual-spatial 
#     field.
#
# - Scenario 3
#   ~ Input Fixation has been performed.
#   ~ Scene fixated on by input Fixation does represents a visual-spatial field.
#   ~ No recognition occurs.
#
# - Scenario 4
#   ~ Input Fixation has been performed.
#   ~ Scene fixated on by input Fixation does not represent a visual-spatial 
#     field.
#   ~ Recognition occurs and Visual STM is empty before "recognition".
#
# - Scenario 5
#   ~ Fixation has been performed
#   ~ Scene fixated on by Fixation does not represent a visual-spatial field
#   ~ Visual STM not empty and recognition does not occur.
#
# - Scenario 6
#   ~ Fixation has been performed
#   ~ Scene fixated on by Fixation does not represent a visual-spatial field
#   ~ Recognition occurs, before this, Visual STM is not empty after recognition
#     its contents differ.
#     
# "Recognition" is simulated by populating Visual STM manually after the 
# Fixation has been performed.  To do this, the attention clock of the CHREST 
# model is set to a certain value and the item history of the Visual STM
# associated with the CHREST model has an entry added to it at the time the 
# CHREST model's attention clock has been set to.  If recognition occurs:  
#
# - The Visual LTM root Node will be added to check that the method handles them
#   gracefully.
# - Every other Node added will have a non-empty content/image and its item and
#   position slots will be filled.  This allows the test to check that all of 
#   these sources of information are used to determine what 
#   VisualSpatialFieldObjects are recognised.
# - Up to three Nodes may be added these are:
#   ~ Visual LTM root Node
#   ~ node_1
#   ~ node_2 (only in scenario 6)
# - node_1 and node_2's contents, image, filled item slot and filled position 
#   slot contain the location for 1 VisualSpatialFieldObject on the 
#   VisualSpatialField:
#   ~ node_1
#     + Contents
#       > Denotes VisualSpatialFieldObject with identifier "1" and type "A".
#     + Image
#       > Denotes VisualSpatialFieldObject with identifier "2" and type "B".
#     + Filled item slot
#       > Denotes VisualSpatialFieldObject with identifier "3" and type "C".
#     + Filled position slot
#       > Denotes VisualSpatialFieldObject with identifier "4" and type "D".
#   ~ node_2
#     + Contents
#       > Denotes VisualSpatialFieldObject with identifier "5" and type "E".
#     + Image
#       > Denotes VisualSpatialFieldObject with identifier "6" and type "F".
#     + Filled item slot
#       > Denotes VisualSpatialFieldObject with identifier "7" and type "G".
#     + Filled position slot
#       > Denotes VisualSpatialFieldObject with identifier "8" and type "H".
#       
# In Scenarios 4-6, Visual STM will be populated in the following way:
# 
# - Scenario 4
#   ~ At Fixation performance time: empty
#   ~ At time attention clock is set: Visual LTM root Node, node_1
# 
# - Scenario 5
#   ~ At Fixation performance time: Visual LTM root Node, node_1
#   ~ At time attention clock is set: Visual LTM root Node, node_1
#   
# - Scenario 6
#   ~ At Fixation performance time: Visual LTM root Node, node_2
#   ~ At Fixation performance time: Visual LTM root Node, node_2, node_1
#   
# Before discussing expected outcomes, the status of VisualSpatialFieldObjects
# should be noted:
# 
# - 1(A) is not recognised but will not be "alive" at the time the CHREST 
#   model's attention clock is set to.
#   
# - 2(B) is not recognised and will be "alive" at the time the CHREST model's 
#   attention clock is set to.
#   
# - 3(C) is recognised and will be "alive" at the time the CHREST model's 
#   attention clock is set to.
#   
# - 4(D) is recognised and will be "alive" at the time the CHREST model's 
#   attention clock is set to.
#   
# - 5(E), 6(F), 7(G) and 8(H) are not recognised and will be "alive" at the time 
#   the CHREST model's attention clock is set to.
#   
# Note also that the terminus of all VisualSpatialFieldObjects except 1(A) will
# not be set, the reasoning for this will be explained below.
#
# Expected Output
# ===============
# 
# Recognition should only occur in scenarios 4 and 6 and 
# VisualSpatialFieldObjects denoted in the contents, image and filled 
# item/position slots of Nodes that have been added to Visual STM after the 
# Fixation has been performed, i.e. at the time the CHREST model's attention 
# clock is set to, should have their "recognised" status set at the time the 
# CHREST model's attention clock is set to and their terminus should be updated
# automatically (if the VisualSpatialFieldObject is alive).  Thus, by ensuring 
# that 1(A) is not alive at the time recognition occurs, the test can check to
# see if it is ignored appropriately.  Furthermore, since none of the other
# VisualSpatialFieldObject's termini are set when created or afterwards, the 
# test can also verify that this variable is set correctly for recognised 
# VisualSpatialFieldObjects.  Finally, since node_1 is the only Node that will
# be considered as being "recognised", VisualSpatialFieldObjects referenced in
# node_2 should not be altered in any way (this is why they are unrecognised 
# when created and their termini are set to null).
# 
# So, in Scenarios 4 and 6, the recognised status and termini of 
# VisualSpatialFieldObjects 2(B), 3(C) and 4(D) should be updated *only*.
#
unit_test "tag_visual_spatial_field_objects_fixated_on_as_recognised" do
  
  #######################################################
  ##### SET-UP ACCESS TO PRIVATE INSTANCE VARIABLES #####
  #######################################################
  
  # The "tagVisualSpatialFieldObjectsFixatedOnAsRecognised" method in a 
  # jchrest.architecture.Chrest instance is private so it needs to be made 
  # accessible.
  method = Chrest.java_class.declared_method(:tagVisualSpatialFieldObjectsFixatedOnAsRecognised, Fixation)
  method.accessible = true
  
  # Need access to visual LTM root Node so it can be placed in visual STM.  Also
  # need access to the attention clock so that visual STM can be set according
  # to the scenario requirements.  Finally, need access to the lifespan defined
  # for recognised VisualSpatialFieldObjects so the status of recognised 
  # VisualSpatialFieldObjects can be set for checking.
  Chrest.class_eval{
    field_accessor :_visualLtm, :_visualStm, :_attentionClock, :_recognisedVisualSpatialFieldObjectLifespan
  }
  
  # Need to be able to access the visual-spatial field's actual field to 
  # populate it.
  vsf_field = VisualSpatialField.java_class.declared_field("_visualSpatialField")
  vsf_field.accessible = true
  
  # Needed to be able to precisely stipulate if VisualSpatialFieldObjects are 
  # alive.
  VisualSpatialFieldObject.class_eval{
    field_accessor :_terminus
  }
  
  # Needed to set and check recognised status of VisualSpatialFieldObjects
  vsfo_recognised_field = VisualSpatialFieldObject.java_class.declared_field("_recognisedHistory")
  vsfo_recognised_field.accessible = true
  
  # Needed to that Node contents/image can be constructed precisely.
  ListPattern.class_eval{
    field_accessor :_list
  }
  
  # Need to be able to fill a Node's item and position slots
  Node.class_eval{
    field_accessor :_filledItemSlotsHistory, :_filledPositionSlotsHistory
  }
  
  # Need to be able to set various Fixation variables depending on the scenario.
  Fixation.class_eval {
    field_accessor :_performed, :_performanceTime, :_scene
  }
  
  # Need to be able to set the item history for visual STM.
  stm_item_history_field = Stm.java_class.declared_field("_itemHistory")
  stm_item_history_field.accessible = true
  
  #####################
  ##### MAIN LOOP #####
  #####################
  
  for repeat in 1..2
    for scenario in 1..6
      100.times do
        
        ##################################
        ##### CONSTRUCT CHREST MODEL #####
        ##################################
        
        time_model_created = 0
        model_learning_object_locations_relative_to_self = (repeat == 1 ? false : true)
        model = Chrest.new(time_model_created, model_learning_object_locations_relative_to_self)
        
        ###########################
        ##### CONSTRUCT NODES #####
        ###########################
        
        # Get Visual Modality root Node
        visual_ltm_root_node = model._visualLtm
        
        ##### Construct node_1
        
        # Construct node_1 contents
        node_1_contents = ListPattern.new(Modality::VISUAL)
        node_1_contents._list.add(
          (model_learning_object_locations_relative_to_self ?
            ItemSquarePattern.new("A", -1, -1) :
            ItemSquarePattern.new("A", 3, 3)
          )
        )
        
        # Construct node_1 image
        node_1_image = ListPattern.new(Modality::VISUAL)
        node_1_image._list.add(
          (model_learning_object_locations_relative_to_self ?
            ItemSquarePattern.new("A", -1, -1) :
            ItemSquarePattern.new("A", 3, 3)
          )
        )
        node_1_image._list.add(
          (model_learning_object_locations_relative_to_self ?
            ItemSquarePattern.new("B", 1, 1) :
            ItemSquarePattern.new("B", 5, 5)
          )
        )
        
        # Construct node_1 filled item slots
        node_1_filled_item_slots = ArrayList.new()
        node_1_filled_item_slots.add(
          (model_learning_object_locations_relative_to_self ?
            ItemSquarePattern.new("C", 1, -1) :
            ItemSquarePattern.new("C", 5, 3)
          )
        )
      
        # Construct node_1 filled position slots
        node_1_filled_position_slots = ArrayList.new()
        node_1_filled_position_slots.add(
          (model_learning_object_locations_relative_to_self ?
            ItemSquarePattern.new("D", -1, 1) :
            ItemSquarePattern.new("D", 3, 5)
          )
        )
        
        # Construct node_1 so that its contents, image and item/position slots 
        # can be instantiated.
        time_node_1_created = time_model_created + 5
        node_1 = Node.new(model, node_1_contents, node_1_image, time_node_1_created)
        
        # Fill node_1's item and position slots (doesn't have to actually be a
        # template to do this since the test has access to the relevant private
        # Node instance variables).
        node_1_filled_item_slots_history = HistoryTreeMap.new()
        node_1_filled_item_slots_history.put(time_node_1_created, node_1_filled_item_slots)
        node_1._filledItemSlotsHistory = node_1_filled_item_slots_history
        
        node_1_filled_position_slots_history = HistoryTreeMap.new()
        node_1_filled_position_slots_history.put(time_node_1_created, node_1_filled_position_slots)
        node_1._filledPositionSlotsHistory = node_1_filled_position_slots_history
        
        ##### Construct node_2
           
        # Construct node_2 contents
        node_2_contents = ListPattern.new(Modality::VISUAL)
        node_2_contents._list.add(
          (model_learning_object_locations_relative_to_self ?
            ItemSquarePattern.new("E", -2, 0) :
            ItemSquarePattern.new("E", 2, 4)
          )
        )
        
        # Construct node_2 image
        node_2_image = ListPattern.new(Modality::VISUAL)
        node_2_image._list.add(
          (model_learning_object_locations_relative_to_self ?
            ItemSquarePattern.new("E", -2, 0) :
            ItemSquarePattern.new("E", 2, 4)
          )
        )
        node_2_image._list.add(
          (model_learning_object_locations_relative_to_self ?
            ItemSquarePattern.new("F", 0, 2) :
            ItemSquarePattern.new("F", 4, 6)
          )
        )
        
        # Construct node_2 filled item slots
        node_2_filled_item_slots = ArrayList.new()
        node_2_filled_item_slots.add(
          (model_learning_object_locations_relative_to_self ?
            ItemSquarePattern.new("G", 2, 0) :
            ItemSquarePattern.new("G", 6, 4)
          )
        )
      
        # Construct node_2 filled position slots
        node_2_filled_position_slots = ArrayList.new()
        node_2_filled_position_slots.add(
          (model_learning_object_locations_relative_to_self ?
            ItemSquarePattern.new("H", 0, -2) :
            ItemSquarePattern.new("H", 4, 2)
          )
        )
        
        # Construct node_2 so that its contents, image and item/position slots 
        # can be instantiated.
        time_node_2_created = time_node_1_created
        node_2 = Node.new(model, node_2_contents, node_2_image, time_node_2_created)
        
        # Fill node_2's item and position slots (doesn't have to actually be a
        # template to do this since the test has access to the relevant private
        # Node instance variables).
        node_2_filled_item_slots_history = HistoryTreeMap.new()
        node_2_filled_item_slots_history.put(time_node_2_created, node_2_filled_item_slots)
        node_2._filledItemSlotsHistory = node_2_filled_item_slots_history
        
        node_2_filled_position_slots_history = HistoryTreeMap.new()
        node_2_filled_position_slots_history.put(time_node_2_created, node_2_filled_position_slots)
        node_2._filledPositionSlotsHistory = node_2_filled_position_slots_history
        
        ##############################################
        ##### CONSTRUCT THE VISUAL-SPATIAL FIELD #####
        ##############################################
        
        # Set visual-spatial field dimension parameters
        vsf_width = 5
        vsf_height = 5
        vsf_min_col = 2
        vsf_min_row = 2
        
        # Set creator details
        creator_details = nil
        if model_learning_object_locations_relative_to_self
          creator_details = ArrayList.new()
          creator_details.add("0")
          creator_details.add(Square.new(2, 2))
        end
        
        # Set the time the visual-spatial field is created
        vsf_creation_time = time_node_2_created + 5
        
        # Construct visual-spatial field
        visual_spatial_field = VisualSpatialField.new(
          "", 
          vsf_width, 
          vsf_height, 
          vsf_min_col, 
          vsf_min_row, 
          model, 
          creator_details, 
          vsf_creation_time
        )
        
        # Create an array containing the VisualSpatialField col/row where each
        # VisualSpatialFieldObject is located along with the 
        # VisualSpatialFieldObjects identifier and type.  This will make placing
        # the VisualSpatialFieldObjects much easier
        visual_spatial_field_objects = [
          [[1,1],"1","A"], 
          [[3,3],"2","B"],
          [[3,1],"3","C"],
          [[1,3],"4","D"],
          [[0,2],"5","E"],
          [[2,4],"6","F"],
          [[4,2],"7","G"],
          [[2,0],"8","H"]
        ]
        
        vsfo_creation_time = vsf_creation_time + 5
        
        # Place VisualSpatialFieldObjects
        for visual_spatial_field_object in visual_spatial_field_objects
          col = visual_spatial_field_object[0][0]
          row = visual_spatial_field_object[0][1]
          identifier = visual_spatial_field_object[1]
          type = visual_spatial_field_object[2]
          
          vsfo = VisualSpatialFieldObject.new(
            identifier,
            type,
            model,
            visual_spatial_field, 
            vsfo_creation_time,
            (["C","D"].include?(type) ? true : false), # Only VisualSpatialFieldObjects "C" and "D" should be recognised
            false # Don't bother setting the terminus, yet.
          )
          
          # Add the VisualSpatialFieldObject to the coordinates
          vsf_field.value(visual_spatial_field).get(col).get(row).add(vsfo)
        end
        
        ##############################
        ##### CONSTRUCT FIXATION #####
        ##############################
        
        time_fixation_decided_upon = time_node_2_created + 5
        fixation = CentralFixation.new(time_fixation_decided_upon)
        fixation._performed = (scenario == 1 ? false : true) 
        fixation._performanceTime = time_fixation_decided_upon + 20
        fixation._scene = Scene.new(
          "", 
          vsf_width, 
          vsf_height, 
          vsf_min_col, 
          vsf_min_row, 
          (scenario == 2 ? nil : visual_spatial_field)
        )
        
        ########################################################
        ##### SET TERMINUS OF VISUAL-SPATIAL FIELD OBJECTS #####
        ########################################################
        
        # Now that the Fixation's performance time has been set, the terminus 
        # for VisualSpatialFieldObjects that shouldn't be alive when recognition
        # occurs can be set.  Only VisualSpatialFieldObject with identifier "1"
        # should not be alive.
        vsf_field.value(visual_spatial_field).get(1).get(1).get(0)._terminus = fixation._performanceTime - 1 
        
        ###############################
        ##### SET ATTENTION CLOCK #####
        ###############################
        
        # This will mimic the time taken to recognise information in the 
        # Fixation and update visual STM.  In scenarios 1-3 recognition will not
        # occur but, just go with it.
        model._attentionClock = fixation._performanceTime + 100
        
        ###############################
        ##### POPULATE VISUAL STM #####
        ###############################

        if scenario == 4
          visual_stm_nodes = ArrayList.new()
          visual_stm_nodes.add(visual_ltm_root_node)
          visual_stm_nodes.add(node_1)
          
          # Add visual STM entry after Fixation performed, i.e. at time 
          # attention clock is set to.  At the time the Fixation is performed,
          # visual STM will be empty.
          stm_item_history_field.value(model._visualStm).put(model._attentionClock, visual_stm_nodes) 
          
        elsif scenario == 5
          visual_stm_nodes = ArrayList.new()
          visual_stm_nodes.add(visual_ltm_root_node)
          visual_stm_nodes.add(node_1)
          
          # Add visual STM entry at time Fixation is performed.  At the time of
          # the attention clock, visual STM won't have changed.
          stm_item_history_field.value(model._visualStm).put(fixation._performanceTime, visual_stm_nodes) 
          
        elsif scenario == 6
          visual_stm_nodes = ArrayList.new()
          visual_stm_nodes.add(visual_ltm_root_node)
          visual_stm_nodes.add(node_2)
          
          # Add visual STM entry at time Fixation is performed
          stm_item_history_field.value(model._visualStm).put(fixation._performanceTime, visual_stm_nodes) 
          
          visual_stm_nodes = ArrayList.new()
          visual_stm_nodes.add(visual_ltm_root_node)
          visual_stm_nodes.add(node_2)
          visual_stm_nodes.add(node_1)
          
          # Add visual STM entry after Fixation performed, i.e. at time 
          # attention clock is set to
          stm_item_history_field.value(model._visualStm).put(model._attentionClock, visual_stm_nodes)
        end
        
        #########################
        ##### INVOKE METHOD #####
        #########################
        
        method.invoke(model, fixation)
        
        #################
        ##### TESTS #####
        #################
        
        ##### Check each VisualSpatialFieldObject's status
        expected_visual_spatial_field_data =
        Array.new(vsf_width){
          Array.new(vsf_height) {
            Array.new
          }  
        }

        # Set default values
        expected_visual_spatial_field_data[1][1].push(["1", "A", false, vsfo_creation_time, (fixation._performanceTime - 1)])
        expected_visual_spatial_field_data[3][3].push(["2", "B", false, vsfo_creation_time, nil])
        expected_visual_spatial_field_data[3][1].push(["3", "C", true, vsfo_creation_time, nil])
        expected_visual_spatial_field_data[1][3].push(["4", "D", true, vsfo_creation_time, nil])
        expected_visual_spatial_field_data[0][2].push(["5", "E", false, vsfo_creation_time, nil])
        expected_visual_spatial_field_data[2][4].push(["6", "F", false, vsfo_creation_time, nil])
        expected_visual_spatial_field_data[4][2].push(["7", "G", false, vsfo_creation_time, nil])
        expected_visual_spatial_field_data[2][0].push(["8", "H", false, vsfo_creation_time, nil])
        
        if model_learning_object_locations_relative_to_self
          expected_visual_spatial_field_data[2][2].push(["0", Scene::CREATOR_TOKEN, false, vsf_creation_time, nil])
        end
        
        # Update values (if scenario should)
        if [4,6].include?(scenario)
          expected_visual_spatial_field_data[3][3][0][2] = true
          expected_visual_spatial_field_data[3][3][0][4] = model._attentionClock + model._recognisedVisualSpatialFieldObjectLifespan
          
          expected_visual_spatial_field_data[3][1][0][2] = true
          expected_visual_spatial_field_data[3][1][0][4] = model._attentionClock + model._recognisedVisualSpatialFieldObjectLifespan
          
          expected_visual_spatial_field_data[1][3][0][2] = true
          expected_visual_spatial_field_data[1][3][0][4] = model._attentionClock + model._recognisedVisualSpatialFieldObjectLifespan
        end
        
        # Check VisualSpatialFieldObject status
        check_visual_spatial_field_against_expected(
          visual_spatial_field, 
          expected_visual_spatial_field_data, 
          model._attentionClock, 
          "in scenario " + scenario.to_s + " when the model is " + 
          (repeat == 1 ? "not" : "") + " learning object locations relative to " +
          "itself"
        )
        
        ##### Check for correct key entry in each VisualSpatialFieldObject's 
        ##### recognised history
        
        # In all scenarios except 4 and 6, this array should contain the 
        # locations for all VisualSpatialFieldObjects.  If this is scenario 4 or 
        # 6 and the VisualSpatialFieldObject has an identifier of 2, 3 or 4, 
        # these VisualSpatialFieldObject's recognised status should include the 
        # time node_1 is added to visual STM, i.e. the time the attention clock
        # is set to, as a key (should have been tagged as recognised) and so 
        # shouldn't be present in the array being constructed.
        vsfo_locations_that_shouldnt_be_updated = visual_spatial_field_objects.map {
          | object | 
          ([4,6].include?(scenario) && ["2","3","4"].include?(object[1]) ? 
            nil : 
            object[0]
          )
        }

        # If this is scenario 4 or 6and this is a VisualSpatialFieldObject with
        # an identifier of 2, 3 or 4, this VisualSpatialFieldObject's recognised 
        # status should include the time node_1 is added to visual STM, i.e. the 
        # time the attention clock is set to, as a key (should have been tagged 
        # as recognised) and so should be present in the array being constructed.
        vsfo_locations_that_should_be_updated = visual_spatial_field_objects.map {
          | object |
          ([4,6].include?(scenario) && ["2","3","4"].include?(object[1]) ? 
            object[0] : 
            nil
          )
        }

        for location in vsfo_locations_that_shouldnt_be_updated
          if location != nil
            col = location[0]
            row = location[1]
            vsfo = vsf_field.value(visual_spatial_field).get(col).get(row).get(0)
            vsfo_recognised_history = vsfo_recognised_field.value(vsfo)

            assert_false(
              vsfo_recognised_history.containsKey(model._attentionClock.to_java(:int)),
              "occurred when checking if the recognised history for the " +
              "following VisualSpatialFieldObject does not contain a key for " +
              "the time recognition occurs when the model is " + (repeat == 1 ? 
              "not" : "") + " learning object locations relative to itself " +
              "in scenario " + scenario.to_s + "\n" + vsfo.toString()
            )
          end
        end

        for location in vsfo_locations_that_should_be_updated
          if location != nil
            col = location[0]
            row = location[1]
            vsfo = vsf_field.value(visual_spatial_field).get(col).get(row).get(0)
            vsfo_recognised_history = vsfo_recognised_field.value(vsfo)

            assert_true(
              vsfo_recognised_history.containsKey(model._attentionClock.to_java(:int)),
             "occurred when checking if the recognised history for the " +
              "following VisualSpatialFieldObject does contain a key for " +
              "the time recognition occurs when the model is " + (repeat == 1 ? 
              "not" : "") + " learning object locations relative to itself " +
              "in scenario " + scenario.to_s + "\n" + vsfo.toString()
            )
          end
        end
        
      end
    end
  end
end

################################################################################
# Tests the "Chrest.tagVisualSpatialFieldObjectsFixatedOnAsRecognised()" method
# using various scenarios that should simulate every possible scenario this 
# method will have to handle.
# 
# The VisualSpatialField used in these tests is as follows 
# (VisualSpatialFieldObjects are denoted by their identifier followed by their 
# type in parenthesis):
#
# Visual-Spatial Field Used
# =========================
# 
# NOTE: VisualSpatialFieldObject with identifier "0" is the creator.  This will
#       not be present if the model is not learning object locations relative to
#       itself.
#  
#       |--------|--------|--------|
# 2   4 |  4(D)  |        |  2(B)  |
#       |--------|--------|--------|
# 1   3 |        | 0(CRT) |        |
#       |--------|--------|--------|
# 0   2 |  1(A)  |        |  3(C)  |
#       |--------|--------|--------|
#           2        3        4      DOMAIN-COORDINATES
#           0        1        2      VISUAL-SPATIAL FIELD COORDINATES
# 
# Scenario Details
# ================
# 
# - Scenario 1
#   ~ CHREST model has not completed its current Fixation set.
#
# - Scenario 2
#  ~ CHREST model has completed its current Fixation set.
#  ~ The Fixation input to the method fixated on a Scene that does not represent
#    a VisualSpatialField.
#
# - Scenario 3
#   ~ CHREST model has completed its current Fixation set.
#   ~ The Fixation input to the method fixated on a Scene that does represent a
#     VisualSpatialField.
#   ~ The latest time after considering the input Fixation's performance time 
#     and the CHREST model's attention clock is the input Fixation performance 
#     time, i.e. the input Fixation was not performed.
#   ~ No VisualSpatialFieldObjects have been recognised in the Fixation set.
#
# - Scenario 4
#   ~ CHREST model has completed its current Fixation set.
#   ~ The Fixation input to the method fixated on a Scene that does represent a
#     VisualSpatialField.
#   ~ The latest time after considering the input Fixation's performance time 
#     and the CHREST model's attention clock is the input Fixation performance 
#     time, i.e. the input Fixation was not performed.
#   ~ All VisualSpatialFieldObjects have been recognised in the Fixation set.
#
# - Scenario 5
#   ~ CHREST model has completed its current Fixation set.
#   ~ The Fixation input to the method fixated on a Scene that does represent a
#     VisualSpatialField.
#   ~ The latest time after considering the input Fixation's performance time 
#     and the CHREST model's attention clock is the attention clock, i.e. the
#     input Fixation was performed.
#   ~ No VisualSpatialFieldObjects have been recognised in the Fixation set.
#
# - Scenario 6
#   ~ CHREST model has completed its current Fixation set.
#   ~ The latest time after considering the input Fixation's performance time 
#     and the CHREST model's attention clock is the attention clock, i.e. the
#     input Fixation was performed.
#   ~ Latest time after considering input Fixation performance time and 
#     attention clock is the attention clock
#    All VisualSpatialFieldObjects have been recognised in the Fixation set.
#
# Its important to note the properties that VisualSpatialFieldObjects have in
# order to understand the expected outcomes:
# 
# Visual-Spatial Field Object Details
# ===================================
# 
# At the latest time after considering the input Fixation's performance time and 
# the CHREST model's attention clock, the following properties are set as 
# indicated for each VisualSpatialFieldObject:
# 
# - VisualSpatialFieldObject 1(A) 
#   ~ Alive: false
#   ~ Recognised: false
#   
# - 2(B) 
#   ~ Alive: false
#   ~ Recognised: true
#   
# - 3(C) 
#   ~ Alive: true
#   ~ Recognised: false
#   
# - 4(D) 
#   ~ Alive: true
#   ~ Recognised: true
#
# Expected Outcomes
# =================
# 
# In all scenarios except 3 and 5, no VisualSpatialFieldObject's recognised 
# status should include a key for either the Fixation's performance time or the
# CHREST model's attention clock (depending on which is greater).  
# 
# In scenarios 3 and 5, VisualSpatialFieldObjects with identifiers 3 and 4 
# should include such a key since they are alive at the Fixation's performance 
# time or the CHREST model's attention clock (depending on which is greater) and 
# are not included in the CHREST model's 
# "_recognisedVisualSpatialFieldObjectIdentifiers" data structure. Also, the 
# terminus values for these VisualSpatialFieldObjects should be set to the
# the Fixation's performance time or the CHREST model's attention clock 
# (depending on which is greater) plus the value for the CHREST model's 
# "_unrecognisedVisualSpatialFieldObjectLifespan" parameter.
#
unit_test "tag_unrecognised_visual_spatial_field_objects_after_fixation_set_complete" do
  
  ##########################################################
  ##### SET-UP PRIVATE INSTANCE METHOD/VARIABLE ACCESS #####
  ##########################################################
  
  # The method to test is private so needs to be made accessible in order to 
  # test it.
  method = Chrest.java_class.declared_method(:tagUnrecognisedVisualSpatialFieldObjectsAfterFixationSetComplete, Fixation)
  method.accessible = true
  
  # Need access to the following CHREST model variables for the following 
  # reasons:
  #
  # 1. _attentionClock: needs to be set to a particular value depending on 
  #    scenario and accessible so that variable values to be tested can be 
  #    calculated.
  # 
  # 2. _performingFixations: needs to be set to a particular value depending on 
  #    scenario.
  #
  # 3. _recognisedVisualSpatialFieldObjectIdentifiers: needs to be set to a 
  #    particular value depending on scenario.
  #
  # 4. _unrecognisedVisualSpatialFieldObjectLifespan: needs to be accessible so 
  #    that variable values to be tested can be calculated.
  Chrest.class_eval{
    field_accessor :_attentionClock,
      :_performingFixations,
      :_recognisedVisualSpatialFieldObjectIdentifiers,
      :_unrecognisedVisualSpatialFieldObjectLifespan
  }
  
  # Need to be able to place VisualSpatialFieldObjects precisely on a 
  # VisualSpatialField to access to the *actual* field is required.
  vsf_field = VisualSpatialField.java_class.declared_field("_visualSpatialField")
  vsf_field.accessible = true
  
  # Need to be able to set and check the input Fixation's performance time. 
  Fixation.class_eval{
    field_accessor :_performanceTime
  }
  
  # Need to be able to set the terminus for various VisualSpatialFieldObjects so
  # that they are not alive when the Fixation set is completed.
  VisualSpatialFieldObject.class_eval{
    field_accessor :_terminus
  }
  
  # Need to be able to check the recognised history of VisualSpatialFieldObjects
  vsf_recognised_history_field = VisualSpatialFieldObject.java_class.declared_field("_recognisedHistory")
  vsf_recognised_history_field.accessible = true
  
  #####################
  ##### MAIN LOOP #####
  #####################
  
  for scenario in 1..6
    100.times do
      
      ######################################
      ##### CONSTRUCT THE CHREST MODEL #####
      ######################################
      
      time_model_created = 0
      model_learning_object_locations_relative_to_self = [true, false].sample # Shouldn't affect anything
      model = Chrest.new(time_model_created, model_learning_object_locations_relative_to_self)
      
      model._performingFixations = (scenario == 1 ? true : false)
      
      ##############################################
      ##### CONSTRUCT THE VISUAL-SPATIAL FIELD #####
      ##############################################

      # Set visual-spatial field dimension parameters
      vsf_width = 3
      vsf_height = 3
      vsf_min_col = 2
      vsf_min_row = 2

      # Set creator details
      creator_details = nil
      if model_learning_object_locations_relative_to_self
        creator_details = ArrayList.new()
        creator_details.add("0")
        creator_details.add(Square.new(1, 1))
      end

      # Set the time the visual-spatial field is created
      vsf_creation_time = time_model_created + 5

      # Construct visual-spatial field
      visual_spatial_field = VisualSpatialField.new(
        "", 
        vsf_width, 
        vsf_height, 
        vsf_min_col, 
        vsf_min_row, 
        model, 
        creator_details, 
        vsf_creation_time
      )

      # Create an array containing the VisualSpatialField col/row where each
      # VisualSpatialFieldObject is located along with the 
      # VisualSpatialFieldObjects identifier and type.  This will make placing
      # the VisualSpatialFieldObjects much easier
      visual_spatial_field_objects = [
          [[0,0],"1","A"], 
          [[2,2],"2","B"],
          [[2,0],"3","C"],
          [[0,2],"4","D"]
        ]

      vsfo_creation_time = vsf_creation_time + 5

      # Place VisualSpatialFieldObjects
      for visual_spatial_field_object in visual_spatial_field_objects
        col = visual_spatial_field_object[0][0]
        row = visual_spatial_field_object[0][1]
        identifier = visual_spatial_field_object[1]
        type = visual_spatial_field_object[2]

        vsfo = VisualSpatialFieldObject.new(
          identifier,
          type,
          model,
          visual_spatial_field, 
          vsfo_creation_time,
          (["1","3"].include?(identifier) ? false : true),
          false # Don't bother setting the terminus, yet.
        )

        # Add the VisualSpatialFieldObject to the coordinates
        vsf_field.value(visual_spatial_field).get(col).get(row).add(vsfo)
      end

      ##############################
      ##### CONSTRUCT FIXATION #####
      ##############################
      
      time_fixation_decided_upon = vsfo_creation_time + 10
      fixation = PeripheralSquareFixation.new(model, time_fixation_decided_upon)
      fixation._scene = Scene.new("", vsf_width, vsf_height, vsf_min_col, vsf_min_row, (scenario == 2 ? nil : visual_spatial_field))
      
      ##########################################################################
      ##### SET FIXATION PERFORMANCE TIME AND CHREST MODEL ATTENTION CLOCK #####
      ##########################################################################
      
      fixation._performanceTime = time_fixation_decided_upon + 10
      
      # Set the model's attention clock later than the fixations performance 
      # time if the scenario requires this.  Otherwise, leave it as its default
      # which is currently specified to be -1.
      if [5,6].include?(scenario) 
        model._attentionClock = fixation._performanceTime + 10
      end
      
      ###############################
      ##### SET THE LATEST TIME #####
      ###############################
      
      latest_time = [fixation._performanceTime, model._attentionClock].max
      
      ########################################################
      ##### SET TERMINUS OF VISUAL-SPATIAL FIELD OBJECTS #####
      ########################################################

      # Now that the latest time has been set, the terminus for particular
      # VisualSpatialFieldObjects can be set so that they aren't alive when 
      # processed by the method.
      vsf_field.value(visual_spatial_field).get(0).get(0).get(0)._terminus = latest_time - 1 
      vsf_field.value(visual_spatial_field).get(2).get(2).get(0)._terminus = latest_time - 1
      
      ##################################################################
      ##### SET RECOGNISED VisualSpatialFieldObject DATA STRUCTURE #####
      ##################################################################
      
      if ![3,5].include?(scenario)
        for visual_spatial_field_object in visual_spatial_field_objects
          model._recognisedVisualSpatialFieldObjectIdentifiers.add(visual_spatial_field_object[1])
        end
      end
      
      ###########################
      ##### INVOKE FUNCTION #####
      ###########################
      
      method.invoke(model, fixation)
      
      #################
      ##### TESTS #####
      #################
      
      ##### Check each VisualSpatialFieldObject's status
      expected_visual_spatial_field_data =
        Array.new(vsf_width){
          Array.new(vsf_height) {
            Array.new
          }  
        }

      # Set default values
      expected_visual_spatial_field_data[0][0].push(["1", "A", false, vsfo_creation_time, (latest_time - 1)])
      expected_visual_spatial_field_data[2][2].push(["2", "B", true, vsfo_creation_time, (latest_time - 1)])
      expected_visual_spatial_field_data[2][0].push(["3", "C", false, vsfo_creation_time, nil])
      expected_visual_spatial_field_data[0][2].push(["4", "D", true, vsfo_creation_time, nil])
        
      if model_learning_object_locations_relative_to_self
        expected_visual_spatial_field_data[1][1].push(["0", Scene::CREATOR_TOKEN, false, vsf_creation_time, nil])
      end
        
      # Update values (if scenario should)
      if [3,5].include?(scenario)
        
        # 3(C) already unrecognised so just update its terminus
        expected_visual_spatial_field_data[2][0][0][4] = latest_time + model._unrecognisedVisualSpatialFieldObjectLifespan

        # 4(D) was recognised so its recognised status and terminus should both
        # be updated
        expected_visual_spatial_field_data[0][2][0][2] = false
        expected_visual_spatial_field_data[0][2][0][4] = latest_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      end
        
      # Check VisualSpatialFieldObject status
      check_visual_spatial_field_against_expected(
        visual_spatial_field, 
        expected_visual_spatial_field_data, 
        latest_time, 
        "in scenario " + scenario.to_s + " when the model is " + 
        (model_learning_object_locations_relative_to_self ? "" : "not") + 
        " learning object locations relative to itself"
      )
      
      ##### Check for correct key entry in each VisualSpatialFieldObject's 
      ##### recognised history
      
      # The "latest_time" variable will be used in a "compareTo" method (to see
      # if it does/does not exist as a key in each VisualSpatialFieldObject's
      # recognised status) so needs to be cast explicitly to a primitive Java
      # int otherwise JRuby will complain that "java.lang.ClassCastException: 
      # java.lang.Integer cannot be cast to java.lang.Long".  Since this 
      # variable will be used in loops below, do it here to make the test more
      # efficient.
      latest_time = latest_time.to_java(:int)
      
      # In Scenarios 1, 2, 4, 6, this array should contain the locations for all 
      # VisualSpatialFieldObjects.  If this is scenario 3 or 5 and the 
      # VisualSpatialFieldObject has an identifier of 3 or 4, these 
      # VisualSpatialFieldObject's recognised status should include the 
      # latest_time as a key (should have been tagged as unrecognised) and so 
      # shouldn't be present in the array being constructed.
      vsfo_locations_that_shouldnt_be_updated = visual_spatial_field_objects.map {
        | object | 
        
        ([3,5].include?(scenario) && ["3","4"].include?(object[1]) ? 
          nil : 
          object[0]
        )
      }
      
      vsfo_locations_that_should_be_updated = visual_spatial_field_objects.map {
        | object |
        # If this is scenario 3 or 5 and this is a VisualSpatialFieldObject with
        # an identifier of 3 or 4, this VisualSpatialFieldObject's recognised 
        # status should include the latest_time as a key (should have been 
        # tagged as unrecognised) and so should be present in the array being 
        # constructed.
        ([3,5].include?(scenario) && ["3","4"].include?(object[1]) ? 
          object[0] : 
          nil
        )
      }
      
      for location in vsfo_locations_that_shouldnt_be_updated
        if location != nil
          col = location[0]
          row = location[1]
          vsfo = vsf_field.value(visual_spatial_field).get(col).get(row).get(0)
          vsfo_recognised_history = vsf_recognised_history_field.value(vsfo)

          assert_false(
            vsfo_recognised_history.containsKey(latest_time),
            "occurred when checking if the recognised history for the " +
            "following VisualSpatialFieldObject does not contain a key for " +
            "the latest time in scenario " + scenario.to_s + "\n" + vsfo.toString()
          )
        end
      end
      
      for location in vsfo_locations_that_should_be_updated
        if location != nil
          col = location[0]
          row = location[1]
          vsfo = vsf_field.value(visual_spatial_field).get(col).get(row).get(0)
          vsfo_recognised_history = vsf_recognised_history_field.value(vsfo)

          assert_true(
            vsfo_recognised_history.containsKey(latest_time),
            "occurred when checking if the recognised history for the " +
            "following VisualSpatialFieldObject does contain a key for " +
            "the latest time in scenario " + scenario.to_s + "\n" + vsfo.toString()
          )
        end
      end
      
    end
  end
end

################################################################################
# Tests the "Chrest.scheduleFixationsForPerformance()" using a number of 
# Scenarios that should simulate all scenarios this method will be invoked in.
# The test checks the following:
# 
# 1. Whether an exception is thrown by the method.
# 2. The contents of the method's return value (if an exception is not thrown).
# 3. The value of the CHREST model's Perceiver clock.
# 
# Scenario Details
# ================
# 
# - Scenario 1
#   ~ Input list contains one Fixation whose performance time is already set.
# 
# - Scenario 2
#   ~ Input list contains one Fixation whose performance time is not set.
#   ~ The time the Fixation has been decided upon is in the past relative to 
#     the time the method is invoked.
#   
# - Scenario 3
#   ~ Input list contains one Fixation whose performance time is not set.
#   ~ The time the Fixation has been decided upon is in the future relative to 
#     the time the method is invoked.
# 
# - Scenario 4 
#   ~ Input list contains one Fixation whose performance time is not set.
#   ~ The time the Fixation has been decided upon is equal to the time the 
#     method is invoked.
#   ~ The CHREST model's Perceiver is not free at the time the method is 
#     invoked.
#
# - Scenario 5
#   ~ Input list contains one Fixation whose performance time is not set.
#   ~ The time the Fixation has been decided upon is equal to the time the 
#     method is invoked.
#   ~ The CHREST model's Perceiver is free at the time the method is invoked.
#   
# - Scenario 6
#   ~ Input list contains two Fixations whose performance times are not set.
#   ~ The time the Fixations have been decided upon is equal to the time the 
#     method is invoked.
#   ~ The CHREST model's Perceiver is free at the time the method is invoked.
#
# Expected Output
# ===============
#
# - Scenario 1
#   ~ Exception thrown: false
#     + No Fixation in the List input to the method has a time that it is 
#       decided upon in the past relative to the time the method is invoked and 
#       a performance time value of null.
#   ~ Method return value: same as list input to method.
#     + No Fixation in the List input to the method has a decided upon time that
#       is equal to the time the method is invoked.
#   ~ Perceiver clock: set to default (-1)
#     + No Fixation is scheduled for performance so the Perceiver associated 
#       with the CHREST model is not used.
#   
#     
# - Scenario 2
#   ~ Exception thrown: true
#     + The Fixation in the List input to the method has a time that it is 
#       decided upon in the past relative to the time the method is invoked and 
#       a performance time value of null.
#   ~ Method return value: null.
#     + Since an exception is thrown no return value is generated by the method.
#   ~ Perceiver clock: set to default (-1)
#     + No Fixation is scheduled for performance so the Perceiver associated 
#       with the CHREST model is not used.
#
# - Scenario 3
#   ~ Exception thrown: false
#     + No Fixation in the List input to the method has a time that it is 
#       decided upon in the past relative to the time the method is invoked and 
#       a performance time value of null.
#   ~ Method return value: same as list input to method.
#     + No Fixation in the List input to the method has a decided upon time that
#       is equal to the time the method is invoked.
#   ~ Perceiver clock: set to default (-1)
#     + No Fixation is scheduled for performance so the Perceiver associated 
#       with the CHREST model is not used.
#
# - Scenario 4
#   ~ Exception thrown: false
#     + No Fixation in the List input to the method has a time that it is 
#       decided upon in the past relative to the time the method is invoked and 
#       a performance time value of null.
#   ~ Method return value: empty list.
#     + The Fixation in the List input to the method has a decided upon time 
#       that is equal to the time the method is invoked but the Perceiver 
#       associated with the CHREST model is not free to perform the Fixation so
#       the Fixation will be abandoned.
#   ~ Perceiver clock: set to time it is manually set to in context of this 
#     scenario.
#     + No Fixation is scheduled for performance so the Perceiver associated 
#       with the CHREST model is not used.
#       
# - Scenario 5
#   ~ Exception thrown: false
#     + No Fixation in the List input to the method  has a time that it is 
#       decided upon in the past relative to the time the method is invoked and 
#       a performance time value of null.
#   ~ Method return value: similar to list input to method.
#     + The Fixation in the List input to the method has a decided upon time 
#       that is equal to the time the method is invoked so its performed at time
#       will be set to the time the method is invoked plus the time taken to 
#       make a saccade by the CHREST model.
#   ~ Perceiver clock: set to the time the Fixation is decided upon (time method
#     is invoked) plus the time taken to make a saccade by the CHREST model.
#     + The Fixation input is scheduled for performance so the Perceiver 
#       associated with the CHREST model is used.
#
# - Scenario 6
#   ~ Exception thrown: false
#     + No Fixation in the List input to the method  has a time that it is 
#       decided upon in the past relative to the time the method is invoked and 
#       a performance time value of null.
#   ~ Method return value: similar to list input to method.
#     + The first Fixation in the List input to the method has a decided upon 
#       time that is equal to the time the method is invoked so its performed at 
#       time will be set to the time the method is invoked plus the time taken 
#       to make a saccade by the CHREST model.  Whilst the second Fixation also
#       has a decided upon time that is equal to the time the method is invoked,
#       the Perceiver associated with the CHREST model will be busy performing
#       the first Fixation in the list so the second will be abandoned.
#   ~ Perceiver clock: set to the time the first Fixation is decided upon (time 
#     method is invoked) plus the time taken to make a saccade by the CHREST model.
#     + The first Fixation input is scheduled for performance so the Perceiver 
#       associated with the CHREST model is used.
unit_test "schedule_fixations_for_performance" do
  
  ###################################################
  ##### SET-UP ACCESS TO PRIVATE METHODS/FIELDS #####
  ###################################################
  
  # The method to test is private so needs to be made accessible.
  method = Chrest.java_class.declared_method(:scheduleFixationsForPerformance, List, Java::int)
  method.accessible = true
  
  # Need to be able to set and check the CHREST model's Perceiver clock.  Also
  # need to be able to use the time taken to make a saccade to calculate a
  # Fixation's performance time.
  Chrest.class_eval{
    field_accessor :_perceiverClock, :_saccadeTime
  }
  
  # Need to be able to check the performance time for Fixations and use the time
  # it is decided upon in calculations.
  Fixation.class_eval{
    field_accessor :_performanceTime, :_timeDecidedUpon
  }
  
  #####################
  ##### MAIN LOOP #####
  #####################
  
  for scenario in 1..6
    100.times do
      
      ##################################
      ##### CONSTRUCT CHREST MODEL #####
      ##################################
      
      time_model_created = 0
      
      # When creating the model, set the "learnObjectLocationsRelativeToAgent"
      # construction parameter to true or false randomly. This shouldn't have
      # any effect on the performance of the method being tested.
      model = Chrest.new(time_model_created, [true,false].sample)
      
      ################################
      ##### CONSTRUCT fixation_1 #####
      ################################
      
      time_fixation_1_decided_upon = time_model_created + 10
      fixation_1 = CentralFixation.new(time_fixation_1_decided_upon)
      
      if scenario == 1 then fixation_1._performanceTime = time_fixation_1_decided_upon + 20 end
      
      ################################
      ##### CONSTRUCT fixation_2 #####
      ################################
      
      fixation_2 = nil
      if scenario == 6
        fixation_2 = CentralFixation.new(time_fixation_1_decided_upon)
      end
      
      ############################################################
      ##### ADD FIXATIONS TO PARAMETER TO BE INPUT TO METHOD #####
      ############################################################
      
      fixations_scheduled = ArrayList.new()
      fixations_scheduled.add(fixation_1)
      if fixation_2 != nil then fixations_scheduled.add(fixation_2) end
      
      ###################################
      ##### SET TIME METHOD INVOKED #####
      ###################################
      
      # Do this now since there is a relationship in the test between this value 
      # and the time the fixation is to be decided upon.  Now that the latter 
      # has been set, the former can be set appropriately.
      time_method_invoked = (
        scenario == 2 ? time_fixation_1_decided_upon + 1 :
        scenario == 3 ? time_fixation_1_decided_upon - 1 :
        time_fixation_1_decided_upon
      )
      
      ###################################
      ##### SET THE PERCEIVER CLOCK #####
      ###################################
      
      # Do this now since there is a relationship in the test between this value 
      # and the time the method is invoked.  Now that the latter has been set, 
      # the former can be set appropriately.
      model._perceiverClock = (
        scenario == 4 ? time_method_invoked + 10 :
        [5,6].include?(scenario) ? time_method_invoked :
        model._perceiverClock #Set to default
      )
      
      #########################
      ##### INVOKE METHOD #####
      #########################
      
      exception_thrown = false
      result = nil
      begin
        result = method.invoke(model, fixations_scheduled, time_method_invoked)
      rescue
        exception_thrown = true
      end
      
      #################
      ##### TESTS #####
      #################
      
      # Check if an exception is thrown
      expected_exception_thrown = (scenario == 2 ? true : false)
      assert_equal(
        expected_exception_thrown, 
        exception_thrown, 
        "occurred when checking if an exception is thrown in scenario " + 
        scenario.to_s
      )
      
      # Check the result of the method (if an exception wasn't thrown)
      if result != nil
        result = result.to_java(ArrayList)
        expected_result = ArrayList.new()
        
        if [1,3].include?(scenario)
          expected_result = fixations_scheduled
        elsif [5,6].include?(scenario)
          fixation_1._performanceTime = fixation_1._timeDecidedUpon + model._saccadeTime
          expected_result.add(fixation_1)
        end
        
        # expected_result will be left empty in scenario 4.
        
        assert_equal(
          expected_result.size(),
          result.size(),
          "occurred when checking size of result in scenario " + scenario.to_s
        )
        
        for i in 0...expected_result.size()
          assert_equal(
            expected_result.get(i).toString(),
            result.get(i).toString(),
            "occurred when checking element + " + i.to_s + " in the contents " +
            "of the result in scenario " + scenario.to_s
          )
        end
      end
      
      # Check the CHREST model's Perceiver clock (this is set earlier in the 
      # test too so this needs to be taken into account).
      expected_perceiver_clock = (
        scenario == 4 ? time_method_invoked + 10 :
        [5,6].include?(scenario) ? fixation_1._timeDecidedUpon + model._saccadeTime :
        -1
      )
      assert_equal(
        expected_perceiver_clock,
        model._perceiverClock,
        "occurred when checking the Perceiver clock in scenario " + scenario.to_s
      )
    end
  end
end

################################################################################
# Checks that the scheduleOrMakeNextFixation function works as expected when
# a CHREST model's domain is set to each class that extends 
# jchrest.domainSpecifics.DomainSpecifics.
# 
# For each domain, the test is run until all Fixations that can be generated in
# the domain have been performed and a VisualSpatialField has been constructed.
# Following this, the test will be run a further 500 times using the current 
# domain until moving on to test the next domain and repeating this whole 
# process.  Doing this ensures a wide range of scenarios that the method should
# be able to handle gracefully since there are a number of properties that are
# set randomly during the course of testing this method in context of each 
# domain.
#
# The test first creates a CHREST model and sets its "learning objects relative
# to self parameter" according to the current DomainSpecifics.  If the domain 
# stipulates no exact value for this parameter, its value is randomly assigned. 
# The CHREST model's "isExperienced" property is then set at random too since,
# in some domains, this can impact the Fixations generated.
# 
# A Scene for the relevant domain is then constructed and is used as the Scene
# to fixate on.  SceneObjects present in the Scene are randomly assigned 
# and adhere to any relevant constraints (are blind squares allowed, should the
# creator of the Scene be encoded etc.).
# 
# Visual STM is then populated to enable HypothesisDiscriminationFixations to be
# performed (since these should be generated in each domain).  These Nodes can
# be used since their images/contents are generated by taking into consideration
# the contents of the Scene generated above at random.  For each SceneObject 
# "recognised" in a Node, its identifier is also added to the CHREST model's
# "_recognisedVisualSpatialFieldObjectIdentifiers" data structure so that, if 
# a VisualSpatialField is to be constructed following the completion of a 
# Fixation set, some VisualSpatialFieldObjects should be recognised (this isn't
# actually tested but the data structure should be able to be used without any
# problems).
# 
# A set of Fixations is then performed with a random assignment of the parameter 
# stipulating whether aVisualSpatialField should be created upon completion of 
# the Fixation set being performed (as mentioned in the previous paragraph).  
# Various checks are then performed:
# 
# - The CHREST model should no longer consider itself as performing a Fixation 
#   set.
# - The _recognisedVisualSpatialFieldObjectIdentifiers data structure should be 
#   cleared.
# - The Fixations scheduled data structure should be cleared.
# - The correct number of Fixations are present in the data structure maintained 
#   by the Perceiver associated with the CHREST model.
# - The _fixationsAttemptedInSet variable has been reset to 0.
# - The correct Fixations have been generated in the correct order.
# - VisualSpatialField construction occurred/did not occur as expected.
#
# The method is then invoked until a new Fixation set is started and the 
# following checks are then performed:
#
# - The CHREST model now considers itself as performing a new Fixation set.
# - The correct initial Fixation according to the domain has been scheduled.
# - The Fixation data structure of the Perceiver associated with the CHREST 
#   model has been cleared.
# - The Fixation to learn from according to the Perceiver has been reset to 0.
#
# The method is then invoked until this second Fixation set has been performed.
# Therefore, the test checks that subsequent Fixation sets can be performed and
# are performed as expected.
canonical_result_test "make_fixations_in_domains" do
  
  #######################################################
  ##### SET-UP ACCESS TO PRIVATE INSTANCE VARIABLES #####
  #######################################################
  
  # With regard to the CHREST model used:
  # 
  # 1. Need to set the domain specifics of the model to ChessDomain.
  # 2. Need to set modify visual STM to ensure a 
  #    HypothesisDiscriminationFixation can be performed.
  # 3. Need to check the Fixations scheduled by the model.
  # 4. Need to check if the data structure containing VisualSpatialFieldObjects
  #    recognised during performance of the Fixation data set is cleared upon
  #    Fixation set completion.
  # 5. Need to set the fixation field of view for the Perceiver associated with
  #    the CHREST model so that PeripheralItemFixations and 
  #    PeripheralSquareFixations are guaranteed to be made.
  # 6. Need to check the model's database of VisualSpatialFields since, if one
  #    is to be constructed, the test needs to check if it is created at the 
  #    time the Fixation set performed completes.
  Chrest.class_eval{
    field_accessor :_domainSpecifics, 
      :_visualStm, 
      :_performingFixations,
      :_fixationsScheduled, 
      :_recognisedVisualSpatialFieldObjectIdentifiers,
      :_fixationsAttemptedInCurrentSet
  }
  chrest_perceiver_field = Chrest.java_class.declared_field("_perceiver")
  chrest_perceiver_field.accessible = true
  
  chrest_vsf_field = Chrest.java_class.declared_field("_visualSpatialFields")
  chrest_vsf_field.accessible = true
  
  # Need to set the fixation field of view for reasons described above.
  Perceiver.class_eval{
    field_accessor :_fixationFieldOfView
  }
  
  # Need to be able to check if the Perceiver's Fixation data structure is 
  # cleared when an initial Fixation is generated.
  perceiver_fixations_field = Perceiver.java_class.declared_field("_fixations")
  perceiver_fixations_field.accessible = true
  
  # Need to access the dimensions of the chess board constructed to enable 
  # randomness in STM Node images to enable/disable 
  # HypothesisDiscriminationFixation performance.
  scene_height_field = Scene.java_class.declared_field("_height")
  scene_height_field.accessible = true
  scene_width_field = Scene.java_class.declared_field("_width")
  scene_width_field.accessible = true
  
  # With regard to the Scene used:
  # 
  # 1. Need to get SceneObjects from a randomly selected Square in the Scene
  #    during STM Node construction.
  # 2. Need to access the dimensions of the Scene constructed to enable 
  #    randomness in STM Node images to enable/disable 
  #    HypothesisDiscriminationFixation performance.
  Scene.class_eval{
    field_accessor :_scene
  }
  
  scene_object_type_field = SceneObject.java_class.declared_field("_objectType")
  scene_object_type_field.accessible = true
  
  scene_object_identifier_field = SceneObject.java_class.declared_field("_identifier")
  scene_object_identifier_field.accessible = true
  
  # Need access to what Fixations are performed to control test progress.
  Fixation.class_eval{
    field_accessor :_performed
  }
  
  # Need access to ListPattern elements to construct contents and images for STM
  # Nodes to enable/disable HypothesisDiscriminationFixation performance.
  ListPattern.class_eval{
    field_accessor :_list
  }
  
  # Need access to STM Node's child history to enable/disable 
  # HypothesisDiscriminationFixation performance.
  Node.class_eval{
    field_accessor :_childHistory
  }
  
  # Need access to visual STM items to enable/disable 
  # HypothesisDiscriminationFixation performance.
  stm_item_history_field = Stm.java_class.declared_field("_itemHistory")
  stm_item_history_field.accessible = true
  
  #####################
  ##### MAIN LOOP #####
  #####################
  
  for test_domain in [GenericDomain, ChessDomain, TileworldDomain]
    test_domain = test_domain.java_class
    
    # For each domain, add the types of Fixation expected to be encountered 
    # during Fixation set performance to an array along with a boolean flag 
    # indicating whether that type of Fixation has been performed.
    fixations_expected = (
      case test_domain
      when GenericDomain.java_class
        [
          [AheadOfAgentFixation.java_class, false],
          [CentralFixation.java_class, false],
          [HypothesisDiscriminationFixation.java_class, false],
          [PeripheralItemFixation.java_class, false],
          [PeripheralSquareFixation.java_class, false]
        ]
      when ChessDomain.java_class
        [  
          [CentralFixation.java_class, false],
          [HypothesisDiscriminationFixation.java_class, false],
          [SalientManFixation.java_class, false],
          [GlobalStrategyFixation.java_class, false],
          [PeripheralItemFixation.java_class, false],
          [PeripheralSquareFixation.java_class, false]
        ]
      when TileworldDomain.java_class
        [
          [AheadOfAgentFixation.java_class, false],
          [HypothesisDiscriminationFixation.java_class, false],
          [SalientObjectFixation.java_class, false],
          [MovementFixation.java_class, false],
          [PeripheralItemFixation.java_class, false],
          [PeripheralSquareFixation.java_class, false]
        ]
      end
    )
    
    # VisualSpatialField construction is randomised on a per-iteration basis 
    # but still needs to be checked.  Ideally, there should be a test that 
    # checks:
    # 
    # a) That a VisualSpatialField was constructed if specified
    # b) That the VisualSpatialField was constructed at the correct time
    # 
    # Checking a) is simple: the test simply checks the following statement: 
    # "if a VisualSpatialField was specified to be constructed AND at least one 
    # Fixation in the set was performed successfully, a VisualSpatialField 
    # should be present in the model's database of VisualSpatialFields".
    # 
    # However, checking b) is very problematic since its not possible to
    # determine when attention was free after completion of the Fixation set 
    # (did the last Fixation performed consume attention or was a previous 
    # Fixation consuming attention when the last Fixation was performed causing 
    # the last Fixation performed to not consume attention).  Consequently, such
    # a test is not performed.
    # 
    # Like checking for Fixation performance though, the test should check that 
    # a VisualSpatialField is constructed at some point.  To do this, the 
    # following variable will be set to true when an iteration of the test 
    # causes a VisualSpatialField to be constructed and only when this variable
    # is set to true and all Fixations have been performed will the test 
    # iteration counter increment.
    visual_spatial_field_created = false
    
    #####################
    ##### MAIN LOOP #####
    #####################
    
    counter = -1
    counter_limit = 500
    until counter > counter_limit do
      
      # Since this test can take a *long* time to complete, display the progress
      # to the user by printing the domain being tested, the current counter
      # number and the counter limit.  This should present a user from quitting 
      # the tests because they think a while loop is running infinitely (which
      # may occur and there are a few of them in this test).
      if counter == -1
        print "\n"
        counter = 0
      end
      print "    - Testing " + test_domain.to_s + ": " + counter.to_s + "/" + counter_limit.to_s + "\r"
      
      ###########################
      ##### CONSTRUCT MODEL #####
      ###########################
      
      time = 0
      
      learn_object_locations_relative_to_self = (
        case test_domain
        when GenericDomain.java_class
          [true,false].sample
        when ChessDomain.java_class
          false
        when TileworldDomain.java_class
          true
        end
       )

      # Fixation generation can differ depending on the domain and whether the 
      # CHREST model making the Fixation is "experienced" or not.  Therefore, 
      # being able to specify if a CHREST model is experienced "on-the-fly", is 
      # desirable. Otherwise, the model would have to have learn a certain 
      # number of Nodes, n, to become experienced.  Thus, if n is changed this 
      # test will break and, in addition, performing this learning in this test 
      # adds extra complexity to an already complex test!
      #
      # To circumvent this, subclass the "Chrest" java class with a jRuby class 
      # that will be used in place of the "Chrest" java class in this test. In
      # the subclass, override "Chrest.isExperienced()" (the method used to 
      # determine the "experienced" status of a CHREST model) and have it return 
      # a class variable (for the subclass) that can be set at will.
      model = Class.new(Chrest) {
        @@experienced = false

        def isExperienced(x)
          return @@experienced
        end

        def setExperienced(bool)
          @@experienced = bool
        end
      }.new(time, learn_object_locations_relative_to_self)

      model_is_experienced = [true, false].sample
      model.setExperienced(model_is_experienced)
      chrest_perceiver_field.value(model)._fixationFieldOfView = 2
      
      # Now that relevant CHREST model parameters have been set, some Fixations
      # may not be expected so they should be removed from the 
      # "fixations_expected" data structure otherwise, this test will run 
      # forever (see below).
      fixation_not_expected_index = fixations_expected.index(fixations_expected.detect{
        | fixation_type_and_performance_flag |
        fixation_type_and_performance_flag.include?(
          case test_domain
          when GenericDomain.java_class
            (learn_object_locations_relative_to_self ? CentralFixation.java_class : AheadOfAgentFixation.java_class)
          when ChessDomain.java_class
            (model_is_experienced ? PeripheralItemFixation.java_class : GlobalStrategyFixation.java_class)
          end
        )
      })
      if fixation_not_expected_index != nil then fixations_expected.delete_at(fixation_not_expected_index) end

      #############################################
      ##### CONSTRUCT DOMAIN AND SET TO MODEL #####
      #############################################
      
      # Set domain parameters
      max_fixations_in_set = 10
      initial_fixation_threshold = 4
      peripheral_item_fixation_max_attempts = 3
      
      # Construct domain and set to model
      model._domainSpecifics = (
        case test_domain
        when GenericDomain.java_class
          GenericDomain.new(model, max_fixations_in_set, peripheral_item_fixation_max_attempts)
        when ChessDomain.java_class
          ChessDomain.new(model, initial_fixation_threshold, peripheral_item_fixation_max_attempts, max_fixations_in_set)
        when TileworldDomain.java_class
          TileworldDomain.new(model, max_fixations_in_set, initial_fixation_threshold, peripheral_item_fixation_max_attempts)
        end
      )

      ########################################
      ##### CONSTRUCT SCENE TO FIXATE ON #####
      ########################################
      
      scene_to_fixate_on = (
        case test_domain
        when GenericDomain.java_class
          scene = Scene.new("GenericDomain Scene", 5, 5, 2, 2, nil)
          
          22.times do
            col = rand(0...scene_width_field.value(scene))
            row = rand(0...scene_width_field.value(scene))
            while (
              scene_object_type_field.value(scene._scene.get(col).get(row)) != Scene::BLIND_SQUARE_TOKEN &&
              scene_object_type_field.value(scene._scene.get(col).get(row)) != Scene::CREATOR_TOKEN
            )
              col = rand(0...scene_width_field.value(scene))
              row = rand(0...scene_width_field.value(scene))
            end
            
            object_type_to_place = (rand(0..1) == 0 ? ("a".."z").to_a.sample : Scene::EMPTY_SQUARE_TOKEN)
            scene._scene.get(col).set(row, SceneObject.new(object_type_to_place))
          end
          
          if learn_object_locations_relative_to_self then scene._scene.get(2).set(2, SceneObject.new(Scene::CREATOR_TOKEN)) end
          
          scene
          
        when ChessDomain.java_class 
          scene = ChessBoard.new("ChessBoard")
          for col in 0...8
            for row in 0...8
              scene._scene.get(col).set(row, ChessObject.new(Scene::EMPTY_SQUARE_TOKEN))
            end
          end

          pieces = ["r","n","b","q","k","R","N","B","Q","K"]
          8.times do pieces.push("p") end
          8.times do pieces.push("P") end
          for piece in pieces
            col = rand(0...8)
            row = rand(0...8)
            while scene_object_type_field.value(scene._scene.get(col).get(row)) != Scene::EMPTY_SQUARE_TOKEN
              col = rand(0...8)
              row = rand(0...8)
            end
            scene._scene.get(col).set(row, ChessObject.new(piece))
          end
          
          scene
        
        when TileworldDomain.java_class
          scene = Scene.new("TileworldDomain Scene", 5, 5, 0, 0, nil)

          # Place physical objects.
          scene._scene.get(2).set(2, SceneObject.new("0", Scene::CREATOR_TOKEN))
          scene._scene.get(2).set(3, SceneObject.new("1", TileworldDomain::TILE_SCENE_OBJECT_TYPE_TOKEN))
          scene._scene.get(3).set(2, SceneObject.new("2", TileworldDomain::HOLE_SCENE_OBJECT_TYPE_TOKEN))
          scene._scene.get(0).set(4, SceneObject.new("3", TileworldDomain::OPPONENT_SCENE_OBJECT_TYPE_TOKEN ))
          scene._scene.get(1).set(0, SceneObject.new("4", TileworldDomain::TILE_SCENE_OBJECT_TYPE_TOKEN))
          scene._scene.get(4).set(0, SceneObject.new("5", TileworldDomain::HOLE_SCENE_OBJECT_TYPE_TOKEN))
          scene._scene.get(1).set(2, SceneObject.new("6", TileworldDomain::HOLE_SCENE_OBJECT_TYPE_TOKEN))
          scene._scene.get(4).set(4, SceneObject.new("7", TileworldDomain::OPPONENT_SCENE_OBJECT_TYPE_TOKEN ))
          scene._scene.get(1).set(1, SceneObject.new("8", TileworldDomain::OPPONENT_SCENE_OBJECT_TYPE_TOKEN ))

          # Fill in empty squares.
          for col in 0...scene_width_field.value(scene)
            for row in 0...scene_height_field.value(scene)
              if col != 2 && (row != 1 || row != 2)

                object_type = scene_object_type_field.value(scene._scene.get(col).get(row))
                if object_type == Scene::BLIND_SQUARE_TOKEN
                  scene._scene.get(col).set(row, SceneObject.new(Scene::EMPTY_SQUARE_TOKEN))
                end
              end
            end
          end
          
          scene
        end
      )

      ##########################################################################
      #####  POPULATE VISUAL STM AND RECOGNISED VisualSpatialFieldObject   ##### 
      #####                         DATA STRUCTURE                         #####
      ##########################################################################
    
      # Populate visual STM so that HypothesisDiscriminationFixations can be 
      # performed correctly (sometimes).  Essentially, there should be a STM 
      # Node whose content/image contains ItemSquarePatterns that will be 
      # present in ListPatterns generated after making a Fixation on the Scene 
      # and normalising said ListPattern.  This STM Node should then have a 
      # child whose content/image also contains ItemSquarePatterns that will be
      # present in ListPatterns generated after making a Fixation on the Scene 
      # and normalising said ListPattern. Therefore, 2 Nodes will be constructed 
      # and added to STM, the Node in STM (depth 1 Node) and the Node that is a 
      # child of the Node in STM (depth 2 Node).
      # 
      # The test should introduce some variablity in behaviour since the 
      # handling of Fixations that are not performed successfully needs to be 
      # checked. Therefore, get the location of 1 randomly selected SceneObject 
      # that does not represent a blind square/empty square/or the creator since 
      # the location of such SceneObjects shouldn't be learned.  When such a 
      # SceneObject is returned, get its identifier and add it to the recognised
      # VisualSpatialFieldObject data structure too, for continuity.
      
      # Construct an array containing the types of objects that can't be learned
      # and thus, should not appear in the contents/image of the Nodes 
      # constructed here.
      types_of_object_that_cant_be_learned = (
        case test_domain
        when GenericDomain.java_class, ChessDomain.java_class, TileworldDomain.java_class
          [
            Scene::EMPTY_SQUARE_TOKEN, 
            Scene::BLIND_SQUARE_TOKEN, 
            Scene::CREATOR_TOKEN
          ]
        end
      )

      ##### CONSTRUCT DEPTH 2 NODE
      depth_2_node_contents_image = nil

      col = rand(0...scene_width_field.value(scene_to_fixate_on))
      row = rand(0...scene_height_field.value(scene_to_fixate_on))
      item = scene_object_type_field.value(scene_to_fixate_on._scene.get(col).get(row))
      identifier = scene_object_identifier_field.value(scene_to_fixate_on._scene.get(col).get(row))

      while types_of_object_that_cant_be_learned.include?(item)
        col = rand(0...scene_width_field.value(scene_to_fixate_on))
        row = rand(0...scene_height_field.value(scene_to_fixate_on))
        item = scene_object_type_field.value(scene_to_fixate_on._scene.get(col).get(row))
        identifier = scene_object_identifier_field.value(scene_to_fixate_on._scene.get(col).get(row))
      end
      
      depth_2_node_contents_image = ItemSquarePattern.new(item, col, row)

      depth_2_node_contents = ListPattern.new(Modality::VISUAL)
      depth_2_node_contents._list.add(depth_2_node_contents_image)
      depth_2_node_image = depth_2_node_contents
      depth_2_node = Node.new(model, depth_2_node_contents, depth_2_node_image, time)
      depth_2_link = Link.new(depth_2_node_contents, depth_2_node, time, "")
      
      # Add identifier to Chrest._recognisedVisualSpatialFieldObjectIdentifiers
      model._recognisedVisualSpatialFieldObjectIdentifiers.add(identifier)

      ##### CONSTRUCT DEPTH 1 NODE ##### 
      depth_1_node_contents_image = nil

      col = rand(0...scene_width_field.value(scene_to_fixate_on))
      row = rand(0...scene_height_field.value(scene_to_fixate_on))
      item = scene_object_type_field.value(scene_to_fixate_on._scene.get(col).get(row))
      identifier = scene_object_identifier_field.value(scene_to_fixate_on._scene.get(col).get(row))
      
      while types_of_object_that_cant_be_learned.include?(item)
        col = rand(0...scene_width_field.value(scene_to_fixate_on))
        row = rand(0...scene_height_field.value(scene_to_fixate_on))
        item = scene_object_type_field.value(scene_to_fixate_on._scene.get(col).get(row))
        identifier = scene_object_identifier_field.value(scene_to_fixate_on._scene.get(col).get(row))
      end

      depth_1_node_contents_image = ItemSquarePattern.new(item, col, row)
      
      depth_1_node_contents = ListPattern.new(Modality::VISUAL)
      depth_1_node_contents._list.add(depth_1_node_contents_image)
      depth_1_node_image = depth_1_node_contents
      depth_1_node = Node.new(model, depth_1_node_contents, depth_1_node_image, time)

      depth_1_node_children = ArrayList.new()
      depth_1_node_children.add(depth_2_link)

      time += 1
      depth_1_node._childHistory.put(time, depth_1_node_children)
      
      # Add identifier to Chrest._recognisedVisualSpatialFieldObjectIdentifiers
      model._recognisedVisualSpatialFieldObjectIdentifiers.add(identifier)

      ##### ADD DEPTH 1 NODE TO STM #####
      time += 1
      stm_items = ArrayList.new()
      stm_items.add(depth_1_node)
      stm_item_history_field.value(model._visualStm).put(time, stm_items)

      ##########################
      ##### MAKE FIXATIONS #####
      ##########################
    
      # Randomly stipulate whether a VisualSpatialField should be constructed or
      # not when the number of Fixations attempted equals the maximum permitted.
      construct_visual_spatial_field = [true,false].sample
      until !model.scheduleOrMakeNextFixation(scene_to_fixate_on, construct_visual_spatial_field, time)
        time += 1
      end
      
      #################
      ##### TESTS #####
      #################
      
      err_msg_append = " in the " + test_domain.to_s + " domain"
      
      # Check that the model isn't performing Fixations now.
      assert_false(
        model._performingFixations, 
        "occurred when checking if the model is performing Fixations when " +
        "it has completed a Fixation set" + err_msg_append
      )
      
      # Check that the _recognisedVisualSpatialFieldObjectIdentifiers data 
      # structure has been cleared.
      assert_true(
        model._recognisedVisualSpatialFieldObjectIdentifiers.isEmpty(),
        "occurred when checking if the data structure containing recognised " +
        "VisualSpatialFieldObject identifiers is cleared when a Fixation set " +
        "is complete" + err_msg_append
      )
      
      # Check that the Fixations scheduled data structure has been cleared.
      assert_true(
        model._fixationsScheduled.get(time.to_java(:int)).isEmpty(),
        "occurred when checking if the data structure containing Fixations " +
        "scheduled for execution is cleared when a Fixation set is complete" +
        err_msg_append
      )

      # Ensure the correct number of Fixations have been attempted before 
      # continuing.
      fixations_attempted = perceiver_fixations_field.value(chrest_perceiver_field.value(model)).get(time.to_java(:int))
      assert_equal(
        max_fixations_in_set,
        fixations_attempted.size(),
        "occurred when checking the number of fixations attempted" + err_msg_append
      )
      
      # Check that the _fixationsAttemptedInSet variable has been reset to 0
      assert_equal(
        0,
        model._fixationsAttemptedInCurrentSet,
        "occurred when checking the number of fixations attempted in the " +
        "current set when a Fixation set is complete" + err_msg_append
      )

      # Check each Fixation type attempted according to its order of attempt.
      for f in 0...fixations_attempted.size()
        fixation = fixations_attempted.get(f)
        
        #########################################
        ##### SET EXPECTED FIXATION CLASSES #####
        #########################################
        
        expected_fixation_classes = []
        
        case test_domain
        when GenericDomain.java_class
          if f == 0
            expected_fixation_classes.push(learn_object_locations_relative_to_self ? AheadOfAgentFixation : CentralFixation)
          elsif f == 1
            expected_fixation_classes.push(HypothesisDiscriminationFixation)
          else
            expected_fixation_classes.push(HypothesisDiscriminationFixation)
            expected_fixation_classes.push(PeripheralSquareFixation)
            expected_fixation_classes.push(PeripheralItemFixation)
          end
        when ChessDomain.java_class
          if f == 0 
            expected_fixation_classes.push(CentralFixation)
          elsif f.between?(1,3)
            expected_fixation_classes.push(SalientManFixation)
          elsif f == 4
            expected_fixation_classes.push(HypothesisDiscriminationFixation)
          else
            expected_fixation_classes.push(HypothesisDiscriminationFixation)
            expected_fixation_classes.push(model_is_experienced ? GlobalStrategyFixation : PeripheralItemFixation)
            expected_fixation_classes.push(PeripheralSquareFixation)
            expected_fixation_classes.push(AttackDefenseFixation)
          end
        when TileworldDomain.java_class
          if f == 0
            expected_fixation_classes.push(AheadOfAgentFixation)
          elsif f < initial_fixation_threshold
            expected_fixation_classes.push(SalientObjectFixation)
          elsif f == initial_fixation_threshold
            expected_fixation_classes.push(HypothesisDiscriminationFixation)
          else
            expected_fixation_classes.push(HypothesisDiscriminationFixation)
            expected_fixation_classes.push(SalientObjectFixation)
            expected_fixation_classes.push(MovementFixation)
            expected_fixation_classes.push(PeripheralItemFixation)
            expected_fixation_classes.push(PeripheralSquareFixation)
          end
        end

        expected_fixation_classes.map!{|x| x.java_class.to_s}
        assert_true(
          expected_fixation_classes.include?(fixation.java_class.to_s), 
          "occurred" + err_msg_append + " when checking if fixation " + f.to_s + 
          " was of any of the following types: " + expected_fixation_classes.to_s + 
          "\nFixation details:\n" + fixation.toString()
        )

        # If the Fixation attempted was performed successfully, set the relevant
        # boolean flag in the test loop control data structure
        fixations_expected.each{|fixation_type| 
          if fixation_type[0] == fixation.java_class && fixation._performed 
            fixation_type[1] = true
          end
        }
      end
      
      # Check VisualSpatialField construction.
      if construct_visual_spatial_field
        if perceiver_fixations_field.value(chrest_perceiver_field.value(model)).lastEntry().getValue().to_a.any?{|fixation| fixation._performed} 
          assert_true(
            chrest_vsf_field.value(model).lastEntry().getValue() != nil,
            "occurred when checking if a VisualSpatialField has been " + 
            "constructed when it should have been after the first Fixation " +
            "set has completed" + err_msg_append
          )
        end
      else
        assert_true(
          chrest_vsf_field.value(model).lastEntry().getValue() == nil,
          "occurred when checking if a VisualSpatialField has not been " + 
          "constructed when it shouldn't have been after the first Fixation " +
          "set has completed" + err_msg_append
        )
      end
    
      ##############################################
      ##### MODIFY TEST LOOP CONTROL VARIABLES #####
      ##############################################

      # Check for all Fixations being performed
      all_fixations_performed = true
      fixations_expected.each{|fixation_type| 
        if !fixation_type[1]
          all_fixations_performed = false
        end
      }
      
      # Check for VisualSpatialFieldConstruction
      if chrest_vsf_field.value(model).lastEntry().getValue() != nil then visual_spatial_field_created = true end
      
      # Increment the test iteration counter accordingly.
      if all_fixations_performed && visual_spatial_field_created then counter += 1 end
      
      ############################################################
      ##### CHECK THAT THE METHOD WILL LOOP AFTER COMPLETION #####
      ############################################################
      
      # Invoke the method until it returns true, i.e. it has started a new 
      # Fixation set.
      time += 1
      until model.scheduleOrMakeNextFixation(scene_to_fixate_on, false, time)
        time += 1
      end
      
      # Check that the model now considers itself as performing a new Fixtaion
      # set
      assert_true(
        model._performingFixations, 
        "occurred when checking if the model is performing Fixations when " +
        "it should have started a new Fixation set" + err_msg_append
      )
      
      # Check that the correct initial Fixation has been scheduled.
      assert_equal(
        1,
        model._fixationsScheduled.get(time.to_java(:int)).size(),
        "occurred when checking the size of the CHREST model's scheduled " +
        "Fixations data structure after starting a new Fixation set" + err_msg_append
      )
      
      expected_initial_fixation = (
        case test_domain
        when GenericDomain.java_class
          learn_object_locations_relative_to_self ? AheadOfAgentFixation : CentralFixation
        when ChessDomain.java_class
          CentralFixation
        when TileworldDomain.java_class
          AheadOfAgentFixation
        end
      ).java_class
      
      assert_equal(
        expected_initial_fixation,
        model._fixationsScheduled.get(time.to_java(:int)).get(0).java_class,
        "occurred when checking the type of the initial Fixation in the CHREST " + 
        "model's scheduled Fixations data structure after starting a new Fixation set" +
        err_msg_append
      )
      
      # Check that Perceiver's Fixations data structure has been cleared.
      assert_true(
        perceiver_fixations_field.value(chrest_perceiver_field.value(model)).get(time.to_java(:int)).isEmpty(),
        "occurred when checking if the Perceiver's Fixation data structure is " +
        "cleared after starting a new Fixation set" + err_msg_append
      )
      
      # Check that the fixation to learn from according to the Perceiver has 
      # been reset to 0.
      assert_equal(
        chrest_perceiver_field.value(model)._fixationToLearnFrom,
        0,
        "occurred when checking if the Perceiver's Fixation to learn from is " + 
        "reset to 0 after starting a new Fixation set" + err_msg_append
      )
      
      ########################################
      ##### PERFORM ANOTHER FIXATION SET #####
      ########################################
      
      until !model.scheduleOrMakeNextFixation(scene_to_fixate_on, false, time)
        time += 1
      end
    end
  end
  
  # Done to make terminal output pretty (will print result of test on a new 
  # line after the counter display for the domain)
  puts "\n"
end

################################################################################
# The following test checks that visual-spatial field construction operates as
# expected using a complex set-up that should test every facet of the 
# "constructVisualSpatialField()" method.  As well as checking this function, 
# the test also checks that the
# "encodeVisualSpatialFieldObjectDuringVisualSpatialFieldConstruction()" and 
# "refreshVisualSpatialFieldObjectTermini()" methods also work correctly since
# "constructVisualSpatialField()" uses these methods.
# 
# An agent equipped with CHREST makes a number of Fixations in different areas 
# of a domain whose SceneObjects change over time.  In scenario 1, the agent 
# does not learn SceneObject locations relative to itself whereas, in scenario 
# 2, it does. This enables the test to check if domain-specific and 
# agent-relative coordinates are handled correctly by the function.
# 
# Seven distinct Scenes representing different domain areas at different periods 
# of time are used in this test, these Scenes are called "south-west", 
# "north-west", "north-east", "south-east", "old-south-west", "old-north-west", 
# and "old-north-east" and are depicted graphically below.
# 
# ==============
# Scene Notation
# ==============
# 
# - Boundaries of Squares in Scenes are denoted by "|" and "-" characters.
# - Empty squares contain no character in their centre.
# - Squares containing the agent equipped with CHREST are denoted by "SELF".
# - Squares that are blind to the agent equipped with CHREST are denoted by "*".
# - Squares that are occupied by SceneObjects other than the agent equipped with 
#   CHREST are denoted by the SceneObject's type ("P", for example).
# - The domain-specific coordinates represented by the Scene are given along the
#   inner x and y axis ("DS" is used for clarification).
# - The Scene-specific coordinates are given along the outer x and y axis ("SS" 
#   is used for clarification).
#   
# - NOTE: if the agent is not learning SceneObject locations relative to itself,
#         the SceneObject representing the agent will be replaced by a blind 
#         spot in the Scene.
# 
# === "old-south-west" ===
# 
# SS   DS                 
#         |----|----|----|
# 2    4  | P  | Y  | SS |
#         |----|----|----|
# 1    3  |    |SELF| H  |
#         |----|----|----|
# 0    2  | I  | *  |    |
#         |----|----|----|
#           3    4    5   
#           0    1    2   
#          
# === "old-north-west" ===
# 
# SS   DS
#         |----|----|----|
# 2    8  | J  | *  |    |
#         |----|----|----|
# 1    7  |    |SELF| TT |
#         |----|----|----|
# 0    6  | M  |    | B  |
#         |----|----|----|
#           3    4    5
#           0    1    2
#           
# === "old-north-east" ===
# 
# SS   DS                 
#         |----|----|----|
# 2    8  |    | *  | K  |
#         |----|----|----|
# 1    7  | F  |SELF|    |
#         |----|----|----|
# 0    6  | C  | UU | N  |
#         |----|----|----|
#           7    8    9   
#           0    1    2   
# 
# === "south-west" ===
# 
# SS   DS                 
#         |----|----|----|
# 2    4  | P  | Y  | A  |
#         |----|----|----|
# 1    3  |    |SELF| H  |
#         |----|----|----|
# 0    2  | I  | *  |    |
#         |----|----|----|
#           3    4    5   
#           0    1    2   
# 
# === "north-west" ===
# 
# SS   DS
#         |----|----|----|
# 2    8  | J  | *  |    |
#         |----|----|----|
# 1    7  |    |SELF| E  |
#         |----|----|----|
# 0    6  | M  |    | B  |
#         |----|----|----|
#           3    4    5
#           0    1    2
# 
# === "north-east" ===
# 
# SS   DS                 
#         |----|----|----|
# 2    8  |    | *  | K  |
#         |----|----|----|
# 1    7  | F  |SELF|    |
#         |----|----|----|
# 0    6  | C  | Z  | N  |
#         |----|----|----|
#           7    8    9   
#           0    1    2   
# 
# === "south-east" ===
# 
# SS   DS
#         |----|----|----|
# 2    4  | D  |    |    |
#         |----|----|----|
# 1    3  | G  |SELF| O  |
#         |----|----|----|
# 0    2  |    | *  | L  |
#         |----|----|----|
#           7    8    9
#           0    1    2
#
# 
# Note that: 
# 
# - The only difference between "old-south-west", "old-north-west" and 
#   "old-north-east" are that the SceneObjects with type "SS", "TT" and "UU" are
#   present instead of "A", "E" and "Z" respectively.  This is important in 
#   enabling this test to check VisualSpatialFieldObject terminus refreshment.
#   
# - The domain coordinates these Scenes represent are not continuous, i.e. the 
#   maximum row of "south-west" and minimum row of "north-west" are not
#   consecutive integers (the same is true for the maximum and minimum columns 
#   of "south-west" and "south-east", respectively).  This means that the test
#   can check if the VisualSpatialField constructed will be "stiched-together" 
#   correctly from these Scenes.
#   
# The CHREST model used in this test has its fixation field of view parameter 
# set to 1 and its domain is set to jchrest.domainSpecifics.GenericDomain but 
# its "normalise" pattern is overridden so that it does not remove empty squares 
# from ListPatterns passed to it.  This enables the test to check that empty 
# squares are encoded correctly as VisualSpatialFieldObjects.
# 
# The following Fixations are then made on the Scenes specified in the order 
# denoted.
# 
# - Fixation 1 
#   ~ Scene fixated on: "old-north-east" 
#   ~ Fixation coordinates
#     > Scene-specific: (0, 0)
#     > Domain-specific: (7, 6)
#   ~ ItemSquarePatterns generated by fixation:
#     > [C 7 6]/[C -1 -1]
#     > [UU 8 6]/[UU 0 -1]
#     > [F 7 7]/[F -1 0]
#    
# - Fixation 2 
#   ~ Scene fixated on: "old-south-west"
#   ~ Fixation coordinates
#     > Scene-specific: (2, 2)
#     > Domain-specific: (5, 4)
#   ~ ItemSquarePatterns generated by fixation:
#     > [H 5 3]/[H 1 0]
#     > [Y 4 4]/[Y 0 1]
#     > [SS 5 4]/[SS 1 1]
#    
# - Fixation 3
#   ~ Scene fixated on: "old-north-west"
#   ~ Fixation coordinates
#     > Scene-specific: (2, 0)
#     > Domain-specific: (5, 6)
#   ~ ItemSquarePatterns generated by fixation:
#     > [. 4 6]/[. 0 -1]
#     > [B 5 6]/[B 1 -1]
#     > [TT 5 7]/[TT 1 0]
#    
# - Fixation 4
#   ~ Scene fixated on: "south-east" 
#   ~ Fixation coordinates
#     > Scene-specific: (0, 2)
#     > Domain-specific: (7, 4)
#   ~ ItemSquarePatterns generated by fixation:
#     > [G 7 3]/[G -1 0]
#     > [D 7 4]/[D -1 1]
#     > [. 8 4]/[. 0 1]
#     
# - Fixation 5
#   ~ Scene fixated on: "south-west" 
#   ~ Fixation coordinates
#     > Scene-specific: (2, 2)
#     > Domain-specific: (5, 4)
#   ~ ItemSquarePatterns generated by fixation:
#     > [H 5 3]/[H 1 0]
#     > [Y 4 4]/[Y 0 1]
#     > [A 5 4]/[A 1 1]
#    
# - Fixation 6
#   ~ Scene fixated on: "south-west" 
#   ~ Fixation coordinates
#     > Scene-specific: (2, 2)
#     > Domain-specific: (5, 4)
#   ~ ItemSquarePatterns generated by fixation:
#     > [H 5 3]/[H 1 0]
#     > [Y 4 4]/[Y 0 1]
#     > [A 5 4]/[A 1 1]
#    
# - Fixation 7
#   ~ Scene fixated on: "north-west"
#   ~ Fixation coordinates
#     > Scene-specific: (2, 0)
#     > Domain-specific: (5, 6)
#   ~ ItemSquarePatterns generated by fixation:
#     > [. 4 6]/[. 0 -1]
#     > [B 5 6]/[B 1 -1]
#     > [E 5 7]/[E 1 0]
#    
# - Fixation 8
#   ~ Scene fixated on: "north-east"
#   ~ Fixation coordinates
#     > Scene-specific: (0, 0)
#     > Domain-specific: (7, 6)
#   ~ ItemSquarePatterns generated by fixation:
#     > [C 7 6]/[C -1 -1]
#     > [Z 8 6]/[Z 0 -1]
#     > [F 7 7]/[F -1 0]
#    
# - Fixation 9
#   ~ Scene fixated on: "south-east"
#   ~ Fixation coordinates
#     > Scene-specific: (0, 2)
#     > Domain-specific: (7, 4)
#   ~ ItemSquarePatterns generated by fixation:
#     > [G 7 3]/[G -1 0]
#     > [D 7 4]/[D -1 1]
#     > [. 8 4]/[. 0 1]
#     
# The test then assumes that these Fixations trigger recognition of six Nodes 
# that are present in visual STM when VisualSpatialFieldConstruction occurs:
# 
#  - STM item 0 (hypothesis):
#    ~ Recognised in response to Fixation 9
#    ~ Non agent-relative object locations
#      > Content: [D 7 4]
#      > Image: [D 7 4][H 5 3][L 9 2][P 0 2][T 8 4][X 10 2]
#    ~ Agent relative object locations
#      > Content: [D -1 1]
#      > Image: [D -1 1][H -3 0][L 1 -1][P -5 1][T 0 1][X 2 -1]
#     
#  - STM item 1
#    ~ Recognised in response to Fixation 8
#    ~ Non agent-relative object locations
#      > Content: [C 7 6]
#      > Image: [C 7 6][G 7 3][K 9 8][O 9 3][S 8 6][W 10 9]
#    ~ Agent relative object locations
#      > Content: [C -1 -1]
#      > Image: [C -1 -1][G -1 -4][K 1 1][O 1 -4][S 0 -1][W 2 2]
#      
# - STM item 2
#   ~ Recognised in response to Fixation 7
#   ~ Non agent-relative object locations
#     > Content: [B 5 6]
#     > Image: [B 5 6][F 7 7][J 3 8][N 9 6][R 4 6][V 2 9]
#   ~ Agent relative object locations
#     > Content: [B 1 -1]
#     > Image: [B 1 -1][F 3 0][J -1 1][N 5 -1][R 0 -1][V -2 2]
#     
# - STM item 3
#   ~ Recognised in response to Fixation 6
#   ~ Non agent-relative object locations
#     > Content: [A 5 4]
#     > Image: [A 5 4][E 5 7][I 3 2][M 3 6][Q 4 4][U 2 2]
#   ~ Agent relative object locations
#     > Content: [A 1 1]
#     > Image: [A 1 1][E 1 4][I -1 -1][M -1 3][Q 0 1][U -2 -1]
#     
# - STM item 4
#   ~ Recognised in response to Fixation 5
#   ~ Non agent-relative object locations
#     > Content: [A 5 4]
#     > Image: [A 5 4][E 5 7][I 3 2][M 3 6][Q 4 4][U 2 2]
#   ~ Agent relative object locations
#     > Content: [A 1 1]
#     > Image: [A 1 1][E 1 4][I -1 -1][M -1 3][Q 0 1][U -2 -1]
#     
#  - STM item 5
#    ~ Recognised in response to Fixation 2
#    ~ Non agent-relative object locations
#      > Content: [SS 5 4]
#      > Image: [TT 5 7]
#    ~ Agent relative object locations
#      > Content: [SS 1 1]
#      > Image: [TT 1 4]
# 
# The VisualSpatialField constructed in response to these Fixations and visual
# STM structure is depicted below.  Note that any coordinates that were not 
# fixated on or were considered blind during Fixation performance do not have
# any VisualSpatialFieldObjects encoded on their respective coordinates in the
# VisualSpatialField constructed.
# 
# =============================
# Visual-Spatial Field Notation
# =============================
# - The coordinates fixated on are surrounded by || and == dividers.
# - The coordinates not fixated on are surrounded by : and ~ dividers.
# - The VisualSpatialFieldObject that represents the agent equipped witH CHREST 
#   is denoted by "SELF"
# - VisualSpatialFieldObjects that represent coordinates with an unknown 
#   VisualSpatialFieldObject status are denoted by "-".
# - VisualSpatialFieldObjects that represent empty VisualSpatialField 
#   coordinates have no character in the coordinate space. 
# - VisualSpatialFieldObjects that represent recognised SceneObjects are 
#   denoted by the SceneObject's type in uppercase.
# - VisualSpatialFieldObjects that represent unrecognised SceneObjects are
#   denoted by the SceneObject's type in lowercase.
# - DS are domain-specific coordinates.
# - SS are Scene-specific coordinates.
# - VSF are VisualSpatialField coordinates.
# 
# Visual-Spatial Field
# ====================
#
# VSF  SS   DS
#              ||====|====|====||~~~~||====|====|====||
# 6    2    8  || -  | -  | -  || -  || -  | -  | -  ||
#              ||----|----|----||~~~~||----|----|----||
# 5    1    7  || -  | -  | E  || -  || F  | -  | -  ||
#              ||----|----|----||~~~~||----|----|----||
# 4    0    6  || -  |    | B  || -  || C  | z  | -  ||
#              ||====|====|====||~~~~||====|====|====||
# 3         5  :: -  : -  : -  :: -  :: -  : -  : -  ::
#              ||====|====|====||~~~~||====|====|====||
# 2    2    4  || -  | y  | A  || -  || D  |    | -  ||
#              ||----|----|----||~~~~||----|----|----||
# 1    1    3  || -  | -  | H  || -  || G  |SELF| -  ||
#              ||----|----|----||~~~~||----|----|----||
# 0    0    2  || -  | -  | -  || -  || -  | -  | -  ||
#              ||====|====|====||~~~~||====|====|====||
#
#                 3    4    5     6     7    8    9    
#                 0    1    2           0    1    2
#                 0    1    2     3     4    5    6
#
# Construction Walkthrough
# ========================
# 
# - SceneObjects in STM item 0's content/image are processed first. All 
#   VisualSpatialFieldObjects created when processing a STM item are created at
#   the same time.
# - After all SceneObjects in STM items are processed, unrecognised SceneObjects
#   (SceneObjects in ItemSquarePatterns generated by Fixations but not in 
#   ItemSquarePatterns constituting STM item contents/images) are processed in
#   order of Fixation performance with the most recent Fixation being processed
#   first.  It takes time to process each Fixation and time to encode the 
#   corresponding VisualSpatialFieldObjects.
#   
# Bearing this in mind, VisualSpatialField construction proceeds as follows:
# 
# 1. SceneObjects "D" and "H" will be encoded as VisualSpatialFieldObjects first
#    since they are present in STM item 0, were fixated on in Fixations 2, 4, 5, 
#    6 and 9 and are not encoded prior to STM item 0 being processed.  Aside
#    from the coordinates "D" and "H" are found on, coordinates (8, 4) are also 
#    recognised since the fith ItemSquarePattern in STM item 0's image 
#    references them and they were fixated on when Fixations 4 and 9 were 
#    performed.  However, the SceneObject referred to by this ItemSquarePattern 
#    in the STM item is not encoded as a VisualSpatialFieldObject since it was 
#    not seen on these coordinates when Fixations 4 and 9 were made. No 
#    VisualSpatialFieldObject's termini will be refreshed since there are no 
#    other VisualSpatialFieldObjects present on the VisualSpatialField at the 
#    time Node 0 is processed.
#    
# 2. SceneObjects "C" and "G" will be encoded as VisualSpatialFieldObjects next
#    since they are present in STM item 1, were fixated on in Fixations 1, 4, 8
#    and 9 and are not encoded prior to STM item 1 being processed. Aside from 
#    the coordinates "C" and "G" are found on, coordinates (8, 6) are recognised 
#    since the fifth ItemSquarePattern in STM item 1's image references them 
#    and they were fixated on when Fixations 1 and 8 were performed. However, 
#    the SceneObject referred to by this ItemSquarePattern in the STM item is 
#    not encoded since it was not seen on these coordinates when Fixations 1 and
#    8 were made. Since coordinates (7, 3) have attention focused on them ("G" 
#    will be encoded here) and coordinates (7, 4) fall inside the fixation field 
#    of view around (7, 3), VisualSpatialFieldObject "D"s terminus is refreshed 
#    since it is alive at the time "G" is encoded.  Despite coordinates (8, 6) 
#    and (7, 6) also having attention focused on them, no 
#    VisualSpatialFieldObjects exist on them at the time attention is focused on 
#    them.
#    
# 3. SceneObjects "B" and "F" will be encoded as VisualSpatialFieldObjects
#    next since they are present in STM item 2, were fixated on in Fixations 1, 
#    3, 7 and 8 and are not encoded prior to STM item 2 being processed.  Aside 
#    from the coordinates "B" and "F" are found on, coordinates (4, 6) are 
#    recognised since the fifth ItemSquarePatern in STM item 2's image 
#    references them and they were fixated on when Fixations 3 and 7 were 
#    performed.  However, the SceneObject referred to by this ItemSquarePattern 
#    is not encoded since it was not seen when these Fixations were made.  Since 
#    coordinates (7, 7) have attention focused on them ("F" will be encoded 
#    here) and coordinates (7, 6) fall inside the fixation field of view around 
#    (7, 7), VisualSpatialFieldObject "C"s terminus is refreshed since it is 
#    alive at the time "F" is encoded.  Despite coordinates (4, 6) and (5, 
#    6) also having attention focused on them, no VisualSpatialFieldObjects
#    exist on them at the time attention is focused on them.
#    
# 4. SceneObjects "A" and "E" will be encoded as VisualSpatialFieldObjects
#    next since they are present in STM item 3, were fixated on in Fixations 5,  
#    6 and 7 and are not encoded prior to STM item 3 being processed.  Aside 
#    from the coordinates "A" and "E" are found on, coordinates (4, 4) are 
#    recognised since the fifth ItemSquarePatern in STM item 3's image 
#    references them and they were fixated on when Fixations 2, 5 and 6 were 
#    performed.  However, the SceneObject referred to by this ItemSquarePattern 
#    is not encoded since it was not seen when these Fixations were made. Since 
#    coordinates (5, 7) have attention focused on them ("E" will be encoded 
#    here) and coordinates (5, 6) fall inside the fixation field of view around 
#    (5, 7), VisualSpatialFieldObject "B"s terminus is refreshed since it is 
#    alive at the time "E" is encoded.  Also, since coordinates (4, 4) and 
#    (5, 4) have attention focused on them ((5, 4) due to "A" being 
#    encoded), "H"s VisualSpatialFieldObject terminus is refreshed too 
#    since coordinates (5, 3) fall inside the fixation field of view around
#    both (4, 4) and (5, 4) and "H" is alive when "A" is encoded and (4, 4)
#    has attention focused on it.
#
# At this point, the test has checked that recognised SceneObjects have been 
# refreshed by ItemSquarePatterns in Node images that don't reference the 
# coordinates they are found on directly but rather, in the field of fixation 
# view.
# 
# 5. STM item 4 is processed, no new VisualSpatialFieldObjects encoded since the
#    coordinates that were fixated on already have the SceneObjects recognised
#    encoded as VisualSpatialFieldObjects on the corresponding 
#    VisualSpatialField cooridnates.  The termini of VisualSpatialFieldObjects 
#    with types "A", "H", "B", "E" are refreshed (the empty square on (5, 8) and
#    VisualSpatialFieldObject with type "Y" have not been encoded as
#    VisualSpatialFieldObjects yet so their termini can not be refreshed).
#    
# Now the test has checked that VisualSpatialFieldObjects are not overwritten by 
# ItemSquarePatterns in STM item images/contents whose SceneObjects have the 
# same type as the VisualSpatialFieldObject on the coordinates referenced.
# Test has also checked that recognised VisualSpatialSceneObjects are refreshed 
# when the ItemSquarePatterns in a STM item's contents/image directly reference 
# the same VisualSpatialFieldObject.
# 
# 6. STM item 5 is processed, no new VisualSpatialFieldObjects encoded since the
#    coordinates referenced in the ItemSquarePatterns already have 
#    VisualSpatialFieldObjects encoded on them on the corresponding 
#    VisualSpatialField coordinates.  The termini of VisualSpatialFieldObjects 
#    with types "A", "H", "B", "E" are refreshed (the empty square on (5, 8) and
#    VisualSpatialFieldObject with type "Y" have not been encoded as
#    VisualSpatialFieldObjects yet so their termini can not be refreshed)
#    
# Now the test has checked that VisualSpatialFieldObjects are not overwritten by 
# ItemSquarePatterns in STM item contents *only* (STM item 5 has no image) and 
# whose SceneObjects have a different type to the VisualSpatialFieldObject on 
# the coordinates referenced. Also tests that recognised 
# VisualSpatialSceneObjects have their termini refreshed when the 
# ItemSquarePatterns in a STM item contents *only* reference a different 
# SceneObject to the corresponding VisualSpatialFieldObject.
#
# 7. The first unrecognised SceneObject will now be processed. The most recently 
#    seen unrecognised SceneObject is the empty square on (8, 4) so this will be 
#    encoded given that it does not already have a VisualSpatialFieldObject 
#    representation on the corresponding coordinates in the VisualSpatialField.  
#    When the empty square is encoded, any VisualSpatialFieldObjects that fall 
#    within the fixation field of view around (8, 4) and are alive when 
#    attention is focused on (8, 4) will have their termini refreshed.  
#    Therefore, the recognised VisualSpatialFieldObjects "D" and "G" will have 
#    their termini refreshed.
#
# 8. The second unrecognised SceneObject will now be processed,
#    i.e. SceneObject "Z" on (8, 6).  This will be encoded given that it 
#    does not already have a VisualSpatialFieldObject representation on the 
#    corresponding coordinates in the VisualSpatialField.  When "Z" is 
#    encoded, any VisualSpatialFieldObjects that fall within the fixation
#    field of view around (8, 6) and are alive when attention is focused on 
#    (8, 4) will have their termini refreshed.  Therefore, the recognised 
#    VisualSpatialFieldObjects "C" and "F" will have their termini 
#    refreshed.
#
# 9. The third unrecognised SceneObject will now be processed, i.e. the empty 
#    square on (4, 6).  This will be encoded given that it does not already have 
#    a VisualSpatialFieldObject representation on the corresponding coordinates 
#    in the VisualSpatialField.  When the empty square is encoded, any 
#    VisualSpatialFieldObjects that fall within the fixation field of view 
#    around (4, 6) and are alive when attention is focused on (4, 6) will have 
#    their termini refreshed.  Therefore, the recognised 
#    VisualSpatialFieldObjects "B" and "E" will have their termini refreshed.
#
# 10. The fourth unrecognised SceneObject will now be processed, i.e. 
#     SceneObject "Y" on (4, 4).  This will be encoded given that it does not 
#     already have a VisualSpatialFieldObject representation on the 
#     corresponding coordinates in the VisualSpatialField.  When "Y" is encoded, 
#     any VisualSpatialFieldObjects that fall within the fixation field of view 
#     around (4, 4) and are alive when attention is focused on (4, 4) will have 
#     their termini refreshed.  Therefore, the recognised 
#     VisualSpatialFieldObjects "A" and "H" will have their termini refreshed.
#
# At this point, recognised SceneObjects will have had their termini 
# refreshed by unrecognised SceneObjects not found directly on their 
# coordinates but inside the Fixation field of view for the Fixation the 
# unrecognised SceneObject was seen in context of.
#
# 11. The fifth unrecognised SceneObject will now be processed. Again, this is
#     SceneObject "Y" on (4, 4) and will not be encoded since it already has a 
#     VisualSpatialFieldObject representation on the corresponding coordinates 
#     in the VisualSpatialField.  However, as before, any 
#     VisualSpatialFieldObjects that fall within the fixation field of view 
#     around (4, 4) and are alive when attention is focused on (4, 4) will have 
#     their termini refreshed.  Therefore, the recognised 
#     VisualSpatialFieldObjects "A" and "H" will have their termini refreshed 
#     along with "Y"s VisualSpatialFieldObject terminus.
#     
# At this point, an unrecognised VisualSpatialFieldObject will have been 
# refreshed by referencing the exact unrecognised VisualSpatialFieldObject 
# to refresh.
# 
# 12. The sixth unrecognised SceneObject will now be processed, i.e. the empty
#     square on (8, 4).  This will not be encoded since it already has a 
#     VisualSpatialFieldObject representation on the corresponding coordinates 
#     in the VisualSpatialField.  However, as before, any 
#     VisualSpatialFieldObjects that fall within the fixation field of view 
#     around (8, 4) and are alive when attention is focused on (8, 4) will have 
#     their termini refreshed.  Therefore, the recognised 
#     VisualSpatialFieldObjects "D" and "G" will have their termini refreshed 
#     along with the empty square on (8, 4)s VisualSpatialFieldObject terminus.
# 
# 14. The seventh unrecognised SceneObject will now be processed, i.e. the empty
#     square on (4, 6).  This will not be encoded since it already has a 
#     VisualSpatialFieldObject representation on the corresponding coordinates 
#     in the VisualSpatialField.  However, as before, any 
#     VisualSpatialFieldObjects that fall within the fixation field of view 
#     around (4, 6) and are alive when attention is focused on (4, 6) will have 
#     their termini refreshed.  Therefore, the recognised 
#     VisualSpatialFieldObjects "B" and "E" will have their termini refreshed 
#     along with the empty square on (4, 6)s VisualSpatialFieldObject terminus.
# 
# 15. The eighth unrecognised SceneObject will now be processed, i.e. 
#     SceneObject "SS" on (5, 4).  This will not be encoded since it already has 
#     a VisualSpatialFieldObject representation on the corresponding coordinates 
#     in the VisualSpatialField.  However, as before, any 
#     VisualSpatialFieldObjects that fall within the fixation field of view 
#     around (5, 4) and are alive when attention is focused on (5, 4) will have 
#     their termini refreshed.  Therefore, the recognised 
#     VisualSpatialFieldObjects "A", "H" and "Y" will have their termini 
#     refreshed.
#
# 16. The final unrecognised VisualSpatialFieldObject will now be processed,
#     i.e. SceneObject "UU" on (8, 6). This will not be encoded since there 
#     is already a VisualSpatialFieldObject representation for SceneObject 
#     "Z" on the corresponding coordinates in the VisualSpatialField.  
#     However, any VisualSpatialFieldObjects that fall within the fixation 
#     field of view around (8, 6) and are alive when attention is focused on 
#     (8, 6) will have their termini refreshed.  Therefore, the recognised 
#     VisualSpatialFieldObjects "C" and "F" will have their termini 
#     refreshed along with "Z"s VisualSpatialFieldObject terminus.
# 
# At this point, an unrecognised VisualSpatialFieldObject will have been 
# refreshed by referencing the coordinates of the unrecognised 
# VisualSpatialFieldObject to refresh.
process_test "construct_visual_spatial_field" do
  
  for scenario in 1..2
    time = 0
    
    #########################
    ##### SET-UP CHREST #####
    #########################
    
    Chrest.class_eval{
      field_accessor :_timeToRetrieveItemFromStm,
        :_timeToEncodeRecognisedSceneObjectAsVisualSpatialFieldObject,
        :_timeToEncodeUnrecognisedEmptySquareSceneObjectAsVisualSpatialFieldObject,
        :_timeToEncodeUnrecognisedNonEmptySquareSceneObjectAsVisualSpatialFieldObject,
        :_timeToProcessUnrecognisedSceneObjectDuringVisualSpatialFieldConstruction,
        :_recognisedVisualSpatialFieldObjectLifespan,
        :_unrecognisedVisualSpatialFieldObjectLifespan,
        :_attentionClock
    }
    
    model = Chrest.new(time, (scenario == 1 ? false : scenario == 2 ? true : false))
    perceiver = model.getPerceiver()
    
    model._timeToRetrieveItemFromStm = 50
    model._timeToEncodeRecognisedSceneObjectAsVisualSpatialFieldObject = 5
    model._timeToEncodeUnrecognisedEmptySquareSceneObjectAsVisualSpatialFieldObject = 10
    model._timeToEncodeUnrecognisedNonEmptySquareSceneObjectAsVisualSpatialFieldObject = 25
    model._timeToProcessUnrecognisedSceneObjectDuringVisualSpatialFieldConstruction = 100
    model._recognisedVisualSpatialFieldObjectLifespan = 10000
    model._unrecognisedVisualSpatialFieldObjectLifespan = 8000
    
    # Override the "GenericDomain.normalise()" function.
    domain = Class.new(GenericDomain){
      def normalise(pattern)
        result = ListPattern.new(pattern.getModality());
    
        for i in 0...pattern.size
          primitive = pattern.getItem(i)
          object_type = primitive.getItem();
            
          if( 
            object_type != Scene.getCreatorToken() &&
            object_type != Scene.getBlindSquareToken() &&
            !result.contains(primitive)
          ) then
            result.add(primitive);
          end
        end
        
        return result
      end
    }.new(model, 10, 3)
    model.setDomain(domain)
    
    # Set fixation field of view
    perceiver.setFixationFieldOfView(1)

    #########################
    ##### SET-UP SCENES #####
    #########################
    
    Scene.class_eval{
      field_accessor :_scene
    }
    
    # Since there are old and new versions of some Scenes, SceneObjects need to
    # be reused otherwise, they won't be noted as being fixated on twice so 
    # create these now.
    creator = SceneObject.new(Scene.getCreatorToken())
    
    object_I = SceneObject.new("I")
    scene_1_blind_1 = SceneObject.new(Scene.getBlindSquareToken())
    scene_1_empty_1 = SceneObject.new(Scene.getEmptySquareToken())
    scene_1_empty_2 = SceneObject.new(Scene.getEmptySquareToken())
    scene_1_blind_2 = SceneObject.new(Scene.getBlindSquareToken())
    object_H = SceneObject.new("H")
    object_P = SceneObject.new("P")
    object_Y = SceneObject.new("Y")
    object_A = SceneObject.new("A")
    
    object_M = SceneObject.new("M")
    scene_2_empty_1 = SceneObject.new(Scene.getEmptySquareToken())
    object_B = SceneObject.new("B")
    scene_2_empty_2 = SceneObject.new(Scene.getEmptySquareToken())
    scene_2_blind_1 = SceneObject.new(Scene.getBlindSquareToken())
    object_E = SceneObject.new("E")
    object_J = SceneObject.new("J")
    scene_2_blind_2 = SceneObject.new(Scene.getBlindSquareToken())
    scene_2_empty_3 = SceneObject.new(Scene.getEmptySquareToken())
    
    object_C = SceneObject.new("C")
    object_Z = SceneObject.new("Z")
    object_N = SceneObject.new("N")
    object_F = SceneObject.new("F")
    scene_3_blind_1 = SceneObject.new(Scene.getBlindSquareToken())
    scene_3_empty_1 = SceneObject.new(Scene.getEmptySquareToken())
    scene_3_empty_2 = SceneObject.new(Scene.getEmptySquareToken())
    scene_3_blind_2 = SceneObject.new(Scene.getBlindSquareToken())
    object_K = SceneObject.new("K")

    scene_1 = Scene.new("south-west", 3, 3, 3, 2, nil)
    scene_2 = Scene.new("north-west", 3, 3, 3, 6, nil)
    scene_3 = Scene.new("north-east", 3, 3, 7, 6, nil)
    scene_4 = Scene.new("south-east", 3, 3, 7, 2, nil)
    scene_5 = Scene.new("old-south-west", 3, 3, 3, 2, nil)
    scene_6 = Scene.new("old-north-west", 3, 3, 3, 6, nil)
    scene_7 = Scene.new("old-north-east", 3, 3, 7, 6, nil)
    
    scene_1._scene.get(0).set(0, object_I)
    scene_1._scene.get(1).set(0, scene_1_blind_1)
    scene_1._scene.get(2).set(0, scene_1_empty_1)
    scene_1._scene.get(0).set(1, scene_1_empty_2)
    scene_1._scene.get(1).set(1, (scenario == 1 ? scene_1_blind_2 : creator))
    scene_1._scene.get(2).set(1, object_H)
    scene_1._scene.get(0).set(2, object_P)
    scene_1._scene.get(1).set(2, object_Y)
    scene_1._scene.get(2).set(2, object_A)

    scene_2._scene.get(0).set(0, object_M)
    scene_2._scene.get(1).set(0, scene_2_empty_1)
    scene_2._scene.get(2).set(0, object_B)
    scene_2._scene.get(0).set(1, scene_2_empty_2)
    scene_2._scene.get(1).set(1, (scenario == 1 ? scene_2_blind_1 : creator))
    scene_2._scene.get(2).set(1, object_E)
    scene_2._scene.get(0).set(2, object_J)
    scene_2._scene.get(1).set(2, scene_2_blind_2)
    scene_2._scene.get(2).set(2, scene_2_empty_3)

    scene_3._scene.get(0).set(0, object_C)
    scene_3._scene.get(1).set(0, object_Z)
    scene_3._scene.get(2).set(0, object_N)
    scene_3._scene.get(0).set(1, object_F)
    scene_3._scene.get(1).set(1, (scenario == 1 ? scene_3_blind_1 : creator))
    scene_3._scene.get(2).set(1, scene_3_empty_1)
    scene_3._scene.get(0).set(2, scene_3_empty_2)
    scene_3._scene.get(1).set(2, scene_3_blind_2)
    scene_3._scene.get(2).set(2, object_K)

    scene_4._scene.get(0).set(0, SceneObject.new(Scene.getEmptySquareToken()))
    scene_4._scene.get(1).set(0, SceneObject.new(Scene.getBlindSquareToken()))
    scene_4._scene.get(2).set(0, SceneObject.new("L"))
    scene_4._scene.get(0).set(1, SceneObject.new("G"))
    scene_4._scene.get(1).set(1, (scenario == 1 ? SceneObject.new(Scene.getBlindSquareToken()) : creator))
    scene_4._scene.get(2).set(1, SceneObject.new("O"))
    scene_4._scene.get(0).set(2, SceneObject.new("D"))
    scene_4._scene.get(1).set(2, SceneObject.new(Scene.getEmptySquareToken()))
    scene_4._scene.get(2).set(2, SceneObject.new(Scene.getEmptySquareToken()))
    
    scene_5._scene.get(0).set(0, object_I)
    scene_5._scene.get(1).set(0, scene_1_blind_1)
    scene_5._scene.get(2).set(0, scene_1_empty_1)
    scene_5._scene.get(0).set(1, scene_1_empty_2)
    scene_5._scene.get(1).set(1, (scenario == 1 ? scene_1_blind_2 : creator))
    scene_5._scene.get(2).set(1, object_H)
    scene_5._scene.get(0).set(2, object_P)
    scene_5._scene.get(1).set(2, object_Y)
    scene_5._scene.get(2).set(2, SceneObject.new("SS"))
    
    scene_6._scene.get(0).set(0, object_M)
    scene_6._scene.get(1).set(0, scene_2_empty_1)
    scene_6._scene.get(2).set(0, object_B)
    scene_6._scene.get(0).set(1, scene_2_empty_2)
    scene_6._scene.get(1).set(1, (scenario == 1 ? scene_2_blind_1 : creator))
    scene_6._scene.get(2).set(1, SceneObject.new("TT"))
    scene_6._scene.get(0).set(2, object_J)
    scene_6._scene.get(1).set(2, scene_2_blind_2)
    scene_6._scene.get(2).set(2, scene_2_empty_3)
    
    scene_7._scene.get(0).set(0, object_C)
    scene_7._scene.get(1).set(0, SceneObject.new("UU"))
    scene_7._scene.get(2).set(0, object_N)
    scene_7._scene.get(0).set(1, object_F)
    scene_7._scene.get(1).set(1, (scenario == 1 ? scene_3_blind_1 : creator))
    scene_7._scene.get(2).set(1, scene_3_empty_1)
    scene_7._scene.get(0).set(2, scene_3_empty_2)
    scene_7._scene.get(1).set(2, scene_3_blind_2)
    scene_7._scene.get(2).set(2, object_K)
    
    #############################################################
    ##### SET-UP FIXATIONS AND POPULATE PERCEIVER FIXATIONS #####
    #############################################################
    
    fixations_field = perceiver.java_class.declared_field("_fixations")
    fixations_field.accessible = true
    
    Fixation.class_eval{
      field_accessor :_timeDecidedUpon, :_performanceTime, :_performed, :_scene, :_colFixatedOn, :_rowFixatedOn, :_objectSeen
    }
    
    for fixation_number in 1..9
      fixation = CentralFixation.new(time) #Sets Fixation's _timeDecidedUpon
      
      if fixation_number == 1 then fixation._scene, fixation._colFixatedOn, fixation._rowFixatedOn = scene_7, 0, 0 end
      if fixation_number == 2 then fixation._scene, fixation._colFixatedOn, fixation._rowFixatedOn = scene_5, 2, 2 end
      if fixation_number == 3 then fixation._scene, fixation._colFixatedOn, fixation._rowFixatedOn = scene_6, 2, 0 end  
      if fixation_number == 4 then fixation._scene, fixation._colFixatedOn, fixation._rowFixatedOn = scene_4, 0, 2 end
      
      if fixation_number == 5 then fixation._scene, fixation._colFixatedOn, fixation._rowFixatedOn = scene_1, 2, 2 end
      if fixation_number == 6 then fixation._scene, fixation._colFixatedOn, fixation._rowFixatedOn = scene_1, 2, 2 end
      if fixation_number == 7 then fixation._scene, fixation._colFixatedOn, fixation._rowFixatedOn = scene_2, 2, 0 end
      if fixation_number == 8 then fixation._scene, fixation._colFixatedOn, fixation._rowFixatedOn = scene_3, 0, 0 end
      if fixation_number == 9 then fixation._scene, fixation._colFixatedOn, fixation._rowFixatedOn = scene_4, 0, 2 end

      fixation._objectSeen = fixation._scene.getSquareContents(fixation._colFixatedOn, fixation._rowFixatedOn)
      fixation._performed = true
      fixation._performanceTime = (fixation._timeDecidedUpon + 30)

      current_fixations = fixations_field.value(perceiver).lastEntry().getValue()
      new_fixations = ArrayList.new()
      new_fixations.addAll(current_fixations)
      new_fixations.add(fixation)
      fixations_field.value(perceiver).put(fixation._performanceTime, new_fixations)

      time = fixation._performanceTime
      fixation_number += 1
    end
    
    ################################################
    ##### SET-UP NODES AND POPULATE VISUAL STM #####
    ################################################
    
    stm_item_history_field = Stm.java_class.declared_field("_itemHistory")
    stm_item_history_field.accessible = true
    
    for node_number in 1..6
      
      # Set Node content
      node_contents = ListPattern.new(Modality::VISUAL)
      content = []
      
      if scenario == 1
        if node_number == 1 then content = ["SS", 5, 4] end
        if node_number == 2 || node_number == 3 then content = ["A", 5, 4] end
        if node_number == 4 then content = ["B", 5, 6] end
        if node_number == 5 then content = ["C", 7, 6] end
        if node_number == 6 then content = ["D", 7, 4] end
      elsif scenario == 2
        if node_number == 1 then content = ["SS", 1, 1] end
        if node_number == 2 || node_number == 3 then content = ["A", 1, 1] end
        if node_number == 4 then content = ["B", 1, -1] end
        if node_number == 5 then content = ["C", -1, -1] end
        if node_number == 6 then content = ["D", -1, 1] end
      end
      
      if !content.empty? then node_contents.add(ItemSquarePattern.new(content[0].to_s, content[1], content[2])) end
      
      # Set image
      node_image = ListPattern.new(Modality::VISUAL)
      if node_number != 1 then node_image = node_image.append(node_contents) end
      
      image = []
      if scenario == 1
        if node_number == 1 then image = [["TT", 5, 7]] end
        if node_number == 2 || node_number == 3 then image = [["E", 5, 7],["I", 3, 2],["M", 3, 6],["Q", 4, 4],["U", 2, 2]] end
        if node_number == 4 then image = [["F", 7, 7],["J", 3, 8],["N", 9, 6],["R", 4, 6],["V", 2, 9]] end
        if node_number == 5 then image = [["G", 7, 3],["K", 9, 8],["O", 9, 3],["S", 8, 6],["W", 10, 9]] end
        if node_number == 6 then image = [["H", 5, 3],["L", 9, 2],["P", 0, 2],["T", 8, 4],["X", 10, 2]] end
      elsif scenario == 2
        if node_number == 1 then image = [["TT", 1, 4]] end
        if node_number == 2 || node_number == 3 then image = [["E", 1, 4],["I", -1, -1],["M", -1, 3],["Q", 0, 1],["U", -2, -1]] end
        if node_number == 4 then image = [["F", 3, 0],["J", -1, 1],["N", 5, -1],["R", 0, -1],["V", -2, 2]] end
        if node_number == 5 then image = [["G", -1, -4],["K", 1, 1],["O", 1, -4],["S", 0, -1],["W", 2, 2]] end
        if node_number == 6 then image = [["H", -3, 0],["L", 1, -1],["P", -5, 1],["T", 0, 1],["X", 2, -1]] end
      end
      
      for image_primitive in image
        node_image.add(ItemSquarePattern.new(image_primitive[0], image_primitive[1], image_primitive[2]))
      end
      
      # Construct node
      node = Node.new(model, node_contents, node_image, time)
      
      # Add node to visual STM
      current_stm_items = stm_item_history_field.value(model.getStm(Modality::VISUAL)).lastEntry().getValue()
      new_stm_items = ArrayList.new()
      new_stm_items.add(node)
      new_stm_items.addAll(current_stm_items)
      stm_item_history_field.value(model.getStm(Modality::VISUAL)).put(time += 10, new_stm_items)
    end
    
    ##############################################
    ##### CONSTRUCT THE VISUAL-SPATIAL FIELD #####  
    ##############################################

    inst_vsf_method = Chrest.java_class.declared_method("constructVisualSpatialField", Java::int)
    inst_vsf_method.accessible = true
    vsf = inst_vsf_method.invoke(model, time)
    
    ##############################################
    ##### SET EXPECTED VALUES DATA STRUCTURE #####
    ##############################################
    VisualSpatialFieldObject.class_eval{
      field_accessor :_timeCreated, :_terminus
    }
    
    vsfo_recognised_history_field = VisualSpatialFieldObject.java_class.declared_field("_recognisedHistory")
    vsfo_unknown_square_token_field = VisualSpatialFieldObject.java_class.declared_field("UNKNOWN_SQUARE_TOKEN")
    vsfo_recognised_history_field.accessible = true
    vsfo_unknown_square_token_field.accessible = true
    
    # Need to be able to access the VisualSpatialField constructed and its
    # dimensions for testing.  Since all these fields are private and final, a
    # class_eval construct can not be used to access them instead, they must be
    # accessed "manually".
    visual_spatial_fields = model.java_class.declared_field("_visualSpatialFields")
    height_field = VisualSpatialField.java_class.declared_field("_height")
    width_field = VisualSpatialField.java_class.declared_field("_width")
    vsf_field = VisualSpatialField.java_class.declared_field("_visualSpatialField")
    visual_spatial_fields.accessible = true
    height_field.accessible = true
    width_field.accessible = true
    vsf_field.accessible = true
    
    # Get the VisualSpatialField just constructed.
    vsf = visual_spatial_fields.value(model).lastEntry().getValue()
    vsf_field_value = vsf_field.value(vsf)
    
    ##################################
    ##### SET EXPECTED VARIABLES #####
    ##################################
    
    # The expected value data structure is a 4D array with the following 
    # structure:
    # 1: VisualSpatialField column
    # 2: VisualSpatialField row
    # 3: VisualSpatialFieldObject on VisualSpatialField column and row 
    # 4.1: VisualSpatialFieldObject type
    # 4.2: VisualSpatialFieldObject recognised status
    # 4.3: VisualSpatialFieldObject creation time
    # 4.4: VisualSpatialFieldObject terminus
    expected_visual_spatial_field_data = 
      Array.new(7){ Array.new(7) { Array.new } }
    
    # For most coordinates, no VisualSpatialFieldObjects are expected.
    for col in 0...width_field.value(vsf)
      for row in 0...height_field.value(vsf)
        
        # Set creation and terminus values to 0, these will be calculated 
        # afterwards.
        if col == 1 && row == 2 then expected_visual_spatial_field_data[col][row] = [["Y", false, 0, 0]] end
        if col == 1 && row == 4 then expected_visual_spatial_field_data[col][row] = [[Scene.getEmptySquareToken, false, 0, 0]] end
        
        if col == 2 && row == 1 then expected_visual_spatial_field_data[col][row] = [["H", true, 0, 0]] end
        if col == 2 && row == 2 then expected_visual_spatial_field_data[col][row] = [["A", true, 0, 0]] end
        if col == 2 && row == 4 then expected_visual_spatial_field_data[col][row] = [["B", true, 0, 0]] end
        if col == 2 && row == 5 then expected_visual_spatial_field_data[col][row] = [["E", true, 0, 0]] end
        
        if col == 4 && row == 1 then expected_visual_spatial_field_data[col][row] = [["G", true, 0, 0]] end
        if col == 4 && row == 2 then expected_visual_spatial_field_data[col][row] = [["D", true, 0, 0]] end
        if col == 4 && row == 4 then expected_visual_spatial_field_data[col][row] = [["C", true, 0, 0]] end
        if col == 4 && row == 5 then expected_visual_spatial_field_data[col][row] = [["F", true, 0, 0]] end
        
        if col == 5 && row == 1 && scenario == 2 then expected_visual_spatial_field_data[col][row] = [[Scene.getCreatorToken(), false, time, 0]] end
        if col == 5 && row == 2 then expected_visual_spatial_field_data[col][row] = [[Scene.getEmptySquareToken, false, 0, 0]] end
        if col == 5 && row == 4 then expected_visual_spatial_field_data[col][row] = [["Z", false, 0, 0]] end
        
      end
    end
    
    # Now that the expected VisualSpatialFieldObject data structure is populated
    # with elements for non-initial VisualSpatialFieldObjects, calculate their 
    # creation and terminus times.
    #
    # Recognised SceneObjects created first in order of their STM Node 
    # appearance (visual-spatial field coordinates that SceneObject is located 
    # on in parenthesis):
    # 
    # 1. H (2, 1) and D (4, 2)
    # 2. G (4, 1) and C (4, 4)
    # 3. B (2, 4) and F (4, 5)
    # 4. A (2, 2) and E (2, 5)
    creation_time = time
    node_processing_times = []
    for node in 1..6
      creation_time += model._timeToRetrieveItemFromStm
      node_processing_times.push(creation_time)
      
       if [1,2,3,4].include?(node) then 
        creation_time += model._timeToEncodeRecognisedSceneObjectAsVisualSpatialFieldObject
      end
      
      coordinates_to_edit = []
      if node == 1 then coordinates_to_edit = [[2, 1],[4, 2]] end
      if node == 2 then coordinates_to_edit = [[4, 1],[4, 4]] end
      if node == 3 then coordinates_to_edit = [[2, 4],[4, 5]] end
      if node == 4 then coordinates_to_edit = [[2, 2],[2, 5]] end
      
      for col_and_row in coordinates_to_edit
        col = col_and_row[0]
        row = col_and_row[1]
        expected_visual_spatial_field_data[col][row][0][2] = creation_time
      end
    end
    
    # Unrecognised SceneObjects created next, in order of Fixation performance 
    # (SceneObjects fixated on most recently are created first, visual-spatial 
    # field coordinates that SceneObject is located on in parenthesis):
    #
    # 1. Empty square (5, 2)
    # 2. Z (5, 4)
    # 3. Empty square (1, 4)
    # 4. Y (1, 2)
    fixation_processing_times = []
    for fixation in 1..9
      creation_time += model._timeToProcessUnrecognisedSceneObjectDuringVisualSpatialFieldConstruction
      fixation_processing_times.push(creation_time)
      
      if fixation == 1 || fixation == 3 
        creation_time += model._timeToEncodeUnrecognisedEmptySquareSceneObjectAsVisualSpatialFieldObject
      elsif fixation == 2 || fixation == 4
        creation_time += model._timeToEncodeUnrecognisedNonEmptySquareSceneObjectAsVisualSpatialFieldObject
      end
      
      coordinates_to_edit = []
      if fixation == 1 then coordinates_to_edit.push([5, 2]) end
      if fixation == 2 then coordinates_to_edit.push([5, 4]) end
      if fixation == 3 then coordinates_to_edit.push([1, 4]) end
      if fixation == 4 then coordinates_to_edit.push([1, 2]) end
      
      for coordinate_to_edit in coordinates_to_edit
        col = coordinate_to_edit[0]
        row = coordinate_to_edit[1]
        expected_visual_spatial_field_data[col][row][0][2] = creation_time
      end
    end
    
    # Set terminus values for recognised and unrecognised 
    # VisualSpatialFieldObjects. The terminus value is dictated by the last time 
    # a SceneObject's coordinates are processed in the function.
    for col in 0...width_field.value(vsf)
      for row in 0...height_field.value(vsf)
        
        terminus = nil

        if col == 1 && row == 2 then terminus = fixation_processing_times[7] + model._unrecognisedVisualSpatialFieldObjectLifespan end#Y
        if col == 1 && row == 4 then terminus = fixation_processing_times[6] + model._unrecognisedVisualSpatialFieldObjectLifespan end #Empty square
        
        if col == 2 && row == 1 then terminus = fixation_processing_times[7] + model._recognisedVisualSpatialFieldObjectLifespan end #H
        if col == 2 && row == 2 then terminus = fixation_processing_times[7] + model._recognisedVisualSpatialFieldObjectLifespan end #A
        if col == 2 && row == 4 then terminus = fixation_processing_times[6] + model._recognisedVisualSpatialFieldObjectLifespan end #B
        if col == 2 && row == 5 then terminus = fixation_processing_times[6] + model._recognisedVisualSpatialFieldObjectLifespan end #E
        
        if col == 4 && row == 1 then terminus = fixation_processing_times[5] + model._recognisedVisualSpatialFieldObjectLifespan end #G
        if col == 4 && row == 2 then terminus = fixation_processing_times[5] + model._recognisedVisualSpatialFieldObjectLifespan end #D
        if col == 4 && row == 4 then terminus = fixation_processing_times[8] + model._recognisedVisualSpatialFieldObjectLifespan end #C
        if col == 4 && row == 5 then terminus = fixation_processing_times[8] + model._recognisedVisualSpatialFieldObjectLifespan end #F
        
        if col == 5 && row == 2 then terminus = fixation_processing_times[5] + model._unrecognisedVisualSpatialFieldObjectLifespan end #Empty
        if col == 5 && row == 4 then terminus = fixation_processing_times[8] + model._unrecognisedVisualSpatialFieldObjectLifespan end #Z
        
        if terminus != nil then expected_visual_spatial_field_data[col][row][0][3] = terminus end
        if col == 5 && row == 1 && scenario == 2 then expected_visual_spatial_field_data[col][row][0][3] = nil end #Creator
      end
    end
    
    #################
    ##### TESTS #####
    #################
    
    assert_equal(
      fixation_processing_times.last, 
      model._attentionClock,
      "occurred when checking the CHREST model's attention clock in scenario " +
      scenario.to_s
    )

    for col in 0...width_field.value(vsf)
      for row in 0...height_field.value(vsf)
        
        assert_equal(
          expected_visual_spatial_field_data[col][row].size(),
          vsf_field_value.get(col).get(row).size(),
          "occurred when checking the number of VisualSpatialFieldObjects on " +
          "col " + col.to_s + ", row " + row.to_s + " in context of test " +
          "scenario " + scenario.to_s
        )
        
        for object in 0...vsf_field_value.get(col).get(row).size()
          vsf_object = vsf_field_value.get(col).get(row).get(object)

          error_msg_postpend = "VisualSpatialFieldObject " +
            (object + 1).to_s + " on col " + col.to_s + ", row " + row.to_s +
            " in context of test scenario " + scenario.to_s
        
          assert_equal(
            expected_visual_spatial_field_data[col][row][object][0],
            vsf_object.getObjectType(),
            "occurred when checking the type of " + error_msg_postpend
          )
          
          assert_equal(
            expected_visual_spatial_field_data[col][row][object][1],
            vsfo_recognised_history_field.value(vsf_object).lastEntry().getValue(),
            "occurred when checking the recognised status of " + error_msg_postpend
          )
          
          assert_equal(
            expected_visual_spatial_field_data[col][row][object][2],
            vsf_object._timeCreated,
            "occurred when checking the creation time of " + error_msg_postpend
          )
          
          assert_equal(
            expected_visual_spatial_field_data[col][row][object][3],
            vsf_object._terminus,
            "occurred when checking the terminus of " + error_msg_postpend
          )
        end
      end
    end
  end
end

################################################################################
# Tests for correct operation of the "VisualSpatialField.moveObjects()" function
# when moving the following types of VisualSpatialFieldObjects in all possible 
# scenarios:
# 
# - A recognised VisualSpatialFieldObject that represents a non-empty square 
# - An unrecognised VisualSpatialFieldObject that represents a non-empty square
# - The creator of the VisualSpatialField
# 
# In the final 3 scenarios, the test also checks that exceptions are thrown and
# handled correctly.
# 
# The initial state of the VisualSpatialField used in the test is illustrated 
# below.
# 
# Notation Used
# =============
# 
# - "~" represents a coordinate whose VisualSpatialFieldObject status is unknown 
# - VisualSpatialFieldObjects are denoted by their identifiers followed by their 
#   type in parenthesis
# - The creator/agent equipped with CHREST is denoted with type "SLF"
# - Recognised VisualSpatialFieldObjects have uppercase types
# - Unrecognised VisualSpatialFieldObjects have lowercase types
# - VisualSpatialField coordinates are listed along the x and y-axis
# 
# =====================
# === Scenarios 1-6 ===
# =====================
# 
# - VisualSpatialFieldObject with identifier "1" will be moved.
# - VisualSpatialFieldObject with identifier "1" is recognised.
# 
#                  --------
# 4     ~      ~   |      |   ~      ~
#           ----------------------
# 3     ~   | 3(c) |      |      |   ~
#    ------------------------------------
# 2  |      |      | 2(B) |      |      |
#    ------------------------------------
# 1     ~   | 1(A) |      |      |   x
#           ----------------------
# 0     ~      ~   |0(SLF)|   ~      ~
#                  --------
#       0      1      2       3      4     COORDINATES
#
# ======================
# === Scenarios 7-12 ===
# ======================
# 
# - VisualSpatialFieldObject with identifier "1" will be moved.
# - VisualSpatialFieldObject with identifier "1" is unrecognised.
# 
#                  --------
# 4     ~      ~   |      |   ~      ~
#           ----------------------
# 3     ~   | 3(c) |      |      |   ~
#    ------------------------------------
# 2  |      |      | 2(B) |      |      |
#    ------------------------------------
# 1     ~   | 1(a) |      |      |   x
#           ----------------------
# 0     ~      ~   |0(SLF)|   ~      ~
#                  --------
#       0      1      2       3      4     COORDINATES
#
# =======================
# === Scenarios 13-20 ===
# =======================
#
# - VisualSpatialFieldObject with identifier "1" will be the creator and will
#   be the VisualSpatialFieldObject moved.
#
#                  --------
# 4     ~      ~   |      |   ~      ~
#           ----------------------
# 3     ~   | 3(c) |      |      |   ~
#    ------------------------------------
# 2  |      |      | 2(B) |      |      |
#    ------------------------------------
# 1     ~   |1(SLF)|      |      |   x
#           ----------------------
# 0     ~      ~   |      |   ~      ~
#                  --------
#       0      1      2       3      4     COORDINATES
process_test "move_visual_spatial_field_object" do
  
  recognised_history_field = VisualSpatialFieldObject.java_class.declared_field("_recognisedHistory")
  recognised_history_field.accessible = true
  
  for scenario in 1..20
    
    time = 0
    
    ###################################
    ##### CREATE NEW CHREST MODEL #####
    ###################################
    
    # Need to access the Perceiver associated with the CHREST model to create to 
    # set its fixation field of view.  Since the instance field that stores the 
    # Perceiver associated with the CHREST model is private and final, accessing 
    # it must be enabled "manually", i.e. setting its "accessible" property 
    # rather than using a "class_eval" structure.
    perceiver_field = Chrest.java_class.declared_field("_perceiver")
    perceiver_field.accessible = true
    
    # Create CHREST model and set the "learning object locations relative to 
    # agent" constructor parameter to true since the creator will be denoted in 
    # the VisualSpatialField.
    model = Chrest.new(time, true)
    
    # Set the fixation field of view for the Perceiver associated with the 
    # CHREST model created to 1. This is used when the termini of 
    # VisualSpatialFieldObject's on the VisualSpatialField are refreshed during 
    # the 'pick-up' and 'put-down' stages of VisualSpatialFieldObject movement.
    # Since this instance field is private but not final, a "class_eval" 
    # structure can be used to set its value.
    Perceiver.class_eval{
      field_accessor :_fixationFieldOfView
    }
    perceiver_field.value(model)._fixationFieldOfView = 1

    ##########################################
    ##### CONSTRUCT VISUAL-SPATIAL FIELD #####
    ##########################################

    # Set visual-spatial field variables related to the test in the CHREST model
    # directly.  Since these fields are private but not final, a class_eval 
    # structure can be used to set them directly.
    Chrest.class_eval{
      field_accessor :_timeToEncodeRecognisedSceneObjectAsVisualSpatialFieldObject,
        :_timeToEncodeUnrecognisedEmptySquareSceneObjectAsVisualSpatialFieldObject,
        :_timeToEncodeUnrecognisedNonEmptySquareSceneObjectAsVisualSpatialFieldObject,
        :_timeToProcessUnrecognisedSceneObjectDuringVisualSpatialFieldConstruction,
        :_recognisedVisualSpatialFieldObjectLifespan,
        :_unrecognisedVisualSpatialFieldObjectLifespan,
        :_timeToAccessVisualSpatialField,
        :_timeToMoveVisualSpatialFieldObject
    }
    
    model._timeToEncodeRecognisedSceneObjectAsVisualSpatialFieldObject = 10
    model._timeToEncodeUnrecognisedEmptySquareSceneObjectAsVisualSpatialFieldObject = 15
    model._timeToEncodeUnrecognisedNonEmptySquareSceneObjectAsVisualSpatialFieldObject = 20
    model._timeToProcessUnrecognisedSceneObjectDuringVisualSpatialFieldConstruction = 100
    model._recognisedVisualSpatialFieldObjectLifespan = 60000
    model._unrecognisedVisualSpatialFieldObjectLifespan = 30000
    model._timeToAccessVisualSpatialField = 100
    model._timeToMoveVisualSpatialFieldObject = 250

    # Set-up creator details.
    creator_details = ArrayList.new()
    creator_details.add( (scenario.between?(1, 12) ? "0" : "1") ) #Identifier for creator
    creator_details.add( (scenario.between?(1, 12) ? Square.new(2, 0) : Square.new(1, 1)) ) #Location in visual-spatial field
    
    # Create the visual-spatial field
    visual_spatial_field = VisualSpatialField.new("test", 5, 5, 2, 2, model, creator_details, time += 100)
    visual_spatial_field_creation_time = time
    
    # Add VisualSpatialField to model's database.
    vsfs_field = model.java_class.declared_field("_visualSpatialFields")
    vsfs_field.accessible = true
    vsfs_field.value(model).put(visual_spatial_field_creation_time.to_java(:int), visual_spatial_field)

    # Set-up VisualSpatialFieldObjects
    visual_spatial_field_object_a = nil
    if(scenario.between?(1, 12))
      visual_spatial_field_object_a = VisualSpatialFieldObject.new(
        "1", 
        "A", 
        model, 
        visual_spatial_field, 
        time += (scenario.between?(7, 12) ? 
          model._timeToProcessUnrecognisedSceneObjectDuringVisualSpatialFieldConstruction + model._timeToEncodeUnrecognisedNonEmptySquareSceneObjectAsVisualSpatialFieldObject : 
          model._timeToEncodeRecognisedSceneObjectAsVisualSpatialFieldObject
        ), 
        (scenario.between?(7, 12) ? false : true), 
        true
      )
    end
    
    visual_spatial_field_object_b = VisualSpatialFieldObject.new(
      "2", 
      "B", 
      model, 
      visual_spatial_field, 
      time += model._timeToEncodeRecognisedSceneObjectAsVisualSpatialFieldObject, 
      true, 
      true
    )
    
    visual_spatial_field_object_c = VisualSpatialFieldObject.new(
      "3", 
      "C", 
      model, 
      visual_spatial_field, 
      time += (model._timeToProcessUnrecognisedSceneObjectDuringVisualSpatialFieldConstruction + model._timeToEncodeUnrecognisedNonEmptySquareSceneObjectAsVisualSpatialFieldObject), 
      false, 
      true
    )
    
    # Populate the visual-spatial field (need access to the actual 
    # visual-spatial field instance field).  Since this is private and final, 
    # its "accessible" property needs to be set to "true" manually.
    visual_spatial_field_field = VisualSpatialField.java_class.declared_field("_visualSpatialField")
    visual_spatial_field_field.accessible = true
    vsf = visual_spatial_field_field.value(visual_spatial_field) #This is the "actual" visual-spatial field.
    
    if visual_spatial_field_object_a != nil then vsf.get(1).get(1).add(visual_spatial_field_object_a) end
    vsf.get(2).get(2).add(visual_spatial_field_object_b)
    vsf.get(1).get(3).add(visual_spatial_field_object_c)
    
    # Add empty squares, in scenarios 11-14, coordinates (2, 2) will be empty
    # rather than occupied by the creator
    for i in 1..(scenario.between?(1, 12) ? 9 : 10)
      empty_visual_spatial_field_object = VisualSpatialFieldObject.new(
        SecureRandom.uuid, 
        Scene.getEmptySquareToken(), 
        model, 
        visual_spatial_field, 
        time += (model._timeToProcessUnrecognisedSceneObjectDuringVisualSpatialFieldConstruction + model._timeToEncodeUnrecognisedEmptySquareSceneObjectAsVisualSpatialFieldObject), 
        false, 
        true
      )
      
      coordinates_to_add_empty_square_to = []
      if i == 1 then coordinates_to_add_empty_square_to = [2, 1] end
      if i == 2 then coordinates_to_add_empty_square_to = [3, 1] end
      if i == 3 then coordinates_to_add_empty_square_to = [0, 2] end
      if i == 4 then coordinates_to_add_empty_square_to = [1, 2] end
      if i == 5 then coordinates_to_add_empty_square_to = [3, 2] end
      if i == 6 then coordinates_to_add_empty_square_to = [4, 2] end
      if i == 7 then coordinates_to_add_empty_square_to = [2, 3] end
      if i == 8 then coordinates_to_add_empty_square_to = [3, 3] end
      if i == 9 then coordinates_to_add_empty_square_to = [2, 4] end
      if i == 10 then coordinates_to_add_empty_square_to = [2, 0] end
      
      vsf.get(coordinates_to_add_empty_square_to[0]).get(coordinates_to_add_empty_square_to[1]).add(empty_visual_spatial_field_object)
    end
    
    ####################################################################
    ##### SET-UP EXPECTED VISUAL-SPATIAL FIELD COORDINATE CONTENTS #####
    ####################################################################

    expected_visual_spatial_field_data = Array.new(5){ Array.new(5) { Array.new } }
    expected_creation_time = visual_spatial_field_creation_time
    
    # VisualSpatialFieldObject on (1, 1): first VisualSpatialFieldObject either 
    # has type "A" or is the creator.
    expected_visual_spatial_field_data[1][1] = [[
        "1", 
        (scenario.between?(1, 12) ? "A" : Scene.getCreatorToken()), 
        (scenario.between?(1, 6) ? true : false), 
        (scenario.between?(1, 12) ?
          (expected_creation_time += 
            (scenario.between?(1, 6) ? 
              model._timeToEncodeRecognisedSceneObjectAsVisualSpatialFieldObject :
              model._timeToProcessUnrecognisedSceneObjectDuringVisualSpatialFieldConstruction + model._timeToEncodeUnrecognisedNonEmptySquareSceneObjectAsVisualSpatialFieldObject
            )
          ) : 
          visual_spatial_field_creation_time # Creator encoded when the VisualSpatialField is constructed
        ),
        (scenario.between?(1, 12) ?
          (expected_creation_time + 
            (scenario.between?(1, 6) ? 
              model._recognisedVisualSpatialFieldObjectLifespan :
              model._unrecognisedVisualSpatialFieldObjectLifespan
            )
          ) :
          nil # Creator always has a null terminus
        )
    ]]
  
    # VisualSpatialFieldObject with type "B" is always the first object on (2, 2)
    expected_visual_spatial_field_data[2][2] = [[
      "2", 
      "B", 
      true, 
      expected_creation_time += model._timeToEncodeRecognisedSceneObjectAsVisualSpatialFieldObject, 
      expected_creation_time + model._recognisedVisualSpatialFieldObjectLifespan
    ]]
  
    # VisualSpatialFieldObject with type "C" is always the first object on (1, 3)
    expected_visual_spatial_field_data[1][3] = [[
      "3", 
      "C", 
      false, 
      expected_creation_time += (model._timeToProcessUnrecognisedSceneObjectDuringVisualSpatialFieldConstruction + model._timeToEncodeUnrecognisedNonEmptySquareSceneObjectAsVisualSpatialFieldObject), 
      expected_creation_time + model._unrecognisedVisualSpatialFieldObjectLifespan
    ]]
  
    empty_square_coordinates = [[2, 1],[3, 1],[0, 2],[1, 2],[3, 2],[4, 2],[2, 3],[3, 3],[2, 4]]
    
    for empty_square_coordinate in empty_square_coordinates
      expected_visual_spatial_field_data[empty_square_coordinate[0]][empty_square_coordinate[1]] = [[
        nil,
        Scene.getEmptySquareToken(),
        false,
        expected_creation_time += (model._timeToProcessUnrecognisedSceneObjectDuringVisualSpatialFieldConstruction + model._timeToEncodeUnrecognisedEmptySquareSceneObjectAsVisualSpatialFieldObject),
        expected_creation_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ]]
    end
    
    expected_visual_spatial_field_data[2][0] = (scenario.between?(1,12) ? 
      [["0", Scene.getCreatorToken(), false, visual_spatial_field_creation_time, nil]] :
      [[
        nil, 
        Scene.getEmptySquareToken, 
        false, 
        expected_creation_time += (model._timeToProcessUnrecognisedSceneObjectDuringVisualSpatialFieldConstruction + model._timeToEncodeUnrecognisedEmptySquareSceneObjectAsVisualSpatialFieldObject), 
        expected_creation_time + model._unrecognisedVisualSpatialFieldObjectLifespan]]
    )
    
    ############################################################################
    # ==================
    # === Scenario 1 ===
    # ==================
    # 
    # - Move recognised VisualSpatialFieldObject to coordinates whose 
    #   VisualSpatialFieldObject status is unknown.
    # - Moves performed:
    #   + VisualSpatialFieldObject with identifier "1" moved from (1, 1) to 
    #     (0, 1).
    #     
    # - Expected VisualSpatialField state after move:
    # 
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      | 2(B) |      |      |
    #    ------------------------------------
    # 1  | 1(A) |      |      |      |   ~
    #    -----------------------------
    # 0     ~      ~   |0(SLF)|   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #
    # ==================
    # === Scenario 7 ===
    # ==================
    #
    # - As scenario 1 but VisualSpatialFieldObject with identifier "1" will be
    #   unrecognised.
    #
    # ===================
    # === Scenario 13 ===
    # ===================
    # 
    # - As scenario 7 but expected VisualSpatialField state after move is 
    #  different:
    # 
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      | 2(B) |      |      |
    #    ------------------------------------
    # 1  |1(SLF)|      |      |      |   ~
    #    -----------------------------
    # 0     ~      ~   |      |   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    if (scenario == 1 || scenario == 7 || scenario == 13)
      
      # Construct move
      move = ArrayList.new
      move.add(ItemSquarePattern.new("1", 1, 1))
      move.add(ItemSquarePattern.new("1", 0, 1))
      move_sequence = ArrayList.new
      move_sequence.add(move)
      
      # Set relevant timing parameters.
      time_move_requested = time
      pickup_time = time_move_requested + model._timeToAccessVisualSpatialField
      putdown_time = pickup_time + model._timeToMoveVisualSpatialFieldObject
      expected_attention_clock = putdown_time
      
      # Set terminus for VisualSpatialFieldObject being moved
      expected_visual_spatial_field_data[1][1][0][4] = pickup_time
      
      # New VisualSpatialFieldObject representing an empty square should be 
      # added to (1, 1) when VisualSpatialFieldObject being moved is picked up.
      expected_visual_spatial_field_data[1][1].push([
        nil,
        Scene.getEmptySquareToken(),
        false,
        pickup_time,
        pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # Refresh termini of VisualSpatialField objects on coordinates around 
      # (1, 1) that fall within the fixation field of view.
      if scenario == 13 then expected_visual_spatial_field_data[2][0][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan end
      expected_visual_spatial_field_data[2][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[0][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[0][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][0][4] = pickup_time + model._recognisedVisualSpatialFieldObjectLifespan
      
      # New VisualSpatialFieldObject representing the VisualSpatialFieldObject
      # being moved should be added to (0, 1).  If the VisualSpatialFieldObject 
      # being moved was previously recognised it should now be unrecognised.
      expected_visual_spatial_field_data[0][1] = [[
        "1", 
        (scenario == 13 ? Scene.getCreatorToken() : "A"), 
        false, 
        putdown_time, 
        putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ]]
      
      # VisualSpatialFieldObjects in fixation field of view around (0, 1) should
      # have their termini refreshed.
      expected_visual_spatial_field_data[1][1][1][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[0][2][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][2][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      move_visual_spatial_field_object_test(
        model,
        move_sequence,
        time_move_requested,
        expected_visual_spatial_field_data,
        expected_attention_clock,
        putdown_time,
        scenario
      )
    
    ############################################################################
    # ==================
    # === Scenario 2 ===
    # ==================
    # 
    # - Move a recognised VisualSpatialFieldObject to coordinates containing a 
    #   live VisualSpatialFieldObject representing an empty square.
    # - Move a recognised VisualSpatialFieldObject from coordinates that 
    #   contained a VisualSpatialFieldObject representing an empty square 
    #   previously.
    # - Move(s) performed:
    #   + VisualSpatialFieldObject with identifer "1" moved from (1, 1) to 
    #     (1, 2).
    #   + VisualSpatialFieldObject with identifer "1" moved from (1, 2) to 
    #     (3, 2)
    # - In between moves, VisualSpatialFieldObject with identifier "1"s 
    #   recognised status will be manually set to true to ensure that a 
    #   recognised VisualSpatialFieldObject is being moved (its recognised 
    #   status will be set to false after first move).
    # 
    # - Expected VisualSpatialField state after first move:
    #	
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      | 1(A) | 2(B) |      |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |0(SLF)|   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #
    # - Expected VisualSpatialField state after second move
    #	
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      | 2(B) | 1(A) |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |0(SLF)|   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #
    # ==================
    # === Scenario 8 ===
    # ==================
    #
    # - As scenario 2 but VisualSpatialFieldObject with identifier "1" will be
    #   unrecognised and will not be made "recognised" after first move
    #
    # ===================
    # === Scenario 14 ===
    # ===================
    # 
    # - As scenario 8 but expected VisualSpatialField state after each move is 
    #  different:
    #  
    # After first move
    # 
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |1(SLF)| 2(B) |      |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |      |   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #
    # After second move
    #	
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      | 2(B) |1(SLF)|      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |      |   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    elsif (scenario == 2 || scenario == 8 || scenario == 14)
      
      ######################
      ##### FIRST MOVE #####
      ######################
      
      # Construct move
      move = ArrayList.new()
      move.add(ItemSquarePattern.new("1", 1, 1))
      move.add(ItemSquarePattern.new("1", 1, 2))
      move_sequence = ArrayList.new()
      move_sequence.add(move)
      
      # Set relevant timing parameters.
      time_move_requested = time
      pickup_time = time_move_requested + model._timeToAccessVisualSpatialField
      putdown_time = pickup_time + model._timeToMoveVisualSpatialFieldObject
      expected_attention_clock = putdown_time
      
      # Set terminus for VisualSpatialFieldObject being moved on (1, 1)
      expected_visual_spatial_field_data[1][1][0][4] = pickup_time
      
      # New VisualSpatialFieldObject representing an empty square should be 
      # added to (1, 1) when VisualSpatialFieldObject being moved is picked up.
      expected_visual_spatial_field_data[1][1].push([
        nil,
        Scene.getEmptySquareToken(),
        false,
        pickup_time,
        pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # VisualSpatialFieldObjects in fixation field of view around (1, 1) should
      # have their termini refreshed.
      if scenario == 14 then expected_visual_spatial_field_data[2][0][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan end
      expected_visual_spatial_field_data[2][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[0][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][0][4] = pickup_time + model._recognisedVisualSpatialFieldObjectLifespan
    
      # Set terminus for empty square on (1, 2)
      expected_visual_spatial_field_data[1][2][0][4] = putdown_time
      
      # VisualSpatialFieldObject being moved should be added to (1, 2) at put 
      # down time.  If the VisualSpatialFieldObject being moved was previously
      # recognised it should now be unrecognised.
      expected_visual_spatial_field_data[1][2].push([
        "1",
        (scenario == 14 ? Scene.getCreatorToken() : "A"),
        false,
        putdown_time,
        putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # VisualSpatialFieldObjects in fixation field of view around (1, 2) should
      # have their termini refreshed.
      expected_visual_spatial_field_data[1][1][1][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[0][2][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][0][4] = putdown_time + model._recognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      move_visual_spatial_field_object_test(
        model,
        move_sequence,
        time_move_requested,
        expected_visual_spatial_field_data,
        expected_attention_clock,
        putdown_time,
        scenario.to_s + ".1"
      )
      
      #######################
      ##### SECOND MOVE #####
      #######################
      
      if (scenario == 2)
        # Make VisualSpatialFieldObject with identifier "1" recognised again.  
        # Since the recognised history of a VisualSpatialFieldObject is a 
        # HistoryTreeMap and VisualSpatialFieldObject with identifier "1"s 
        # recognised status is updated at the current value of "putdown_time", its
        # not possible to overwrite this entry.  Best solution currently is to add
        # an entry just after the previous one stating that the 
        # VisualSpatialFieldObject is recognised.
        rec_history = recognised_history_field.value(vsf.get(1).get(2).get(1))
        rec_history.put(putdown_time + 1, true)

        # Set expected recognised status and terminus of VisualSpatialFieldObject 
        # with identifier 0
        expected_visual_spatial_field_data[1][2][1][2] = true
        expected_visual_spatial_field_data[1][2][1][4] = model._recognisedVisualSpatialFieldObjectLifespan
      end
      
      # Construct move
      move = ArrayList.new
      move.add(ItemSquarePattern.new("1", 1, 2))
      move.add(ItemSquarePattern.new("1", 3, 2))
      move_sequence = ArrayList.new
      move_sequence.add(move)
      
      # Set relevant timing parameters
      time_move_requested = putdown_time + 1
      pickup_time = time_move_requested + model._timeToAccessVisualSpatialField
      putdown_time = pickup_time + model._timeToMoveVisualSpatialFieldObject
      expected_attention_clock = putdown_time
      
      # Set terminus for VisualSpatialFieldObject being moved on (1, 2)
      expected_visual_spatial_field_data[1][2][1][4] = pickup_time
      
      # New VisualSpatialFieldObject representing an empty square should be 
      # added to (1, 2) when VisualSpatialFieldObject being moved is picked up.
      expected_visual_spatial_field_data[1][2].push([
        nil,
        Scene.getEmptySquareToken(),
        false,
        pickup_time,
        pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # VisualSpatialFieldObjects in fixation field of view around (1, 2) should
      # have their termini refreshed.
      expected_visual_spatial_field_data[1][1][1][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[0][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][0][4] = pickup_time + model._recognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][3][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][3][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
    
      # Set terminus for empty square on (3, 2)
      expected_visual_spatial_field_data[3][2][0][4] = putdown_time
      
      # Add VisualSpatialFieldObject being moved to (3, 2)
      expected_visual_spatial_field_data[3][2].push([
        "1",
        (scenario == 14 ? Scene.getCreatorToken() : "A"),
        false,
        putdown_time,
        putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # VisualSpatialFieldObjects in fixation field of view around (3, 2) should
      # have their termini refreshed.
      expected_visual_spatial_field_data[2][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][0][4] = putdown_time + model._recognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[4][2][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      move_visual_spatial_field_object_test(
        model,
        move_sequence,
        time_move_requested,
        expected_visual_spatial_field_data,
        expected_attention_clock,
        putdown_time,
        scenario.to_s + ".2"
      )
      
    ############################################################################
    # ==================
    # === Scenario 3 ===
    # ==================
    # 
    # - Move a recognised VisualSpatialFieldObject to coordinates that contains
    #   a VisualSpatialFieldObject representing the creator of the 
    #   VisualSpatialField.
    # - Move a recognised VisualSpatialFieldObject from coordinates that 
    #   contains a VisualSpatialFieldObject representing the creator of the 
    #   VisualSpatialField.
    # - Move(s) performed:
    #   + VisualSpatialFieldObject with identifier "1" moved from (1, 1) to 
    #     (2, 0).
    #   + VisualSpatialFieldObject with identifier "1" moved from (2, 0) to 
    #     (3, 2).
    # - In between moves, VisualSpatialFieldObject with identifier "1"s 
    #   recognised status will be manually set to true.
    # 
    # - Expected VisualSpatialField state after first move:
    # 
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      | 2(B) |      |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   | 1(A) |   ~      ~
    #                  |0(SLF)|
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #     
    # - Expected VisualSpatialField state after second move:
    #
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      | 2(B) | 1(A) |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |0(SLF)|   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #
    # ==================
    # === Scenario 9 ===
    # ==================
    #
    # - As scenario 3 but VisualSpatialFieldObject with identifier "1" will be
    #   unrecognised and will not be made "recognised" after first move
    elsif (scenario == 3 || scenario == 9)
      
      ##############################
      ##### FIRST PART OF MOVE #####
      ##############################
      
      # Construct move.
      move = ArrayList.new
      move.add(ItemSquarePattern.new("1", 1, 1))
      move.add(ItemSquarePattern.new("1", 2, 0))
      move_sequence = ArrayList.new
      move_sequence.add(move)
      
      # Set relevant timing parameters.
      time_move_requested = time
      pickup_time = time_move_requested + model._timeToAccessVisualSpatialField
      putdown_time = pickup_time + model._timeToMoveVisualSpatialFieldObject
      expected_attention_clock = putdown_time
      
      # Set terminus for VisualSpatialFieldObject with identifier "1" on (1, 1)
      expected_visual_spatial_field_data[1][1][0][4] = pickup_time
      
      # New VisualSpatialFieldObject representing an empty square should be 
      # added to (1, 1) when VisualSpatialFieldObject with identifier "1" is 
      # picked up.
      expected_visual_spatial_field_data[1][1].push([
        nil,
        Scene.getEmptySquareToken(),
        false,
        pickup_time,
        pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # Termini of VisualSpatialFieldObjects on coordinates around (1, 1) within
      # fixation field of view should be refreshed.
      expected_visual_spatial_field_data[2][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan 
      expected_visual_spatial_field_data[0][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan 
      expected_visual_spatial_field_data[1][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan 
      expected_visual_spatial_field_data[2][2][0][4] = pickup_time + model._recognisedVisualSpatialFieldObjectLifespan 
      
      # VisualSpatialFieldObject with identifier "1" should be added to (2, 0) 
      # at first putdown time.  Should no longer be recognised.
      expected_visual_spatial_field_data[2][0].push([
        "1",
        "A",
        false,
        putdown_time,
        putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan 
      ])
    
      # VisualSpatialFieldObject representing the creator should not be modified
      # in any way.  Just refresh the termini of VisualSpatialFieldObjects 
      # around (2, 0) within fixation field of view.
      expected_visual_spatial_field_data[1][1][1][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
    
      move_visual_spatial_field_object_test(
        model,
        move_sequence,
        time_move_requested,
        expected_visual_spatial_field_data,
        expected_attention_clock,
        putdown_time,
        scenario.to_s + ".1"
      )
      
      ###############################
      ##### SECOND PART OF MOVE #####
      ###############################
      
      if (scenario == 3)
        # Make VisualSpatialFieldObject with identifier "1" recognised again.  
        # Since the recognised history of a VisualSpatialFieldObject is a 
        # HistoryTreeMap and VisualSpatialFieldObject with identifier "1"s 
        # recognised status is updated at the current value of "putdown_time", its
        # not possible to overwrite this entry.  Best solution currently is to add
        # an entry just after the previous one stating that the 
        # VisualSpatialFieldObject is recognised.
        rec_history = recognised_history_field.value(vsf.get(2).get(0).get(1))
        rec_history.put(putdown_time + 1, true)

        # Set expected recognised status and terminus of VisualSpatialFieldObject 
        # with identifier 0
        expected_visual_spatial_field_data[2][0][1][2] = true
        expected_visual_spatial_field_data[2][0][1][4] = model._recognisedVisualSpatialFieldObjectLifespan
      end
      
      # Construct move.
      move = ArrayList.new
      move.add(ItemSquarePattern.new("1", 2, 0))
      move.add(ItemSquarePattern.new("1", 3, 2))
      move_sequence = ArrayList.new
      move_sequence.add(move)
      
      # Set relevant time parameters.
      time_move_requested = putdown_time + 1
      pickup_time = time_move_requested + model._timeToAccessVisualSpatialField
      putdown_time = pickup_time + model._timeToMoveVisualSpatialFieldObject
      expected_attention_clock = putdown_time
      
      # Set terminus for VisualSpatialObject with identifier "1" on (2, 0)
      expected_visual_spatial_field_data[2][0][1][4] = pickup_time
      
      # VisualSpatialFieldObject representing the creator should not be modified
      # in any way.  Just refresh the termini of VisualSpatialFieldObjects 
      # around (2, 0) within fixation field of view.
      expected_visual_spatial_field_data[1][1][1][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      # Set terminus for VisualSpatialFieldObject representing an empty square 
      # on (3, 2)
      expected_visual_spatial_field_data[3][2][0][4] = putdown_time
      
      # Add VisualSpatialFieldObject with identifier "1" to (3, 2)
      expected_visual_spatial_field_data[3][2].push([
        "1",
        "A",
        false,
        putdown_time,
        putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # Termini of VisualSpatialFieldObjects on coordinates around (3, 2) within
      # fixation field of view should be refreshed.
      expected_visual_spatial_field_data[2][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan 
      expected_visual_spatial_field_data[3][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan 
      expected_visual_spatial_field_data[2][2][0][4] = putdown_time + model._recognisedVisualSpatialFieldObjectLifespan 
      expected_visual_spatial_field_data[4][2][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
    
      move_visual_spatial_field_object_test(
        model,
        move_sequence,
        time_move_requested,
        expected_visual_spatial_field_data,
        expected_attention_clock,
        putdown_time,
        scenario.to_s + ".2"
      )
      
    ############################################################################
    #	==================
    # === Scenario 4 ===
    # ==================
    # 
    #	- Move recognised VisualSpatialFieldObject to coordinates that contains a 
    #	  live, recognised VisualSpatialFieldObject on it.
    #	- Move recognised VisualSpatialFieldObject from coordinates that contains 
    #	  a live, recognised VisualSpatialFieldObject on it.
    # - Move(s) performed:
    #   + VisualSpatialFieldObject with identifier "1" moved from (1, 1) to 
    #     (2, 2).
    #   + VisualSpatialFieldObject with identifier "1" moved from (2, 2) to 
    #     (3, 2).
    # - In between moves, VisualSpatialFieldObject with identifier "1"s 
    #   recognised status will be manually set to true.
    #	
    #	- Expected VisualSpatialField state after first move
    #   
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      | 1(A) |      |      |
    #    |      |      | 2(B) |      |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |0(SLF)|   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #       
    # - Expected VisualSpatialField state after second move:
    #
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      | 2(B) | 1(A) |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |0(SLF)|   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #
    # ===================
    # === Scenario 10 ===
    # ===================
    #
    # - As scenario 4 but VisualSpatialFieldObject with identifier "1" will be
    #   unrecognised and will not be made "recognised" after first move
    #
    # ===================
    # === Scenario 15 ===
    # ===================
    # 
    # - As scenario 10 but expected VisualSpatialField state after each move is 
    #  different:
    #  
    # After first move
    # 
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      |1(SLF)|      |      |
    #    |      |      | 2(B) |      |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |      |   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #
    # After second move
    #	
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      | 2(B) |1(SLF)|      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |      |   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    elsif(scenario == 4 || scenario == 10 || scenario == 15)
      
      ##############################
      ##### FIRST PART OF MOVE #####
      ##############################
      
      # Construct move
      move = ArrayList.new
      move.add(ItemSquarePattern.new("1", 1, 1))
      move.add(ItemSquarePattern.new("1", 2, 2))
      move_sequence = ArrayList.new
      move_sequence.add(move)
      
      # Set relevant time parameters
      time_move_requested = time
      pickup_time = time_move_requested + model._timeToAccessVisualSpatialField
      putdown_time = pickup_time + model._timeToMoveVisualSpatialFieldObject
      expected_attention_clock = putdown_time
      
      # Set terminus for VisualSpatialFieldObject being moved on (1, 1)
      expected_visual_spatial_field_data[1][1][0][4] = pickup_time
      
      # New VisualSpatialFieldObject representing an empty square should be 
      # added to (1, 1) when VisualSpatialFieldObject being moved is picked up.
      expected_visual_spatial_field_data[1][1].push([
        nil,
        Scene.getEmptySquareToken(),
        false,
        pickup_time,
        pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # Refresh termini of VisualSpatialFieldObjects around (1, 1) that fall 
      # within fixation field of view.
      if scenario == 15 then expected_visual_spatial_field_data[2][0][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan end
      expected_visual_spatial_field_data[2][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[0][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][0][4] = pickup_time + model._recognisedVisualSpatialFieldObjectLifespan
      
      # VisualSpatialFieldObject being moved should be added to (2, 2)  at first 
      # put down time.  If the VisualSpatialFieldObject being moved was 
      # previously recognised it will now be unrecognised.
      expected_visual_spatial_field_data[2][2].push([
        "1",
        (scenario == 15 ? Scene.getCreatorToken() : "A"),
        false,
        putdown_time,
        putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # Update terminus for VisualSpatialFieldObject with identifier "2" on 
      # (2, 2) since the coordinates have had attention focused on them and the 
      # VisualSpatialFieldObject is alive when the VisualSpatialFieldObject 
      # being moved is put down.
      expected_visual_spatial_field_data[2][2][0][4] = putdown_time + model._recognisedVisualSpatialFieldObjectLifespan
      
      # Refresh termini of VisualSpatialFieldObjects around (2, 2) that fall 
      # within fixation field of view.
      expected_visual_spatial_field_data[1][1][1][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][2][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][2][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      move_visual_spatial_field_object_test(
        model,
        move_sequence,
        time_move_requested,
        expected_visual_spatial_field_data,
        expected_attention_clock,
        putdown_time,
        scenario.to_s + ".1"
      )
      
      ###############################
      ##### SECOND PART OF MOVE #####
      ###############################
      
      if (scenario == 4)
        # Make VisualSpatialFieldObject with identifier "1" recognised again.  
        # Since the recognised history of a VisualSpatialFieldObject is a 
        # HistoryTreeMap and VisualSpatialFieldObject with identifier "1"s 
        # recognised status is updated at the current value of "putdown_time", its
        # not possible to overwrite this entry.  Best solution currently is to add
        # an entry just after the previous one stating that the 
        # VisualSpatialFieldObject is recognised.
        rec_history = recognised_history_field.value(vsf.get(2).get(2).get(1))
        rec_history.put(putdown_time + 1, true)
      
        # Update recognised status and terminus of VisualSpatialFieldObject with 
        # identifier "1" on (2, 2)
        expected_visual_spatial_field_data[2][2][1][2] = true
        expected_visual_spatial_field_data[2][2][1][4] = putdown_time + model._recognisedVisualSpatialFieldObjectLifespan
      end
      
      # Construct move
      move = ArrayList.new
      move.add(ItemSquarePattern.new("1", 2, 2))
      move.add(ItemSquarePattern.new("1", 3, 2))
      move_sequence = ArrayList.new
      move_sequence.add(move)
      
      # Set relevant timing parameters
      time_move_requested = putdown_time + 1
      pickup_time = time_move_requested + model._timeToAccessVisualSpatialField
      putdown_time = pickup_time + model._timeToMoveVisualSpatialFieldObject
      expected_attention_clock = putdown_time
      
      # Set terminus for VisualSpatialFieldObject being moved on (2, 2)
      expected_visual_spatial_field_data[2][2][1][4] = pickup_time
      
      # Refresh terminus for VisualSpatialFieldObject with identifier "2" on 
      # (2, 2)
      expected_visual_spatial_field_data[2][2][0][4] = pickup_time + model._recognisedVisualSpatialFieldObjectLifespan
      
      # Refresh termini of VisualSpatialFieldObjects around (2, 2) that fall 
      # within fixation field of view.
      expected_visual_spatial_field_data[1][1][1][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][3][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][3][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][3][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      # Set terminus for VisualSpatialFieldObject representing an empty square 
      # on (3, 2)
      expected_visual_spatial_field_data[3][2][0][4] = putdown_time
      
      # Add VisualSpatialFieldObject being moved to (3, 2)
      expected_visual_spatial_field_data[3][2].push([
        "1",
        (scenario == 15 ? Scene.getCreatorToken() : "A"),
        false,
        putdown_time,
        putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # Refresh termini of VisualSpatialFieldObjects around (3, 2) that fall 
      # within fixation field of view.
      expected_visual_spatial_field_data[2][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][0][4] = putdown_time + model._recognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[4][2][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      move_visual_spatial_field_object_test(
        model,
        move_sequence,
        time_move_requested,
        expected_visual_spatial_field_data,
        expected_attention_clock,
        putdown_time,
        scenario.to_s + ".2"
      )
    
    ############################################################################
    #	==================
    # === Scenario 5 ===
    # ==================
    # 
    #	- Move recognised VisualSpatialFieldObject to coordinates containing a 
    #	  live, unrecognised VisualSpatialFieldObject.
    #	- Move recognised VisualSpatialFieldObject from coordinates containing a 
    #	  live, unrecognised VisualSpatialFieldObject.
    # - Move(s) performed:
    #   + VisualSpatialFieldObject with identifier "1" moved from (1, 1) to 
    #     (1, 3).
    #   + VisualSpatialFieldObject with identifier "1" moved from (1, 3) to 
    #     (3, 2).
    # - In between moves, VisualSpatialFieldObject with identifier "1"s 
    #   recognised status will be manually set to true.
    #	
    #	- Expected VisualSpatialField state after first move:
    #   
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 1(A) |      |      |   ~
    #           | 3(c) |      |      |
    #    ------------------------------------
    # 2  |      |      | 2(B) |      |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |0(SLF)|   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #       
    # - Expected VisualSpatialField state after second move:
    #
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      | 2(B) | 1(A) |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |0(SLF)|   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #
    # ===================
    # === Scenario 11 ===
    # ===================
    #
    # - As scenario 5 but VisualSpatialFieldObject with identifier "1" will be
    #   unrecognised and will not be made "recognised" after first move
    #
    # ===================
    # === Scenario 16 ===
    # ===================
    # 
    # - As scenario 11 but expected VisualSpatialField state after each move is 
    #  different:
    #  
    # After first move
    # 
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   |1(SLF)|      |      |   ~
    #           | 3(c) |      |      |
    #    ------------------------------------
    # 2  |      |      | 2(B) |      |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |      |   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #
    # After second move
    #	
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      | 2(B) |1(SLF)|      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |      |   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    elsif(scenario == 5 || scenario == 11 || scenario == 16)
      
      ##############################
      ##### FIRST PART OF MOVE #####
      ##############################
      
      # Construct move
      move = ArrayList.new
      move.add(ItemSquarePattern.new("1", 1, 1))
      move.add(ItemSquarePattern.new("1", 1, 3))
      move_sequence = ArrayList.new
      move_sequence.add(move)
      
      # Set relevant time parameters
      time_move_requested = time
      pickup_time = time_move_requested + model._timeToAccessVisualSpatialField
      putdown_time = pickup_time + model._timeToMoveVisualSpatialFieldObject
      expected_attention_clock = putdown_time
      
      # Set terminus for VisualSpatialFieldObject being moved on (1, 1)
      expected_visual_spatial_field_data[1][1][0][4] = pickup_time
      
      # New VisualSpatialFieldObject representing an empty square should be 
      # added to (1, 1) when VisualSpatialFieldObject being moved is picked up.
      expected_visual_spatial_field_data[1][1].push([
        nil,
        Scene.getEmptySquareToken(),
        false,
        pickup_time,
        pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # Refresh termini of VisualSpatialFieldObjects on coordinates around 
      # (1, 1) that fall within the fixation field of view.
      if scenario == 16 then expected_visual_spatial_field_data[2][0][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan end
      expected_visual_spatial_field_data[2][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[0][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][0][4] = pickup_time + model._recognisedVisualSpatialFieldObjectLifespan
      
      # VisualSpatialFieldObject being moved should be added to (1, 3) at first 
      # put down time.  If the VisualSpatialFieldObject being moved was 
      # previously recognised, it should now be unrecognised.
      expected_visual_spatial_field_data[1][3].push([
        "1",
        (scenario == 16 ? Scene.getCreatorToken() : "A"),
        false,
        putdown_time,
        putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # Update terminus for VisualSpatialFieldObject with identifier "3" on 
      # (1, 3) since the coordinates have had attention focused on them and the 
      # VisualSpatialFieldObject is alive when the VisualSpatialFieldObject 
      # being moved is put down.
      expected_visual_spatial_field_data[1][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      # Refresh termini of VisualSpatialFieldObjects on coordinates around 
      # (1, 3) that fall within the fixation field of view.
      expected_visual_spatial_field_data[0][2][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][2][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][0][4] = putdown_time + model._recognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][4][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      move_visual_spatial_field_object_test(
        model,
        move_sequence,
        time_move_requested,
        expected_visual_spatial_field_data,
        expected_attention_clock,
        putdown_time,
        scenario.to_s + ".1"
      )
      
      ###############################
      ##### SECOND PART OF MOVE #####
      ###############################
      
      if (scenario == 5)
        # Make VisualSpatialFieldObject with identifier "1" recognised again.  
        # Since the recognised history of a VisualSpatialFieldObject is a 
        # HistoryTreeMap and VisualSpatialFieldObject with identifier "1"s 
        # recognised status is updated at the current value of "putdown_time", its
        # not possible to overwrite this entry.  Best solution currently is to add
        # an entry just after the previous one stating that the 
        # VisualSpatialFieldObject is recognised.
        rec_history = recognised_history_field.value(vsf.get(1).get(3).get(1))
        rec_history.put(putdown_time + 1, true)

        # Update recognised status and terminus of VisualSpatialFieldObject with 
        # identifier "1" on (1, 3)
        expected_visual_spatial_field_data[1][3][1][2] = true
        expected_visual_spatial_field_data[1][3][1][4] = putdown_time + model._recognisedVisualSpatialFieldObjectLifespan
      end
      
      # Construct move
      move = ArrayList.new
      move.add(ItemSquarePattern.new("1", 1, 3))
      move.add(ItemSquarePattern.new("1", 3, 2))
      move_sequence = ArrayList.new
      move_sequence.add(move)
      
      # Set relevant timing parameters
      time_move_requested = putdown_time + 1
      pickup_time = time_move_requested + model._timeToAccessVisualSpatialField
      putdown_time = pickup_time + model._timeToMoveVisualSpatialFieldObject
      expected_attention_clock = putdown_time
      
      # Set terminus for VisualSpatialFieldObject being moved on (1, 3)
      expected_visual_spatial_field_data[1][3][1][4] = pickup_time
      
      # Refresh terminus for VisualSpatialFieldObject with identifier "3" on 
      # (1, 3)
      expected_visual_spatial_field_data[1][3][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      # Refresh termini of VisualSpatialFieldObjects on coordinates around 
      # (1, 3) that fall within the fixation field of view.
      expected_visual_spatial_field_data[0][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][0][4] = pickup_time + model._recognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][3][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][4][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      # Set terminus for VisualSpatialFieldObject that represents an empty 
      # square object on (3, 2)
      expected_visual_spatial_field_data[3][2][0][4] = putdown_time
      
      # Add VisualSpatialFieldObject being moved to (3, 2)
      expected_visual_spatial_field_data[3][2].push([
        "1",
        (scenario == 16 ? Scene.getCreatorToken() : "A"),
        false,
        putdown_time,
        putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # Refresh termini of VisualSpatialFieldObjects on coordinates around 
      # (3, 2) that fall within the fixation field of view.
      expected_visual_spatial_field_data[2][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][0][4] = putdown_time + model._recognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[4][2][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      move_visual_spatial_field_object_test(
        model,
        move_sequence,
        time_move_requested,
        expected_visual_spatial_field_data,
        expected_attention_clock,
        putdown_time,
        scenario.to_s + ".2"
      )
      
    ############################################################################
    # ===================
    # === Scenario 6 ====
    # ===================
    # 
    # - Specify a move sequence that contains a sequence of moves for two 
    #   VisualSpatialFieldObjects:
    #   1. Move a recognised VisualSpatialFieldObject to coordinates not 
    #      represented in the VisualSpatialField and then another move 
    #      afterwards for the same recognised VisualSpatialFieldObject to 
    #      coordinates represented in the VisualSpatialField.
    #   2. Move another VisualSpatialFieldObject (any) to coordinates 
    #      represented in the VisualSpatialField.  
    #   
    #	- Move(s) performed:
    #	
    #   + For VisualSpatialFieldObject with identifier "1":
    #     > Move from (1, 1) to (0, 5).
    #     > Move from (0, 5) to (3, 2).
    #     > Move from (0, 5) to (1, 2).
    #     
    #   + For VisualSpatialFieldObject with identifier "2":
    #     > Move from (2, 2) to (2, 3)
    #   
    #	- Expected VisualSpatialField state after first move:
    #   
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3         | 3(c) |      |      |
    #    ------------------------------------
    # 2  |      |      | 2(B) |      |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |0(SLF)|   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    #       
    # - Expected VisualSpatialField state after second move:
    #
    #                  --------
    # 4     ~      ~   |      |   ~      ~
    #           ----------------------
    # 3     ~   | 3(c) |      |      |   ~
    #    ------------------------------------
    # 2  |      |      |      | 2(B) |      |
    #    ------------------------------------
    # 1     ~   |      |      |      |   ~
    #           ----------------------
    # 0     ~      ~   |0(SLF)|   ~      ~
    #                  --------
    #       0      1      2       3      4     COORDINATES
    elsif(scenario == 6 || scenario == 12 || scenario == 17)
      # Construct move
      object_with_id_1_moves = ArrayList.new
      object_with_id_1_moves.add(ItemSquarePattern.new("1", 1, 1))
      object_with_id_1_moves.add(ItemSquarePattern.new("1", 0, 5))
      object_with_id_1_moves.add(ItemSquarePattern.new("1", 1, 2))
      
      object_with_id_2_moves = ArrayList.new
      object_with_id_2_moves.add(ItemSquarePattern.new("2", 2, 2))
      object_with_id_2_moves.add(ItemSquarePattern.new("2", 3, 2))
      
      move_sequence = ArrayList.new
      move_sequence.add(object_with_id_1_moves)
      move_sequence.add(object_with_id_2_moves)
      
      #########################################################
      ### VisualSpatialFieldObject WITH IDENTIFIER "1" MOVE ###
      #########################################################
      
      # Set relevant time parameters
      time_move_requested = time
      pickup_time = time_move_requested + model._timeToAccessVisualSpatialField
      putdown_time = pickup_time + model._timeToMoveVisualSpatialFieldObject
      
      # Set terminus for VisualSpatialFieldObject being moved on (1, 1)
      expected_visual_spatial_field_data[1][1][0][4] = pickup_time
      
      # New VisualSpatialFieldObject representing an empty square should be 
      # added to (1, 1) when VisualSpatialFieldObject being moved is picked up.
      expected_visual_spatial_field_data[1][1].push([
        nil,
        Scene.getEmptySquareToken(),
        false,
        pickup_time,
        pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # Refresh termini of VisualSpatialFieldObjects on coordinates around 
      # (1, 1) that fall within the fixation field of view.
      if scenario == 17 then expected_visual_spatial_field_data[2][0][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan end
      expected_visual_spatial_field_data[2][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[0][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][0][4] = pickup_time + model._recognisedVisualSpatialFieldObjectLifespan
      
      # Nothing should happen now since the coordinates moved to are outside of
      # the coordinates represented by the VisualSpatialField.
    
      #########################################################
      ### VisualSpatialFieldObject WITH IDENTIFIER "2" MOVE ###
      #########################################################
      
      pickup_time = putdown_time
      putdown_time = pickup_time + model._timeToMoveVisualSpatialFieldObject
      expected_attention_clock = putdown_time
      
      # Set terminus for VisualSpatialFieldObject being moved on (2, 2)
      expected_visual_spatial_field_data[2][2][0][4] = pickup_time
      
      # VisualSpatialFieldObject representing empty square should be placed on
      # (2, 2) when VisualSpatialFieldObject being moved is picked up.
      expected_visual_spatial_field_data[2][2].push([
        nil,
        Scene.getEmptySquareToken,
        false,
        pickup_time,
        pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
      
      # Refresh termini of VisualSpatialFieldObjects on coordinates around 
      # (2, 2) that fall within the fixation field of view.
      expected_visual_spatial_field_data[1][1][1][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][1][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][2][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[1][3][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][3][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][3][0][4] = pickup_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      # Add the VisualSpatialFieldObject being moved to (3, 2).  It will now be
      # unrecognised.
      expected_visual_spatial_field_data[3][2].push([
        "2",
        "B",
        false,
        putdown_time,
        putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      ])
    
      # Terminus of VisualSpatialFieldObject representing an empty square on
      # (3, 2) will be set.
      expected_visual_spatial_field_data[3][2][0][4] = putdown_time
      
      # Refresh termini of VisualSpatialFieldObjects on coordinates around 
      # (3, 2) that fall within the fixation field of view.
      expected_visual_spatial_field_data[2][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][1][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][2][1][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[4][2][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[2][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      expected_visual_spatial_field_data[3][3][0][4] = putdown_time + model._unrecognisedVisualSpatialFieldObjectLifespan
      
      move_visual_spatial_field_object_test(
        model,
        move_sequence,
        time_move_requested,
        expected_visual_spatial_field_data,
        expected_attention_clock,
        putdown_time,
        scenario.to_s + ".1"
      )
    
    ############################################################################
    # Checks that an exception is thrown and the VisualSpatialField is reset 
    # correctly if a VisualSpatialFieldObject move sequence contains moves for 
    # two VisualSpatialFieldObjects and the moves for the first 
    # VisualSpatialFieldObject are valid but only the initial location of the 
    # second VisualSpatialFieldObject to move is specified.  Specifying a legal
    # movement for the first VisualSpatialFieldObject will allow the test to
    # check that the VisualSpatialField is reverted to its state before any
    # moves were applied correctly.
    elsif scenario == 18
      
      # Construct move
      object_with_id_1_moves = ArrayList.new
      object_with_id_1_moves.add(ItemSquarePattern.new("1", 1, 1))
      object_with_id_1_moves.add(ItemSquarePattern.new("1", 1, 2))
      
      object_with_id_2_moves = ArrayList.new
      object_with_id_2_moves.add(ItemSquarePattern.new("2", 2, 2))
      
      move_sequence = ArrayList.new
      move_sequence.add(object_with_id_1_moves)
      move_sequence.add(object_with_id_2_moves)
      
      expected_attention_clock = model.getAttentionClock()
      exception_thrown = false
      begin
        model.moveObjectsInVisualSpatialField(move_sequence, time)
      rescue
        exception_thrown = true
      end
      
      assert_true(
        exception_thrown, 
        "occurred when checking if an exception is thrown in scenario " + 
        scenario.to_s
      )
      
      check_visual_spatial_field_against_expected(
        vsfs_field.value(model).lastEntry().getValue(), 
        expected_visual_spatial_field_data,
        time + 1000,
        "in scenario " + scenario.to_s
      )
      
      assert_equal(
        expected_attention_clock,
        model.getAttentionClock(),
        "occured when checking the attention clock in scenario " + scenario.to_s
      ) 
    
    ############################################################################
    # Checks that an exception is thrown and the VisualSpatialField is reset 
    # correctly if a VisualSpatialFieldObject move sequence contains moves for 
    # three VisualSpatialFieldObjects and the moves for the first 
    # VisualSpatialFieldObject are valid but VisualSpatialFieldObject movement 
    # in the second move sequence is not serial.  Specifying a legal movement 
    # for the first VisualSpatialFieldObject will allow the test to check that 
    # the VisualSpatialField is reverted to its state before any moves were 
    # applied correctly.
    elsif scenario == 19
      
      # Construct move
      object_with_id_1_moves = ArrayList.new
      object_with_id_1_moves.add(ItemSquarePattern.new("1", 1, 1))
      object_with_id_1_moves.add(ItemSquarePattern.new("1", 1, 2))
      
      object_with_id_2_and_3_moves = ArrayList.new
      object_with_id_2_and_3_moves.add(ItemSquarePattern.new("2", 2, 2))
      object_with_id_2_and_3_moves.add(ItemSquarePattern.new("3", 1, 3))
      
      move_sequence = ArrayList.new
      move_sequence.add(object_with_id_1_moves)
      move_sequence.add(object_with_id_2_and_3_moves)
      
      expected_attention_clock = model.getAttentionClock()
      exception_thrown = false
      begin
        model.moveObjectsInVisualSpatialField(move_sequence, time)
      rescue
        exception_thrown = true
      end
      
      assert_true(
        exception_thrown, 
        "occurred when checking if an exception is thrown in scenario " + 
        scenario.to_s
      )
      
      check_visual_spatial_field_against_expected(
        vsfs_field.value(model).lastEntry().getValue(), 
        expected_visual_spatial_field_data,
        time + 1000,
        "in scenario " + scenario.to_s
      )
      
      assert_equal(
        expected_attention_clock,
        model.getAttentionClock(),
        "occured when checking the attention clock in scenario " + scenario.to_s
      )
      
    ############################################################################
    # Checks that an exception is thrown and the VisualSpatialField is reset 
    # correctly if a VisualSpatialFieldObject move sequence contains moves for 
    # two VisualSpatialFieldObjects and the moves for the first 
    # VisualSpatialFieldObject are valid but the initial location of the second
    # VisualSpatialFieldObject to move is incorrect.  Specifying a legal
    # movement for the first VisualSpatialFieldObject will allow the test to
    # check that the VisualSpatialField is reverted to its state before any
    # moves were applied correctly.
    elsif scenario == 20
      
      # Construct move
      object_with_id_1_moves = ArrayList.new
      object_with_id_1_moves.add(ItemSquarePattern.new("1", 1, 1))
      object_with_id_1_moves.add(ItemSquarePattern.new("1", 1, 2))
      
      object_with_id_2_but_incorrect_initial_location_moves = ArrayList.new
      object_with_id_2_but_incorrect_initial_location_moves.add(ItemSquarePattern.new("2", 1, 3))
      object_with_id_2_but_incorrect_initial_location_moves.add(ItemSquarePattern.new("2", 2, 2))
      
      move_sequence = ArrayList.new
      move_sequence.add(object_with_id_1_moves)
      move_sequence.add(object_with_id_2_but_incorrect_initial_location_moves)
      
      expected_attention_clock = model.getAttentionClock()
      exception_thrown = false
      begin
        model.moveObjectsInVisualSpatialField(move_sequence, time)
      rescue
        exception_thrown = true
      end
      
      assert_true(
        exception_thrown, 
        "occurred when checking if an exception is thrown in scenario " + 
        scenario.to_s
      )
      
      check_visual_spatial_field_against_expected(
        vsfs_field.value(model).lastEntry().getValue(), 
        expected_visual_spatial_field_data,
        time + 1000,
        "in scenario " + scenario.to_s
      )
      
      assert_equal(
        expected_attention_clock,
        model.getAttentionClock(),
        "occured when checking the attention clock in scenario " + scenario.to_s
      )
    end 
  end 
end



################################################################################
################################################################################
############################## TEST HELPER METHODS #############################
################################################################################
################################################################################

def move_visual_spatial_field_object_test(model, move_sequence, time_move_should_be_performed, expected_visual_spatial_field_data, expected_attention_clock, time_to_check_visual_spatial_field_at, scenario)
  
  chrest_visual_spatial_fields_history = Chrest.java_class.declared_field("_visualSpatialFields")
  chrest_visual_spatial_fields_history.accessible = true
  
  model.moveObjectsInVisualSpatialField(move_sequence, time_move_should_be_performed)
      
  check_visual_spatial_field_against_expected(
    chrest_visual_spatial_fields_history.value(model).floorEntry(time_to_check_visual_spatial_field_at.to_java(:int)).getValue(),
    expected_visual_spatial_field_data,
    time_to_check_visual_spatial_field_at,
    "when checking the state of visual-spatial field in scenario " + scenario.to_s
  )
      
  assert_equal(
    expected_attention_clock, 
    model.getAttentionClock(), 
    "occurred when checking the time that the attention of the CHREST model " +
    "associated with the visual-spatial field will be free in scenario " +
    scenario.to_s
  )
end


  
  #####################
  ##### TEST BODY #####
  #####################
  
#  # First, invoke "scheduleOrMakeNextFixation" and, given the scene provided
#  # and the time the "scheduleOrMakeNextFixation" is invoked, this should 
#  # successfully schedule a ChessDomain.fixation.CentralFixation at the time
#  # the method is invoked plus 150ms.
#  time += 5
#  result = model.scheduleOrMakeNextFixation(chess_board, time, false)
#  fixations_to_make = model.getFixationsToMake(time)
#  
#  assert_equal(1, result.size())
#  assert_equal(result.get(0), FixationResult::DELIBERATION_SCHEDULED)
#  assert_equal(model.getAttentionClock(), time + 150)
#  assert_equal(1, fixations_to_make.size())
#  assert_equal(CentralFixation.java_class(), fixations_to_make.get(0).java_class())
#  assert_equal(model.getAttentionClock(), fixations_to_make.get(0).getTimeDecidedUpon())
#  
#  # Invoke "scheduleOrMakeNextFixation" before the CentralFixation just 
#  # scheduled is decided upon.  All variables checked previously remain 
#  # unaltered.
#  time = rand(time...model.getAttentionClock())
#  result = model.scheduleOrMakeNextFixation(chess_board, time, false)
#  fixations_to_make = model.getFixationsToMake(time)
#  
#  assert_true(result.isEmpty())
#  assert_equal(1, fixations_to_make.size())
#  assert_equal(CentralFixation.java_class(), fixations_to_make.get(0).java_class())
#  assert_equal(model.getAttentionClock(), fixations_to_make.get(0).getTimeDecidedUpon())
#  
#  # Invoke "scheduleOrMakeNextFixation" when the CentralFixation just 
#  # scheduled is decided upon, i.e. when the attention resource of the CHREST 
#  # model is free.  At this point, the perceiver resource should also be free
#  # so the CentralFixation should now have its performance time set.  A 
#  # ChessDomain.fixation.SalientManFixation will now also be loaded for 
#  # deliberation since CHREST's attention is free, it is still performing its
#  # initial fixations but its very initial fixation has been loaded for 
#  # execution.
#  time = model.getAttentionClock()
#  result = model.scheduleOrMakeNextFixation(chess_board, time, false)
#  fixations_to_make = model.getFixationsToMake(time)
#  
#  assert_equal(2, result.size())
#  assert_equal(FixationResult::DELIBERATION_SCHEDULED, result.get(0))
#  assert_equal(FixationResult::PERFORMANCE_SCHEDULED, result.get(1))
#  
#  assert_equal(time, model.getAttentionClock())
#  assert_equal(time + model.getSaccadeTime(), model.getPerceiverClock())
#  assert_equal(1, fixations_to_make.size())
#  assert_equal(CentralFixation.java_class(), fixations_to_make.get(0).java_class())
  
  
  # Not yet tested
  #   - What happens when no fixation is scheduled to be made/performed but the
  #     attention resource is busy
  #   - What happens when fixation is scheduled to be performed and the function
  #     is invoked at a time when the perceptual resource is busy and the 
  #     "abandonFixationIfPerceptionBusy" boolean parameter is set to true.

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
