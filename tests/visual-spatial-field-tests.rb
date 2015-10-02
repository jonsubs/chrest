################################################################################
# Tests that an entirely blind scene is handled correctly by the visual-spatial 
# field constructor, i.e. nothing is encoded so CHREST's attention clock is not 
# incremented from the time of visual-spatial field creation specified.
unit_test "constructor (blind scene to encode)" do
  scene = Scene.new("blind ", 10, 10, nil)
  scene.addItemToSquare(5, 5, "00", Scene.getCreatorToken())
  
  creation_time = 0
  time_to_encode_objects = 50
  time_to_encode_empty_squares = 5
  visual_spatial_field_access_time = 100
  time_to_move_object = 250
  lifespan_for_recognised_objects = 10000
  lifespan_for_unrecognised_objects = 5000
  number_fixations = 20
  
  model = Chrest.new
  model.setDomain(GenericDomain.new(model))
  
  visual_spatial_field = VisualSpatialField.new(
    model,
    scene, 
    time_to_encode_objects,
    time_to_encode_empty_squares,
    visual_spatial_field_access_time, 
    time_to_move_object, 
    lifespan_for_recognised_objects,
    lifespan_for_unrecognised_objects,
    number_fixations,
    creation_time,
    false,
    false
  )
  
  assert_equal(0, model.getAttentionClock, "occurred when checking CHREST's attention clock.")
  assert_equal(0, visual_spatial_field.getHeight(), "occurred when checking the height of the visual-spatial field.")
  assert_equal(0, visual_spatial_field.getWidth(), "occurred when checking the width of the visual-spatial field.")
end

################################################################################
# Tests that the visual-spatial field constructor operates as expected given all
# possible permutations of the parameters that can be supplied to the 
# constructor:
# 
# 1) Do not encode the scene creator or ghost objects.
# 2) Do not encode the scene creator but encode ghost objects.
# 3) Encode the scene creator but do not encode ghost objects.
# 4) Encode the scene creator and ghost objects.
#
# The outcome of the constructor for each of these permutations is constructed 
# for a variety of scenarios designed to cover every possible scenario that may
# occur when a visual-spatial field is constructed.
unit_test "constructor (non-blind scenes to encode)" do
  
  ##########################################
  ##### SET INDEPENDENT TEST VARIABLES #####
  ##########################################
  
  time_to_encode_objects = 50
  time_to_encode_empty_squares = 5
  visual_spatial_field_access_time = 100
  time_to_move_object = 250
  recognised_object_lifespan = 20000
  unrecognised_object_lifespan = 10000
  number_fixations = 20 # Crucial to ensure that all chunks that should be 
                        # returned are returned during object recognition in
                        # visual-spatial field construction
  
  #####################
  ##### TEST LOOP #####
  #####################
  
  for test in 1..4
    encode_scene_creator = false
    encode_ghost_objects = false
    
    if test == 1
    elsif test == 2
      encode_ghost_objects = true
    elsif test == 3
      encode_scene_creator = true
    else
      encode_ghost_objects = true
      encode_scene_creator = true
    end
    
    # Get scenario data.
    scenario_data = get_visual_spatial_field_construction_scenario_data(
      encode_scene_creator, 
      encode_ghost_objects, 
      time_to_encode_objects, 
      time_to_encode_empty_squares,
      recognised_object_lifespan
    )
    
    #########################
    ##### SCENARIO LOOP #####
    #########################
    
    for scenario in 1..scenario_data.count
      
      data = scenario_data[scenario - 1]
      
      reality = data[0]
      list_patterns_to_learn = data[1]
      number_chunks_recognised = data[2]
      expected_visual_spatial_field_object_properties = data[3]
      squares_to_be_ignored = data[4]
      number_unrecognised_objects = data[5]
      number_empty_squares = data[6]
      
      # Create a new CHREST instance and set its domain (important to enable 
      # correct or expected perceptual mechanisms).
      model = Chrest.new
      model.setDomain(GenericDomain.new(model))

      # Set the model's field of view to 1 so that unrecognised objects do not
      # cause the model to not recognise intended objects due to list-patterns 
      # input to LTM containing extraneous objects.
      model.getPerceiver().setFieldOfView(1)
      
      # Set the domain time (the external clock to CHREST) to 0.
      domain_time = 0
      
      ###############################
      ##### LEARN LIST PATTERNS #####
      ###############################

      for list_pattern in list_patterns_to_learn
        recognised_chunk = model.recogniseAndLearn(list_pattern, domain_time).getImage()
        until recognised_chunk.contains(list_pattern.getItem(list_pattern.size()-1))
          recognised_chunk = model.recogniseAndLearn(list_pattern, domain_time).getImage()
          domain_time += 1
        end
      end

      # Set domain time to time that learning finishes so that when the 
      # visual-spatial field of the model is constructed below, 
      # the attention clock of the model will be free to do this.
      domain_time = model.getAttentionClock

      ############################################
      ##### INSTANTIATE VISUAL-SPATIAL FIELD #####
      ############################################

      # Since reality is scanned using CHREST's perceptual mechanisms when 
      # encoding reality into a visual-spatial field and since CHREST's 
      # perceptual mechanisms are not deterministic with respect to what order 
      # squares in reality are fixated on, testing of the visual-spatial field 
      # constructed should only be performed when the objects recognised in 
      # reality are recognised in the order specified for each list pattern to 
      # learn in each sub-test.  This allows for accurate calculations to be 
      # made regarding creation/terminus times and recognised/ghost status for 
      # each VisualSpatialFieldObject in the visual-spatial field.  So, to control when 
      # the model is ready for testing, the boolean flag set initially to 
      # "false" below is used.  This is only set to true when the contents of 
      # STM after constructing the visual-spatial field are what is expected by 
      # the current scenario.
      visual_stm_contents_as_expected = false
      creation_time = domain_time
      expected_stm_contents = ""
      for list_pattern in list_patterns_to_learn
        expected_stm_contents += list_pattern.toString()
      end

      until visual_stm_contents_as_expected do
        
       # Set creation time to the current domain time (this is important in 
        # calculating a lot of test variables below).
        creation_time = domain_time

        # Construct the visual-spatial field.
        visual_spatial_field = VisualSpatialField.new(
          model,
          reality, 
          time_to_encode_objects,
          time_to_encode_empty_squares,
          visual_spatial_field_access_time, 
          time_to_move_object, 
          recognised_object_lifespan,
          unrecognised_object_lifespan,
          number_fixations,
          domain_time,
          encode_ghost_objects,
          false
        )

        # Get contents of STM (will have been populated during object 
        # recognition during visual-spatial field construction) and remove root 
        # nodes and nodes with empty images.  This will leave retrieved chunks 
        # that have non-empty images, i.e. these images should contain the 
        # list-patterns learned by the model.
        stm = model.getVisualStm()
        stm_contents = ""
        for i in (stm.getCount() - 1).downto(0)
          chunk = stm.getItem(i)
          if( !chunk.equals(model.getVisualLtm()) )
            if(!chunk.getImage().isEmpty())
              stm_contents += chunk.getImage().toString()
            end
          end
        end

        # Check if STM contents are as expected, if they are, set the flag that
        # controls when the model is ready for testing to true.
        expected_stm_contents == stm_contents ? visual_stm_contents_as_expected = true : nil

        # Advance domain time to the time that the visual-spatial field will be 
        # completely instantiated so that the model's attention will be free 
        # should a new visual-field need to be constructed.
        domain_time = model.getAttentionClock
      end
    
      ###################
      ##### TESTING #####
      ###################
      
      error_message_test_type = "occurred when scene creator " + 
        ((test == 1 || test == 2) ? "is not" : "is") + 
        " encoded and ghost objects " +
        ((test == 1 || test == 3) ? "are not" : "are") +
        " encoded"

      expected_visual_spatial_field_object_properties = add_expected_values_for_unrecognised_visual_spatial_objects(
        reality, 
        expected_visual_spatial_field_object_properties, 
        squares_to_be_ignored,
        time_to_encode_objects,
        time_to_encode_empty_squares,
        unrecognised_object_lifespan,
        number_chunks_recognised
      )
    
      # Set the time that the model's attention is expected to become free after
      # instantiating the visual-spatial field.
      expected_attention_free_time = get_visual_spatial_field_instantiation_complete_time(
        creation_time, 
        visual_spatial_field_access_time,
        time_to_encode_objects,
        time_to_encode_empty_squares,
        number_chunks_recognised,
        number_unrecognised_objects,
        number_empty_squares
      )
      assert_equal(expected_attention_free_time, model.getAttentionClock(), error_message_test_type + " and the attention clock of the CHREST model in scenario " + scenario.to_s + " is checked.")
     
      # 1) Test that the number of items on each visual-spatial coordinate is as 
      #    expected.
      # 2) For each VisualSpatialFieldObject on each visual-spatial coordinate:
      #    a) Set its creation and terminus values now that the visual-spatial 
      #       field creation time has been set.
      #    b) Check that its identifier, class, time created, terminus, 
      #       recognised status and ghost status is as expected.
      error_message_prescript = error_message_test_type + " in scenario " + scenario.to_s + " when checking "
    
      for row in 0...reality.getHeight()
        for col in 0...reality.getWidth()

          visual_spatial_field_objects = visual_spatial_field.getSquareContents(col, row)
          assert_equal(expected_visual_spatial_field_object_properties[col][row].count(), visual_spatial_field_objects.size(), error_message_prescript + "the number of items on col " + col.to_s + ", row " + row.to_s)

          for i in 0...visual_spatial_field_objects.size()
            error_message_postscript = " for object " + i.to_s  + " on col " + col.to_s + ", row " + row.to_s + "."
            expected_visual_spatial_field_object = expected_visual_spatial_field_object_properties[col][row][i]

            expected_visual_spatial_field_object[2] += (creation_time + visual_spatial_field_access_time)
            expected_visual_spatial_field_object[3] = (expected_visual_spatial_field_object[3] == nil ? nil : (expected_visual_spatial_field_object[3] + expected_visual_spatial_field_object[2]))

            visual_spatial_field_object = visual_spatial_field_objects[i]
            
            assert_equal(expected_visual_spatial_field_object[0], visual_spatial_field_object.getIdentifier(), error_message_prescript + "the identifier" + error_message_postscript)
            assert_equal(expected_visual_spatial_field_object[1], visual_spatial_field_object.getObjectClass(), error_message_prescript + "the object class" + error_message_postscript)
            assert_equal(expected_visual_spatial_field_object[2], visual_spatial_field_object.getTimeCreated(), error_message_prescript + "the creation time" + error_message_postscript)
            assert_equal(expected_visual_spatial_field_object[3], visual_spatial_field_object.getTerminus(), error_message_prescript + "the terminus" + error_message_postscript)
            assert_equal(expected_visual_spatial_field_object[4], visual_spatial_field_object.recognised(domain_time), error_message_prescript + "the recognised status" + error_message_postscript)
            assert_equal(expected_visual_spatial_field_object[5], visual_spatial_field_object.isGhost(), error_message_prescript + "the ghost status" + error_message_postscript)
          end
        end
      end
    end
  end
end

################################################################################
# Tests for correct operation of the 
# "VisualSpatialField.checkForDuplicateObjects()" method (this has private 
# access in VisualSpatialScene but is used in the constructor so must be 
# accessed implicitly through the constructor rather than explicitly calling 
# it).  To do this, three sub-tests are performed:
# 
# 1) A Scene containing blind and empty squares only is constructed.  Despite
#    all VisualSpatialFieldObject instances that represent blind and empty 
#    having identical identifiers, these should be exluded from the duplicate
#    check and thus, no error should be thrown.
# 2) A Scene containing blind and empty squares along with two objects that have 
#    the same class but different identifiers is constructed.  Despite the 
#    objects having the same class, their identifiers differ so no error should
#    be thrown.
# 3) A Scene containing blind and empty squares along with two objects that have 
#    different classes but the same identifiers is constructed.  In this case,
#    an error should be thrown due to the existence of two objects with the same
#    identifier, irrespective of whether they have the same class.
#
unit_test "duplicate items" do
  error_thrown = false
  
  ######################
  ##### SUB-TEST 1 #####
  ######################
  
  scene = Scene.new("Blind and empty", 5, 5, nil)
  scene.addItemToSquare(0, 0, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(0, 1, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  begin
    VisualSpatialField.new( 
      Chrest.new,
      scene, 
      0,
      0,
      0, 
      0, 
      0,
      0,
      2,
      0,
      false,
      false
    )
  rescue
    error_thrown = true
  end
  assert_false(error_thrown, "occurred when checking if an error is thrown after encoding only blind and empy squares in the Scene to encode.")
  
  ######################
  ##### SUB-TEST 2 #####
  ######################
  
  scene = Scene.new("Duplicate classes, unique IDs", 5, 5, nil)
  scene.addItemToSquare(0, 0, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(0, 1, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(0, 2, "0", "A")
  scene.addItemToSquare(0, 3, "1", "A")
  
  begin
    VisualSpatialField.new( 
      Chrest.new,
      scene, 
      0,
      0,
      0, 
      0, 
      0,
      0,
      2,
      0,
      false,
      false
    )
  rescue
    error_thrown = true
  end
  assert_false(error_thrown, "occurred when checking if an error is thrown after encoding objects with duplicate classes but unique identifiers in the Scene to encode.")

  ######################
  ##### SUB-TEST 3 #####
  ######################
  
  scene = Scene.new("Unique classes, duplicate IDs", 5, 5, nil)
  scene.addItemToSquare(0, 0, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(0, 1, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(0, 2, "0", "A")
  scene.addItemToSquare(0, 3, "0", "B")
  
  begin
    VisualSpatialField.new( 
      Chrest.new,
      scene, 
      0,
      0,
      0, 
      0, 
      0,
      0,
      2,
      0,
      false,
      false
    )
  rescue
    error_thrown = true
  end
  assert_true(error_thrown, "occurred when checking if an error is thrown after encoding objects with unique classes but duplicate identifiers in the Scene to encode.")
end

################################################################################
# Checks for correct operation of the "VisualSpatialField.getAsScene()" function
# when all possible permutations of parameters are supplied.  Four scenarios are 
# tested:
# 
# 1) The Scene returned is as expected after all objects are encoded but before 
#    any of their termini are reached.  Ghost objects are to not be present in 
#    the Scene returned.
# 2) The Scene returned is as expected after all objects are encoded but before 
#    any of their termini are reached.  Ghost objects are to be present in the 
#    Scene returned.
# 3) The Scene returned is as expected after all objects are encoded but before 
#    any of their termini are reached.  Two objects should exist on the same 
#    coordinates.
# 4) The Scene returned is as expected after the termini for all objects have 
#    been reached.
#
#                  --------
# 4     x      x   |      |   x      x
#           ----------------------
# 3     x   | 3(C) |      |      |   x
#    ------------------------------------
# 2  |      |      | 1(B) |      |      |
#    ------------------------------------
# 1     x   | 0(A) |      |      |   x
#           ----------------------
# 0     x     2(b) |SLF(4)|   x      x
#                  --------
#       0      1      2       3      4     COORDINATES
unit_test "get_as_scene" do
  
  # Set the objects that will be used.
  test_objects = [
    ["0", "A"], 
    ["1", "B"],
    [VisualSpatialField.getGhostObjectIdPrefix + "0", "B"],
    ["3", "C"],
    ["4", Scene.getCreatorToken()]
  ]
  
  ########################
  ##### CREATE SCENE #####
  ########################
  
  scene = Scene.new("Test scene", 5, 5, nil)
  scene.addItemToSquare(2, 0, test_objects[4][0], test_objects[4][1])
  scene.addItemToSquare(1, 1, test_objects[0][0], test_objects[0][1])
  scene.addItemToSquare(2, 1, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(3, 1, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(0, 2, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(1, 2, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(2, 2, test_objects[1][0], test_objects[1][1])
  scene.addItemToSquare(3, 2, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(4, 2, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(1, 3, test_objects[3][0], test_objects[3][1])
  scene.addItemToSquare(2, 3, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(3, 3, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(2, 4, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  
  ###################################
  ##### CREATE NEW CHREST MODEL #####
  ###################################
  model = Chrest.new
  model.setDomain(GenericDomain.new(model))
  model.getPerceiver.setFieldOfView(1)
  
  #########################
  ##### SET TEST TIME #####
  #########################
  
  # Set the domain time (the time against which all CHREST operations will be
  # performed in this test).
  domain_time = 0
  
  ###########################
  ##### CHREST LEARNING #####
  ###########################
  
  # Since the scene creator is present, the locations of 0 and the ghost object
  # should be learned as creator-relative since this is how the coordinates will
  # be formatted during recognition when the visual-spatial field is 
  # constructed.
  real_object_pattern = ItemSquarePattern.new(test_objects[0][1], -1, 1)
  ghost_object_pattern = ItemSquarePattern.new(test_objects[2][1], -1, 0)
  list_pattern_to_learn = ListPattern.new()
  list_pattern_to_learn.add(real_object_pattern)
  list_pattern_to_learn.add(ghost_object_pattern)
  recognised_chunk = model.recogniseAndLearn(list_pattern_to_learn, domain_time).getImage().toString()
  until recognised_chunk == list_pattern_to_learn.toString()
    domain_time += 1
    recognised_chunk = model.recogniseAndLearn(list_pattern_to_learn, domain_time).getImage().toString()
  end
  
  # Set the domain time to be the value of CHREST's learning clock since, when
  # the visual-spatial field is constructed, the LTM of the model will contain
  # the completely familiarised learned pattern enabling expected visual-spatial
  # field construction due to chunk recognition retrieving the learned pattern.
  domain_time = model.getLearningClock()
  
  ##########################################
  ##### CONSTRUCT VISUAL-SPATIAL FIELD #####
  ##########################################
  
  # Set visual-spatial field variables.
  creation_time = domain_time
  number_fixations = 20
  time_to_encode_objects = 50
  time_to_encode_empty_squares = 10
  visual_spatial_field_access_time = 100
  time_to_move_object = 250
  recognised_object_lifespan = 60000
  unrecognised_object_lifespan = 30000
  
  visual_stm_contents_as_expected = false
  creation_time = domain_time
  expected_stm_contents = recognised_chunk
  until visual_stm_contents_as_expected do
    
    # Set creation time to the current domain time (this is important in 
    # calculating a lot of test variables below).
    creation_time = domain_time

    # Construct the visual-spatial field.
    visual_spatial_field = VisualSpatialField.new(
      model,
      scene, 
      time_to_encode_objects,
      time_to_encode_empty_squares,
      visual_spatial_field_access_time, 
      time_to_move_object, 
      recognised_object_lifespan,
      unrecognised_object_lifespan,
      number_fixations,
      domain_time,
      true,
      false
    )

    # Get contents of STM (will have been populated during object 
    # recognition during visual-spatial field construction) and remove root 
    # nodes and nodes with empty images.  This will leave retrieved chunks 
    # that have non-empty images, i.e. these images should contain the 
    # list-patterns learned by the model.
    stm = model.getVisualStm()
    stm_contents = ""
    for i in (stm.getCount() - 1).downto(0)
      chunk = stm.getItem(i)
      if( !chunk.equals(model.getVisualLtm()) )
        if(!chunk.getImage().isEmpty())
          stm_contents += chunk.getImage().toString()
        end
      end
    end

    # Check if STM contents are as expected, if they are, set the flag that
    # controls when the model is ready for testing to true.
    expected_stm_contents == stm_contents ? visual_stm_contents_as_expected = true : nil

    # Advance domain time to the time that the visual-spatial field will be 
    # completely instantiated so that the model's attention will be free 
    # should a new visual-field need to be constructed.
    domain_time = model.getAttentionClock
  end
  
  
  visual_spatial_field_as_scene_without_ghost_objects = visual_spatial_field.getAsScene(domain_time, false)
  for row in 0...visual_spatial_field.getHeight()
    for col in 0...visual_spatial_field.getWidth()
      
      expected_content = SceneObject.new(Scene.getBlindSquareIdentifier(), Scene.getBlindSquareIdentifier())
      if 
        ((row == 1 or row == 3) and (col = 2 or col == 3)) or
        (row == 2 and col != 2) or
        (row == 4 and col == 2)
      then
        expected_content = SceneObject.new(Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
      elsif row == 0 and col == 2
        expected_content = SceneObject.new(test_objects[4][0], test_objects[4][1])
      elsif row == 1 and col == 1
        expected_content = SceneObject.new(test_objects[0][0], test_objects[0][1])
      elsif row == 2 and col == 2
        expected_content = SceneObject.new(test_objects[1][0], test_objects[1][1])
      elsif row == 3 and col == 1
        expected_content = SceneObject.new(test_objects[3][0], test_objects[3][1])
      end
      
      contents = visual_spatial_field_as_scene_without_ghost_objects.getSquareContents(col, row)
      assert_equal(expected_content.getIdentifier(), contents.getIdentifier(), "occurred when checking identifier for object on col " + col.to_s + ", row " + row.to_s + " before object move and when ghost objects should not be returned")
      assert_equal(expected_content.getObjectClass(), contents.getObjectClass(), "occurred when checking object class for object on col " + col.to_s + ", row " + row.to_s + " before object move and when ghost objects should not be returned")
    end
  end
  
  visual_spatial_field_as_scene_with_ghost_objects = visual_spatial_field.getAsScene(domain_time, true)
  for row in 0...visual_spatial_field.getHeight()
    for col in 0...visual_spatial_field.getWidth()
      
      expected_content = SceneObject.new(Scene.getBlindSquareIdentifier(), Scene.getBlindSquareIdentifier())
      if 
        ((row == 1 or row == 3) and (col = 2 or col == 3)) or
        (row == 2 and col != 2) or
        (row == 4 and col == 2)
      then
        expected_content = SceneObject.new(Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
      elsif row == 0 and col == 1
        expected_content = SceneObject.new(test_objects[2][0], test_objects[2][1])
      elsif row == 0 and col == 2
        expected_content = SceneObject.new(test_objects[4][0], test_objects[4][1])
      elsif row == 1 and col == 1
        expected_content = SceneObject.new(test_objects[0][0], test_objects[0][1])
      elsif row == 2 and col == 2
        expected_content = SceneObject.new(test_objects[1][0], test_objects[1][1])
      elsif row == 3 and col == 1
        expected_content = SceneObject.new(test_objects[3][0], test_objects[3][1])
      end
      
      contents = visual_spatial_field_as_scene_with_ghost_objects.getSquareContents(col, row)
      assert_equal(expected_content.getIdentifier(), contents.getIdentifier(), "occurred when checking identifier for object on col " + col.to_s + ", row " + row.to_s + " before object move and when ghost objects should be returned")
      assert_equal(expected_content.getObjectClass(), contents.getObjectClass(), "occurred when checking object class for object on col " + col.to_s + ", row " + row.to_s + " before object move and when ghost objects should be returned")
    end
  end
  
  move_object_0 = ArrayList.new
  move_object_0.add(ItemSquarePattern.new(test_objects[0][0], 1, 1))
  move_object_0.add(ItemSquarePattern.new(test_objects[0][0], 2, 2))
  move_sequence = ArrayList.new
  move_sequence.add(move_object_0)
  visual_spatial_field.moveObjects(move_sequence, domain_time, false)
  domain_time = model.getAttentionClock
  visual_spatial_field_as_scene = visual_spatial_field.getAsScene(domain_time, true)
  
  for row in 0...visual_spatial_field.getHeight()
    for col in 0...visual_spatial_field.getWidth()
      
      expected_content = SceneObject.new(Scene.getBlindSquareIdentifier(), Scene.getBlindSquareIdentifier())
      if 
        (row == 1 and (col == 1 or col = 2 or col == 3)) or
        (row == 2 and col != 2) or
        (row == 3 and (col == 2 or col == 3)) or 
        (row == 4 and col == 2)
      then
        expected_content = SceneObject.new(Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
      elsif row == 0 and col == 1
        expected_content = SceneObject.new(test_objects[2][0], test_objects[2][1])
      elsif row == 0 and col == 2
        expected_content = SceneObject.new(test_objects[4][0], test_objects[4][1])
      elsif row == 2 and col == 2
        expected_content = SceneObject.new(test_objects[0][0], test_objects[0][1])
      elsif row == 3 and col == 1
        expected_content = SceneObject.new(test_objects[3][0], test_objects[3][1])
      end
      
      contents = visual_spatial_field_as_scene.getSquareContents(col, row)
      assert_equal(expected_content.getIdentifier(), contents.getIdentifier(), "occurred when checking identifier for object on col " + col.to_s + ", row " + row.to_s + " after object move")
      assert_equal(expected_content.getObjectClass(), contents.getObjectClass(), "occurred when checking object class for object on col " + col.to_s + ", row " + row.to_s + " after object move")
    end
  end
  
  maximum_terminus = 0;
  for row in 0...visual_spatial_field.getHeight()
    for col in 0...visual_spatial_field.getWidth() 
      for object in visual_spatial_field.getSquareContents(col, row)
        terminus = object.getTerminus()
        if terminus != nil
          terminus > maximum_terminus ? maximum_terminus = terminus : nil
        end
      end
    end
  end
  
  domain_time = maximum_terminus + 1
  visual_spatial_field_as_scene = visual_spatial_field.getAsScene(domain_time, true)
  
  for row in 0...visual_spatial_field.getHeight()
    for col in 0...visual_spatial_field.getWidth()
      
      expected_content = SceneObject.new(Scene.getBlindSquareIdentifier(), Scene.getBlindSquareIdentifier())
      if  
        ((row == 1 or row == 3) and (col = 1 or col = 2 or col == 3)) or
        row == 2 or
        (row == 4 and col == 2)
      then
        expected_content = SceneObject.new(Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
      elsif row == 0 and col == 2
        expected_content = SceneObject.new(test_objects[4][0], test_objects[4][1])
      end
      
      contents = visual_spatial_field_as_scene.getSquareContents(col, row)
      assert_equal(expected_content.getIdentifier(), contents.getIdentifier(), "occurred when checking identifier for object on col " + col.to_s + ", row " + row.to_s + " after object move and after all object's termini have been reached")
      assert_equal(expected_content.getObjectClass(), contents.getObjectClass(), "occurred when checking object class for object on col " + col.to_s + ", row " + row.to_s + " after object move and after all object's termini have been reached")
    end
  end
end

################################################################################
# Tests here check for correct operation of the "VisualSpatialField.moveObjects" 
# function using seven move sequences.  These sequences and what they test for 
# are detailed below:
# 
# 1) Move an object from visual-spatial coordinates that just contain this 
#    object to coordinates that contain another object that is "alive" when the 
#    move occurs. Tests that:
#    
#    a) The terminus of the object moved is correctly set on the visual-spatial
#       coordinates the object is moved from.
#    b) An empty square is created on the coordinates the object is moved from 
#       at the time of the move.  This simulates that the coordinates should now 
#       be empty since the coordinates are not blind in the scene encoded but 
#       there are now no objects on the coordinates in the visual-spatial field.
#    c) The object moved is added to the coordinates that the object is to be 
#       moved to at the time of the move plus the time taken to move an object.
#    d) The termini of non-empty objects that are "alive" on the visual-spatial 
#       coordinates the object is moved to are extended based on the time the
#       object is moved to the coordinates in question.  Essentially, the 
#       moved object should co-habit the visual-spatial coordinates with any 
#       non-empty objects that exist there.
#    e) The termini of objects that are not "alive" on the visual-spatial 
#       coordinates the object is moved to are not extended.
#    
# 2) Move the object from test 1 to visual-spatial coordinates that are 
#    considered to be blind at a time when the object it co-habits its current 
#    location with is "alive".  Tests that:
#    
#    a) The terminus of the object moved is correctly set on the visual-spatial
#       coordinates the object is moved from.
#    b) The terminus of the object left behind is extended since attention has
#       been focused upon its location in the visual-spatial field.
#    c) The coordinates the object is moved from should not have an empty square 
#       object added (as in the previous move) since the object left-behind is
#       still "alive".
#    d) The object moved is not added to the coordinates that the object is to 
#       be moved to since these coordinates are considered blind.
#    e) The coordinates to be moved to are still considered blind after the 
#       move.
#    
# 3) Move a ghost object from visual-spatial coordinates that are considered 
#    blind to coordinates that are also considered to be blind.  Tests that:
#    
#    a) The terminus of the object moved is correctly set on the visual-spatial
#       coordinates the object is moved from.
#    b) A blind square is created on the coordinates the object is moved from 
#       at the time of the move.  This simulates that the coordinates should now 
#       be blind since the coordinates are blind in the scene originally encoded 
#       but there are now no objects on the coordinates in the visual-spatial 
#       field.
#    d) The object moved is not added to the coordinates that the object is to 
#       be moved to since these coordinates are considered blind.
#    e) The coordinates to be moved to are still considered blind after the 
#       move.
#    
# 4) Move an object to visual-spatial coordinates that are occupied by an object 
#    that isn't "alive" when the move occurs.  Tests that:
#    
#    a) The terminus of the object moved is correctly set on the visual-spatial
#       coordinates the object is moved from.
#    b) The object moved is added to the coordinates that the object is to be 
#       moved to at the time of the move plus the time taken to move an object.
#    c) The terminus of the "deceased" objects on the visual-spatial coordinates 
#       that the object is moved to are not modified.
#    
# 5) Move the object from move 4 to visual-spatial coordinates that are 
#    considered empty.  Tests that:
#    
#    a) The terminus of the object moved is correctly set on the visual-spatial
#       coordinates the object is moved from.
#    b) An empty square is created on the coordinates the object is moved from 
#       at the time of the move.  This simulates that the coordinates should now 
#       be empty since the coordinates are not blind in the scene encoded but 
#       there are now no objects that are "alive" on the coordinates in the
#       visual-spatial field.
#    c) The object moved is added to the coordinates that the object is to be 
#       moved to at the time of the move plus the time taken to move an object.
#    d) The terminus of the empty square object on the visual-spatial 
#       coordinates the object is moved to is set to the time the object is 
#       moved.  Essentially, the coordinates moved to should no longer be 
#       considered empty.
#       
#  6) Move an object to visual-spatial coordinates that are occupied by the
#     scene creator.  Tests that:
#     
#     a) The terminus of the creator's avatar in the visual-spatial field isn't 
#        modified since it should never decay.
#        
#  7) Move an object that co-habits visual-spatial coordinates with the scene
#     creator to visual-spatial coordinates to somewhere else.  Tests that:
#     
#     a) The terminus of the creator's avatar in the visual-spatial field isn't 
#        modified since it should never decay.
#
# The scene used in the following test is illustrated below ("x" represents a 
# blind square, real objects are denoted by their identifiers and their class 
# are in parenthesis, ghost objects are denoted by lower case letters in 
# parenthesis).
# 
#                  --------
# 4     x      x   |      |   x      x
#           ----------------------
# 3     x   | 3(C) |      |      |   x
#    ------------------------------------
# 2  |      |      | 1(B) |      |      |
#    ------------------------------------
# 1     x   | 0(A) |      |      |   x
#           ----------------------
# 0     x     2(b) |SLF(4)|   x      x
#                  --------
#       0      1      2       3      4     COORDINATES
#          
unit_test "move_object" do
  
  # Set the objects that will be used.
  test_objects = [
    ["0", "A"], 
    ["1", "B"],
    [VisualSpatialField.getGhostObjectIdPrefix + "0", "B"],
    ["3", "C"],
    ["4", Scene.getCreatorToken()]
  ]
  
  ########################
  ##### CREATE SCENE #####
  ########################
  
  scene = Scene.new("Test scene", 5, 5, nil)
  scene.addItemToSquare(2, 0, test_objects[4][0], test_objects[4][1])
  scene.addItemToSquare(1, 1, test_objects[0][0], test_objects[0][1])
  scene.addItemToSquare(2, 1, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(3, 1, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(0, 2, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(1, 2, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(2, 2, test_objects[1][0], test_objects[1][1])
  scene.addItemToSquare(3, 2, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(4, 2, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(1, 3, test_objects[3][0], test_objects[3][1])
  scene.addItemToSquare(2, 3, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(3, 3, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  scene.addItemToSquare(2, 4, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  
  ###################################
  ##### CREATE NEW CHREST MODEL #####
  ###################################
  model = Chrest.new
  model.setDomain(GenericDomain.new(model))
  model.getPerceiver.setFieldOfView(1)
  
  #########################
  ##### SET TEST TIME #####
  #########################
  
  # Set the domain time (the time against which all CHREST operations will be
  # performed in this test).
  domain_time = 0
  
  ###########################
  ##### CHREST LEARNING #####
  ###########################
  
  # Since the scene creator is present, the locations of 0 and the ghost object
  # should be learned as creator-relative since this is how the coordinates will
  # be formatted during recognition when the visual-spatial field is 
  # constructed.
  real_object_pattern = ItemSquarePattern.new(test_objects[0][1], -1, 1)
  ghost_object_pattern = ItemSquarePattern.new(test_objects[2][1], -1, 0)
  list_pattern_to_learn = ListPattern.new()
  list_pattern_to_learn.add(real_object_pattern)
  list_pattern_to_learn.add(ghost_object_pattern)
  recognised_chunk = model.recogniseAndLearn(list_pattern_to_learn, domain_time).getImage().toString()
  until recognised_chunk == list_pattern_to_learn.toString()
    domain_time += 1
    recognised_chunk = model.recogniseAndLearn(list_pattern_to_learn, domain_time).getImage().toString()
  end
  
  # Set the domain time to be the value of CHREST's learning clock since, when
  # the visual-spatial field is constructed, the LTM of the model will contain
  # the completely familiarised learned pattern enabling expected visual-spatial
  # field construction due to chunk recognition retrieving the learned pattern.
  domain_time = model.getLearningClock()
  
  ##########################################
  ##### CONSTRUCT VISUAL-SPATIAL FIELD #####
  ##########################################
  
  # Set visual-spatial field variables.
  creation_time = domain_time
  number_fixations = 20
  time_to_encode_objects = 50
  time_to_encode_empty_squares = 10
  visual_spatial_field_access_time = 100
  time_to_move_object = 250
  recognised_object_lifespan = 60000
  unrecognised_object_lifespan = 30000
  
  visual_stm_contents_as_expected = false
  creation_time = domain_time
  expected_stm_contents = recognised_chunk
  until visual_stm_contents_as_expected do
    
    # Set creation time to the current domain time (this is important in 
    # calculating a lot of test variables below).
    creation_time = domain_time

    # Construct the visual-spatial field.
    visual_spatial_field = VisualSpatialField.new(
      model,
      scene, 
      time_to_encode_objects,
      time_to_encode_empty_squares,
      visual_spatial_field_access_time, 
      time_to_move_object, 
      recognised_object_lifespan,
      unrecognised_object_lifespan,
      number_fixations,
      domain_time,
      true,
      false
    )

    # Get contents of STM (will have been populated during object 
    # recognition during visual-spatial field construction) and remove root 
    # nodes and nodes with empty images.  This will leave retrieved chunks 
    # that have non-empty images, i.e. these images should contain the 
    # list-patterns learned by the model.
    stm = model.getVisualStm()
    stm_contents = ""
    for i in (stm.getCount() - 1).downto(0)
      chunk = stm.getItem(i)
      if( !chunk.equals(model.getVisualLtm()) )
        if(!chunk.getImage().isEmpty())
          stm_contents += chunk.getImage().toString()
        end
      end
    end

    # Check if STM contents are as expected, if they are, set the flag that
    # controls when the model is ready for testing to true.
    expected_stm_contents == stm_contents ? visual_stm_contents_as_expected = true : nil

    # Advance domain time to the time that the visual-spatial field will be 
    # completely instantiated so that the model's attention will be free 
    # should a new visual-field need to be constructed.
    domain_time = model.getAttentionClock
  end
  
  ####################################################################
  ##### SET-UP EXPECTED VISUAL-SPATIAL FIELD COORDINATE CONTENTS #####
  ####################################################################
  
  expected_visual_spatial_field_object_properties = Array.new
  for col in 0...visual_spatial_field.getSceneEncoded().getWidth()
    expected_visual_spatial_field_object_properties.push([])
    for row in 0...visual_spatial_field.getSceneEncoded().getHeight()
      expected_visual_spatial_field_object_properties[col].push([])
      
      if col == 2 and row == 0
        expected_visual_spatial_field_object_properties[col][row].push([
        test_objects[4][0],
        test_objects[4][1],
        creation_time + visual_spatial_field_access_time,
        nil,
        false,
        false
      ])
      else
        expected_visual_spatial_field_object_properties[col][row].push([
        Scene.getBlindSquareIdentifier(),
        Scene.getBlindSquareIdentifier(),
        creation_time + visual_spatial_field_access_time,
        nil,
        false,
        false
      ])
      end
    end
  end
  
  # Set expected values for squares containing recognised chunks first.
  expected_visual_spatial_field_object_properties[1][0][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 0)
  expected_visual_spatial_field_object_properties[1][0].push([
    test_objects[2][0],
    test_objects[2][1],
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 0),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 0, recognised_object_lifespan),
    true,
    true,
  ])

  expected_visual_spatial_field_object_properties[1][1][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 0)
  expected_visual_spatial_field_object_properties[1][1].push([
    test_objects[0][0],
    test_objects[0][1],
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 0),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 0, unrecognised_object_lifespan),
    true,
    false,
  ])

  # Set expected values for squares containing unrecognised chunks in order of
  # encoding next.
  expected_visual_spatial_field_object_properties[2][1][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 1)
  expected_visual_spatial_field_object_properties[2][1].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 1),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 1, unrecognised_object_lifespan),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[3][1][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 2)
  expected_visual_spatial_field_object_properties[3][1].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 2),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 2, unrecognised_object_lifespan),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[0][2][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 3)
  expected_visual_spatial_field_object_properties[0][2].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 3),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 3, unrecognised_object_lifespan),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[1][2][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 4)
  expected_visual_spatial_field_object_properties[1][2].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 4),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 4, unrecognised_object_lifespan),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[2][2][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 2, 4)
  expected_visual_spatial_field_object_properties[2][2].push([
    test_objects[1][0],
    test_objects[1][1],
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 2, 4),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 2, 4, unrecognised_object_lifespan),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[3][2][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 2, 5)
  expected_visual_spatial_field_object_properties[3][2].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 2, 5),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 2, 5, unrecognised_object_lifespan),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[4][2][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 2, 6)
  expected_visual_spatial_field_object_properties[4][2].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 2, 6),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 2, 6, unrecognised_object_lifespan),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[1][3][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 6)
  expected_visual_spatial_field_object_properties[1][3].push([
    test_objects[3][0],
    test_objects[3][1],
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 6),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 6, unrecognised_object_lifespan),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[2][3][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 7)
  expected_visual_spatial_field_object_properties[2][3].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 7),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 7, unrecognised_object_lifespan),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[3][3][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 8)
  expected_visual_spatial_field_object_properties[3][3].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 8),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 8, unrecognised_object_lifespan),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[2][4][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 9)
  expected_visual_spatial_field_object_properties[2][4].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 9),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 9, unrecognised_object_lifespan),
    false,
    false,
  ])
  
  ######################
  ##### FIRST MOVE #####
  ######################
  
  # This move should transform the original state of the visual-spatial field to
  # that depicted below since object 0 will be moved from (1, 1) to (2, 2):
  # 
  #                  --------
  # 4     x      x   |      |   x      x
  #           ----------------------
  # 3     x   | 3(C) |      |      |   x
  #    ------------------------------------
  # 2  |      |      | 1(B) |      |      |
  #    |      |      | 0(A) |      |      |
  #    ------------------------------------
  # 1     x   |      |      |      |   x
  #           ----------------------
  # 0     x     2(b) |SLF(4)|   x      x
  #                  --------
  #       0      1      2       3      4     COORDINATES
  #
  # This will check that:
  #
  # 1) The terminus for object 0 on coordinates (1, 1) should be set to the 
  #    time the move was requested plus the time specified for visual-spatial 
  #    field access.  This is because it is being moved from (1, 1) so should no 
  #    longer exist here.
  # 2) Coordinates (1, 1) should be re-encoded as an empty square.
  # 3) Object 0 should be present on coordinates (2, 2) since that is its
  #    specified destination.
  # 4) Object 1's terminus should be updated since it has been "looked-at" when
  #    object 0 is moved onto (2, 2).
  object_a_single_legal_move = ArrayList.new
  object_a_single_legal_move.add(ItemSquarePattern.new(test_objects[0][0], 1, 1))
  object_a_single_legal_move.add(ItemSquarePattern.new(test_objects[0][0], 2, 2))
  legal_single_object_move = ArrayList.new
  legal_single_object_move.add(object_a_single_legal_move)
  time_first_move_requested = model.getAttentionClock()
  visual_spatial_field.moveObjects(legal_single_object_move, time_first_move_requested, false)
  
  # Set terminus for object 0 on coordinates (1, 1).
  expected_visual_spatial_field_object_properties[1][1][1][3] = time_first_move_requested + visual_spatial_field_access_time
  
  # Coordinates (1, 1) should now be considered to be empty.
  expected_visual_spatial_field_object_properties[1][1].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    time_first_move_requested + visual_spatial_field_access_time,
    time_first_move_requested + visual_spatial_field_access_time + unrecognised_object_lifespan,
    false,
    false
  ])

  # Object 0 should now be on the same coordinates as object 1.
  expected_visual_spatial_field_object_properties[2][2].push([
    test_objects[0][0],
    test_objects[0][1],
    time_first_move_requested + visual_spatial_field_access_time + time_to_move_object,
    time_first_move_requested + visual_spatial_field_access_time + time_to_move_object + unrecognised_object_lifespan,
    false,
    false,
  ])
  
  # Extend object 1's terminus.
  expected_visual_spatial_field_object_properties[2][2][1][3] = time_first_move_requested + visual_spatial_field_access_time + time_to_move_object + unrecognised_object_lifespan

  check_values_of_visual_spatial_objects_against_expected(
    visual_spatial_field,
    expected_visual_spatial_field_object_properties,
    model.getAttentionClock(),
    "after performing the first move"
  )
  assert_equal(time_first_move_requested + visual_spatial_field_access_time + time_to_move_object, model.getAttentionClock(), "occurred when checking the time that the CHREST model associated with the visual-spatial field will be free after first move.")
  
  #######################
  ##### SECOND MOVE #####
  #######################
  
  # This move should transform the state of the visual-spatial field at the end
  # of the first move to that depicted below since object 0 will be moved from 
  # (2, 2) to (3, 0):
  # 
  #                  --------
  # 4     x      x   |      |   x      x
  #           ----------------------
  # 3     x   | 3(C) |      |      |   x
  #    ------------------------------------
  # 2  |      |      | 1(B) |      |      |
  #    ------------------------------------
  # 1     x   |      |      |      |   x
  #           ----------------------
  # 0     x     2(b) |SLF(4)|   x      x
  #                  --------
  #       0      1      2       3      4     COORDINATES
  #
  # This will check that:
  # 
  # 1) The terminus for object 0 on coordinates (2, 2) should be set to the 
  #    time the move was requested plus the time specified for visual-spatial 
  #    field access.  This is because it is being moved from (2, 2) so should no 
  #    longer exist here.
  # 2) Coordinates (2, 2) should not be considered as an empty square since 
  #    object 1 still exists on it (no empty square object data added to 
  #    expected visual-spatial field object values data structure).
  # 3) Object 0 shouldn't be present on coordinates (3, 0) since it is a blind
  #    square (no object 0 object data added to expected visual-spatial field 
  #    object values data structure).
  # 4) Object 1's terminus should be updated since it has been "looked-at" when
  #    object 0 is moved.
  object_a_move_to_blind_square = ArrayList.new
  object_a_move_to_blind_square.add(ItemSquarePattern.new(test_objects[0][0], 2, 2))
  object_a_move_to_blind_square.add(ItemSquarePattern.new(test_objects[0][0], 3, 0))
  moves = ArrayList.new
  moves.add(object_a_move_to_blind_square)
  time_second_move_requested = model.getAttentionClock()
  visual_spatial_field.moveObjects(moves, time_second_move_requested, false)
  
  # Set terminus for object 0 on coordinates (2, 2).
  expected_visual_spatial_field_object_properties[2][2][2][3] = time_second_move_requested + visual_spatial_field_access_time
  
  # Extend object 1's terminus.
  expected_visual_spatial_field_object_properties[2][2][1][3] = time_second_move_requested + visual_spatial_field_access_time + unrecognised_object_lifespan
  
  check_values_of_visual_spatial_objects_against_expected(
    visual_spatial_field,
    expected_visual_spatial_field_object_properties,
    model.getAttentionClock(),
    "after performing the second move"
  )
  assert_equal(time_second_move_requested + visual_spatial_field_access_time + time_to_move_object, model.getAttentionClock(), "occurred when checking the time that the CHREST model associated with the visual-spatial field will be free after second move.")

  ######################
  ##### THIRD MOVE #####
  ######################
  
  # This move should transform the state of the visual-spatial field at the end
  # of the first move to that depicted below since object 2 will be moved from 
  # (1, 0) to (3, 0):
  # 
  #                  --------
  # 4     x      x   |      |   x      x
  #           ----------------------
  # 3     x   | 3(C) |      |      |   x
  #    ------------------------------------
  # 2  |      |      | 1(B) |      |      |
  #    ------------------------------------
  # 1     x   |      |      |      |   x
  #           ----------------------
  # 0     x     x    |SLF(4)|   x      x
  #                  --------
  #       0      1      2       3      4     COORDINATES
  #
  # This will check that:
  # 
  # 1) The terminus for object 2 on coordinates (1, 0) should be set to the 
  #    time the move was requested plus the time specified for visual-spatial 
  #    field access.  This is because it is being moved from (1, 0) so should no 
  #    longer exist here.
  # 2) Coordinates (1, 0) should now be considered as a blind square since there
  #    are no objects left on these coordinates after 1 has moved.
  # 3) Object 2 shouldn't be present on coordinates (3, 0) since it is a blind
  #    square (no object 2 object data added to expected visual-spatial field 
  #    object values data structure).
  object_2_move_to_blind_square = ArrayList.new
  object_2_move_to_blind_square.add(ItemSquarePattern.new(test_objects[2][0], 1, 0))
  object_2_move_to_blind_square.add(ItemSquarePattern.new(test_objects[2][0], 3, 0))
  moves = ArrayList.new
  moves.add(object_2_move_to_blind_square)
  time_third_move_requested = model.getAttentionClock()
  visual_spatial_field.moveObjects(moves, time_third_move_requested, false)
  
  # Set terminus for object 2 on coordinates (1, 0).
  expected_visual_spatial_field_object_properties[1][0][1][3] = time_third_move_requested + visual_spatial_field_access_time
  
  #Add blind square object to (1, 0)
  expected_visual_spatial_field_object_properties[1][0].push([
    Scene.getBlindSquareIdentifier(),
    Scene.getBlindSquareIdentifier(),
    time_third_move_requested + visual_spatial_field_access_time,
    nil,
    false,
    false
  ])
  check_values_of_visual_spatial_objects_against_expected(
    visual_spatial_field,
    expected_visual_spatial_field_object_properties,
    model.getAttentionClock(),
    "after performing the third move"
  )
  assert_equal(time_third_move_requested + visual_spatial_field_access_time + time_to_move_object, model.getAttentionClock(), "occurred when checking the time that the CHREST model associated with the visual-spatial field will be free after third move.")

  #######################
  ##### FOURTH MOVE #####
  #######################
  
  # This move should transform the state of the visual-spatial field at the end
  # of the first move to that depicted below since object 1 will be moved from 
  # (2, 2) to (1, 3) and object 3's terminus should have been reached:
  # 
  #                  --------
  # 4     x      x   |      |   x      x
  #           ----------------------
  # 3     x   | 1(B) |      |      |   x
  #    ------------------------------------
  # 2  |      |      |      |      |      |
  #    ------------------------------------
  # 1     x   |      |      |      |   x
  #           ----------------------
  # 0     x      x   |SLF(4)|   x      x
  #                  --------
  #       0      1      2       3      4     COORDINATES
  #
  # This will check that:
  # 
  # 1) The terminus for object 1 on coordinates (2, 2) should be set to the 
  #    time the move was requested plus the time specified for visual-spatial 
  #    field access.  This is because it is being moved from (2, 2) so should no 
  #    longer exist here.
  # 2) Coordinates (2, 2) should now be considered as an empty square since 
  #    there are no objects left on these coordinates after 1 has moved.
  # 3) Object 1 should be added to coordinates (1, 3), its creation time should
  #    be equal to the time the fourth move is requested plus the time specified
  #    to access the visual-spatial field plus the time specified to move an
  #    object.
  # 4) Object 3's terminus shouldn't be extended on coordinates (1, 3) since its
  #    terminus will have already been reached.
  object_1_move = ArrayList.new
  object_1_move.add(ItemSquarePattern.new(test_objects[1][0], 2, 2))
  object_1_move.add(ItemSquarePattern.new(test_objects[1][0], 1, 3))
  moves = ArrayList.new
  moves.add(object_1_move)
  time_fourth_move_requested = expected_visual_spatial_field_object_properties[1][3][1][3]
  visual_spatial_field.moveObjects(moves, time_fourth_move_requested, false)
  
  # Set terminus for object 0 on coordinates (2, 2).
  expected_visual_spatial_field_object_properties[2][2][1][3] = time_fourth_move_requested + visual_spatial_field_access_time
  
  # Add empty square object to (2, 2)
  expected_visual_spatial_field_object_properties[2][2].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    time_fourth_move_requested + visual_spatial_field_access_time,
    time_fourth_move_requested + visual_spatial_field_access_time + unrecognised_object_lifespan,
    false,
    false
  ])

  # Add object 1 to (1, 3)
  expected_visual_spatial_field_object_properties[1][3].push([
    test_objects[1][0],
    test_objects[1][1],
    time_fourth_move_requested + visual_spatial_field_access_time + time_to_move_object,
    time_fourth_move_requested + visual_spatial_field_access_time + time_to_move_object + unrecognised_object_lifespan,
    false,
    false
  ])
  
  check_values_of_visual_spatial_objects_against_expected(
    visual_spatial_field,
    expected_visual_spatial_field_object_properties,
    model.getAttentionClock(),
    "after performing the fourth move"
  )
  assert_equal(time_fourth_move_requested + visual_spatial_field_access_time + time_to_move_object, model.getAttentionClock(), "occurred when checking the time that the CHREST model associated with the visual-spatial field will be free after fourth move.")

  #######################
  ##### FIFTH MOVE #####
  #######################
  
  # This move should transform the state of the visual-spatial field at the end
  # of the first move to that depicted below since object 1 will be moved from 
  # (1, 3) to (2, 2).  Since object 3's terminus was reached in the last moved,
  # coordinates (1, 3) should now be empty:
  # 
  #                  --------
  # 4     x      x   |      |   x      x
  #           ----------------------
  # 3     x   |      |      |      |   x
  #    ------------------------------------
  # 2  |      |      | 1(B) |      |      |
  #    ------------------------------------
  # 1     x   |      |      |      |   x
  #           ----------------------
  # 0     x      x   |SLF(4)|   x      x
  #                  --------
  #       0      1      2       3      4     COORDINATES
  #
  # This will check that:
  # 
  # 1) The terminus for object 1 on coordinates (1, 2) should be set to the 
  #    time the move was requested plus the time specified for visual-spatial 
  #    field access.  This is because it is being moved from (1, 3) so should no 
  #    longer exist here.
  # 2) Coordinates (1, 3) should now be considered as an empty square since 
  #    there are no objects alive on these coordinates after 1 has moved.  An
  #    empty square object should now be present on (1, 3).
  # 3) Object 1 should be added to coordinates (2, 2), its creation time should
  #    be equal to the time the fifth move is requested plus the time specified
  #    to access the visual-spatial field plus the time specified to move an
  #    object 
  # 4) The terminus for the empty square object on (2, 2) will be set to the 
  #    time object 1 is placed on these coordinates meaning that the coordinates
  #    are no longer considered empty.
  object_1_move = ArrayList.new
  object_1_move.add(ItemSquarePattern.new(test_objects[1][0], 1, 3))
  object_1_move.add(ItemSquarePattern.new(test_objects[1][0], 2, 2))
  moves = ArrayList.new
  moves.add(object_1_move)
  time_fifth_move_requested = model.getAttentionClock()
  visual_spatial_field.moveObjects(moves, time_fifth_move_requested, false)
  
  # Set terminus for object 1 on coordinates (1, 3).
  expected_visual_spatial_field_object_properties[1][3][2][3] = time_fifth_move_requested + visual_spatial_field_access_time
  
  # Add empty square object to (1, 3)
  expected_visual_spatial_field_object_properties[1][3].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    time_fifth_move_requested + visual_spatial_field_access_time,
    time_fifth_move_requested + visual_spatial_field_access_time + unrecognised_object_lifespan,
    false,
    false
  ])

  # Add object 1 to (2, 2)
  expected_visual_spatial_field_object_properties[2][2].push([
    test_objects[1][0],
    test_objects[1][1],
    time_fifth_move_requested + visual_spatial_field_access_time + time_to_move_object,
    time_fifth_move_requested + visual_spatial_field_access_time + time_to_move_object + unrecognised_object_lifespan,
    false,
    false
  ])

  expected_visual_spatial_field_object_properties[2][2][3][3] = time_fifth_move_requested + visual_spatial_field_access_time + time_to_move_object

  check_values_of_visual_spatial_objects_against_expected(
    visual_spatial_field,
    expected_visual_spatial_field_object_properties,
    model.getAttentionClock(),
    "after performing the fifth move"
  )
  assert_equal(time_fifth_move_requested + visual_spatial_field_access_time + time_to_move_object, model.getAttentionClock(), "occurred when checking the time that the CHREST model associated with the visual-spatial field will be free after fifth move.")

  #######################
  ##### SIXTH MOVE #####
  #######################
  
  # This move should transform the state of the visual-spatial field to that 
  # depicted below since object 1 will be moved from (2, 2) to (2, 0).
  # 
  #                  --------
  # 4     x      x   |      |   x      x
  #           ----------------------
  # 3     x   |      |      |      |   x
  #    ------------------------------------
  # 2  |      |      |      |      |      |
  #    ------------------------------------
  # 1     x   |      |      |      |   x
  #           ----------------------
  # 0     x      x   |SLF(4)|   x      x
  #                  | 1(B) |
  #                  --------
  #       0      1      2       3      4     COORDINATES
  #
  # This will check that:
  # 
  # 1) The terminus for object 1 on coordinates (2, 2) should be set to the 
  #    time the move was requested plus the time specified for visual-spatial 
  #    field access.  This is because it is being moved from (2, 2) so should no 
  #    longer exist here.
  # 2) Coordinates (2, 2) should now be considered as an empty square since 
  #    there are no objects alive on these coordinates after 1 has moved.  An
  #    empty square object should now be present on (2, 2).
  # 3) Object 1 should be added to coordinates (2, 0), its creation time should
  #    be equal to the time the sixth move is requested plus the time specified
  #    to access the visual-spatial field plus the time specified to move an
  #    object 
  # 4) The terminus for the creator's avatar on (2, 0) should be unaltered.
  object_1_move = ArrayList.new
  object_1_move.add(ItemSquarePattern.new(test_objects[1][0], 2, 2))
  object_1_move.add(ItemSquarePattern.new(test_objects[1][0], 2, 0))
  moves = ArrayList.new
  moves.add(object_1_move)
  time_sixth_move_requested = model.getAttentionClock()
  visual_spatial_field.moveObjects(moves, time_sixth_move_requested, false)
  
  # Set terminus for object 1 on coordinates (2, 2).
  expected_visual_spatial_field_object_properties[2][2][4][3] = time_sixth_move_requested + visual_spatial_field_access_time
  
  # Add empty square object to (2, 2)
  expected_visual_spatial_field_object_properties[2][2].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    time_sixth_move_requested + visual_spatial_field_access_time,
    time_sixth_move_requested + visual_spatial_field_access_time + unrecognised_object_lifespan,
    false,
    false
  ])

  # Add object 1 to (2, 0)
  expected_visual_spatial_field_object_properties[2][0].push([
    test_objects[1][0],
    test_objects[1][1],
    time_sixth_move_requested + visual_spatial_field_access_time + time_to_move_object,
    time_sixth_move_requested + visual_spatial_field_access_time + time_to_move_object + unrecognised_object_lifespan,
    false,
    false
  ])

  ########################
  ##### SEVENTH MOVE #####
  ########################
  
  # This move should transform the state of the visual-spatial field to that 
  # depicted below since object 1 will be moved from (2, 2) to (2, 0).
  # 
  #                  --------
  # 4     x      x   |      |   x      x
  #           ----------------------
  # 3     x   |      |      |      |   x
  #    ------------------------------------
  # 2  |      |      |      |      |      |
  #    ------------------------------------
  # 1     x   |      |      | 1(B) |   x
  #           ----------------------
  # 0     x      x   |SLF(4)|   x      x
  #                  --------
  #       0      1      2       3      4     COORDINATES
  #
  # This will check that:
  # 
  # 1) The terminus for object 1 on coordinates (2, 0) should be set to the 
  #    time the move was requested plus the time specified for visual-spatial 
  #    field access.  This is because it is being moved from (2, 0) so should no 
  #    longer exist here.
  # 2) Coordinates (2, 0) should not be considered as an empty square since 
  #    the creator's avatar still exists on these coordinates after 1 has moved.
  # 3) The terminus for the creator's avatar on (2, 0) should be unaltered.
  # 4) The terminus for the empty square on coordinates (3, 1) should be set to 
  #    the time the move was requested plus the time specified to access the 
  #    visual-spatial field plus the time specified to move an object.
  # 5) Object 1 should be added to coordinates (3, 1), its creation time should
  #    be equal to the time the move was requested plus the time specified
  #    to access the visual-spatial field plus the time specified to move an
  #    object.
  object_1_move = ArrayList.new
  object_1_move.add(ItemSquarePattern.new(test_objects[1][0], 2, 0))
  object_1_move.add(ItemSquarePattern.new(test_objects[1][0], 3, 1))
  moves = ArrayList.new
  moves.add(object_1_move)
  time_seventh_move_requested = model.getAttentionClock()
  visual_spatial_field.moveObjects(moves, time_seventh_move_requested, false)
  
  # Set terminus for object 1 on coordinates (2, 0).
  expected_visual_spatial_field_object_properties[2][0][1][3] = time_seventh_move_requested + visual_spatial_field_access_time

  # Set terminus for empty square on coordinates (3, 1).
  expected_visual_spatial_field_object_properties[3][1][1][3] = time_seventh_move_requested + visual_spatial_field_access_time + time_to_move_object
  
  # Add object 1 to (3, 1)
  expected_visual_spatial_field_object_properties[3][1].push([
    test_objects[1][0],
    test_objects[1][1],
    time_seventh_move_requested + visual_spatial_field_access_time + time_to_move_object,
    time_seventh_move_requested + visual_spatial_field_access_time + time_to_move_object + unrecognised_object_lifespan,
    false,
    false
  ])
end

################################################################################
# Tests for correct behaviour when illegal move requests are made.
# 
# 1) Request a move that is legal but while the attention resource is consumed.
# 2) Request a move when the attention resource is free and the first object 
#    move is legal but the initial location for the second object is incorrect.
# 3) Request a move when the attention resource is free and the first object 
#    move is legal but only the initial location for the second object move is 
#    specified.
# 4) Request a move when the attention resource is free and the first object 
#    move is legal but object movement in the second object move is not serial. 
#
# The scene used in the following test resembles a "cone" of vision i.e. the 
# further ahead the observer sees, the wider its field of vision.  A diagram of 
# this scene can be found below ("x" represents a "blind spot" and an object
# is denoted by its identifier and its class is in parenthesis).
# 
#   ----------------------
# 1 | 3(C) | 1(B) |      |
#   ----------------------
# 0    x   | 0(A) |  x
#          --------
#      0      1      2    VISUAL-SPATIAL FIELD COORDS
#
unit_test "move_objects_illegally" do
  
  # Set the objects that will be used.
  test_objects = [
    ["0", "A"], 
    ["1", "B"], 
    ["2", "C"]
  ]
  
  # Create the scene to be transposed into the visual-spatial field.
  scene = Scene.new("Test scene", 3, 2, nil)
  scene.addItemToSquare(1, 0, test_objects[0][0], test_objects[0][1])
  scene.addItemToSquare(0, 1, test_objects[2][0], test_objects[2][1])
  scene.addItemToSquare(1, 1, test_objects[1][0], test_objects[1][1])
  scene.addItemToSquare(2, 1, Scene.getEmptySquareIdentifier(), Scene.getEmptySquareIdentifier())
  
  # Create a new CHREST instance and set its domain (important to enable 
  # perceptual mechanisms).
  model = Chrest.new
  model.setDomain(GenericDomain.new(model))
  
  # Set independent variables.
  creation_time = 0
  number_fixations = 2
  time_to_encode_objects = 50
  time_to_encode_empty_squares = 0
  visual_spatial_field_access_time = 100
  time_to_move_object = 250
  lifespan_for_recognised_objects = 60000
  lifespan_for_unrecognised_objects = 30000
  
  # Create the visual-spatial field
  visual_spatial_field = VisualSpatialField.new(
    model,
    scene, 
    time_to_encode_objects,
    time_to_encode_empty_squares,
    visual_spatial_field_access_time, 
    time_to_move_object, 
    lifespan_for_recognised_objects,
    lifespan_for_unrecognised_objects,
    number_fixations,
    creation_time,
    false,
    false
  )
  
  expected_visual_spatial_field_object_properties = Array.new
  for col in 0...visual_spatial_field.getSceneEncoded().getWidth()
    expected_visual_spatial_field_object_properties.push([])
    for row in 0...visual_spatial_field.getSceneEncoded().getHeight()
      expected_visual_spatial_field_object_properties[col].push([])
      expected_visual_spatial_field_object_properties[col][row].push([
        Scene.getBlindSquareIdentifier(),
        Scene.getBlindSquareIdentifier(),
        creation_time + visual_spatial_field_access_time,
        nil,
        false,
        false
      ])
    end
  end
  
  expected_visual_spatial_field_object_properties[1][0][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 0)
  expected_visual_spatial_field_object_properties[1][0].push([
    test_objects[0][0],
    test_objects[0][1],
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 0),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 1, 0, lifespan_for_unrecognised_objects),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[0][1][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 2, 0)
  expected_visual_spatial_field_object_properties[0][1].push([
    test_objects[2][0],
    test_objects[2][1],
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 2, 0),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 2, 0, lifespan_for_unrecognised_objects),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[1][1][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 0)
  expected_visual_spatial_field_object_properties[1][1].push([
    test_objects[1][0],
    test_objects[1][1],
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 0),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 0, lifespan_for_unrecognised_objects),
    false,
    false,
  ])

  expected_visual_spatial_field_object_properties[2][1][0][3] = get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 1)
  expected_visual_spatial_field_object_properties[2][1].push([
    Scene.getEmptySquareIdentifier(),
    Scene.getEmptySquareIdentifier(),
    get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 1),
    get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, 3, 1, lifespan_for_unrecognised_objects),
    false,
    false,
  ])
  
  begin
    object_0_legal_move = ArrayList.new
    object_0_legal_move.add(ItemSquarePattern.new(test_objects[0][0], 1, 0))
    object_0_legal_move.add(ItemSquarePattern.new(test_objects[0][0], 1, 1))
    moves = ArrayList.new
    moves.add(object_0_legal_move)
    visual_spatial_field.moveObjects(moves, model.getAttentionClock() - 1, false)
  rescue
  end
  
  check_values_of_visual_spatial_objects_against_expected(
    visual_spatial_field,
    expected_visual_spatial_field_object_properties,
    model.getAttentionClock(),
    "after attempting to perform a legal move but before attention is free"
  )
  
  begin
    object_1_incorrect_initial_location = ArrayList.new
    object_1_incorrect_initial_location.add(ItemSquarePattern.new(test_objects[1][0], 1, 0))
    object_1_incorrect_initial_location.add(ItemSquarePattern.new(test_objects[1][0], 2, 1))
    moves = ArrayList.new
    moves.add(object_0_legal_move)
    moves.add(object_1_incorrect_initial_location)
    visual_spatial_field.moveObjects(moves, model.getAttentionClock(), false)
  rescue
  end
  
  check_values_of_visual_spatial_objects_against_expected(
    visual_spatial_field,
    expected_visual_spatial_field_object_properties,
    model.getAttentionClock(),
    "after attempting to perform a move when an object's initial location specification is incorrect"
  )

  begin
    object_1_initial_location_only = ArrayList.new
    object_1_initial_location_only.add(ItemSquarePattern.new(test_objects[1][0], 1, 1))
    moves = ArrayList.new
    moves.add(object_0_legal_move)
    moves.add(object_1_initial_location_only)
    visual_spatial_field.moveObjects(moves, model.getAttentionClock(), false)
  rescue
  end
  
  check_values_of_visual_spatial_objects_against_expected(
    visual_spatial_field,
    expected_visual_spatial_field_object_properties,
    model.getAttentionClock(),
    "after attempting to perform a move where only the initial location of an object is specified"
  )
  
  begin
    object_1_non_serial = ArrayList.new
    object_1_non_serial.add(ItemSquarePattern.new(test_objects[1][0], 1, 1))
    object_1_non_serial.add(ItemSquarePattern.new(test_objects[1][0], 2, 1))
    object_1_non_serial.add(ItemSquarePattern.new(test_objects[2][0], 0, 1))
    moves = ArrayList.new
    moves.add(object_0_legal_move)
    moves.add(object_1_non_serial)
    visual_spatial_field.moveObjects(moves, model.getAttentionClock(), false)
  rescue
  end
  
  check_values_of_visual_spatial_objects_against_expected(
    visual_spatial_field,
    expected_visual_spatial_field_object_properties,
    model.getAttentionClock(),
    "after attempting to move an object part-way through another object's move sequence"
  )
  assert_equal(creation_time + visual_spatial_field_access_time + (time_to_encode_objects * 3) + time_to_encode_empty_squares, model.getAttentionClock(), "occurred when checking the time that the CHREST model associated with the visual-spatial field.")
end

################################################################################
################################################################################
############################## NON-TEST FUNCTIONS ##############################
################################################################################
################################################################################

def get_creation_time_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, number_objects_placed, number_empty_squares_placed)
  return creation_time + 
    visual_spatial_field_access_time + 
    (number_objects_placed * time_to_encode_objects) + 
    (number_empty_squares_placed * time_to_encode_empty_squares)
end

def get_terminus_for_object_after_visual_spatial_field_creation(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, number_objects_placed, number_empty_squares_placed, object_lifespan)
  return creation_time + 
    visual_spatial_field_access_time + 
    (number_objects_placed * time_to_encode_objects) + 
    (number_empty_squares_placed * time_to_encode_empty_squares) + 
    object_lifespan
end

################################################################################
# To test visual-spatial field construction completely, a number of scenarios 
# need to be modelled and their output checked.  These scenarios must take into 
# consideration:
# 
# 1) All combinations of real/ghost object encoding.
# 2) Occurrence of real/ghost objects in recognised chunks.
# 3) Object class of real/ghost objects.
# 4) Location of real/ghost objects.
# 
# These scenarios are detailed in the table below.  Note that all possible 
# permutations of variables that need to be varied are included in the table 
# below for completeness (despite most not being applicable).
# 
# |--------------------------------------------------------------------------|
# | ================                                                         |
# | ===== NOTE =====                                                         |
# | ================                                                         |
# |                                                                          |
# | 1) If object 1 and 2 occur in the same chunk the pattern specifying      |
# |    object 2 in the chunk comes after the pattern specifying object 1.    |
# | 2) If object 1 and 2 occur in the same chunk and object 1 is a ghost,    |
# |    assume that there is an object, -1, that is real and occurs before    |
# |    object 1. This is because a chunk that specifies a ghost object first |
# |    would never be retrieved during visual-spatial field construction     |
# |    since the ghost does not exist in the Scene (reality) that is scanned |
# |--------------------------------------------------------------------------|
# 
# |------------|--------|--------|-------------|------------|-----------|--------------------------------------------|
# | Scenario # | Obj. 1 | Obj. 2 | Same Chunk? | Obj. Class | Obj. Loc. | Description                                |
# |------------|--------|--------|-------------|------------|-----------|--------------------------------------------|
# | 1          | Real   | Real   | Yes         | =          | =         | IMPOSSIBLE: same object occurs twice in    |
# |            |        |        |             |            |           | the same chunk (no duplicates allowed in   |
# |            |        |        |             |            |           | list patterns to be learned).              |
# | 2          |        |        |             |            | !=        | Objects 1 and 2 are two distinct objects   |
# |            |        |        |             |            |           | (different locations) and are recognised   |
# |            |        |        |             |            |           | at the same time.                          |                                                       |
# | 3          |        |        |             | !=         | =         | IMPOSSIBLE: co-habitation of coordinates   |
# |            |        |        |             |            |           | not supported in Scenes so not possible    |
# |            |        |        |             |            |           | to learn and therefore retrieve a chunk    |
# |            |        |        |             |            |           | specifying two objects on same coordinates |
# |            |        |        |             |            |           | simultaneously.                            |
# | 4          |        |        |             |            | !=        | Objects 1 and 2 are two distinct objects   |
# |            |        |        |             |            |           | (different object class and location) and  |
# |            |        |        |             |            |           | are recognised at the same time.           |
# | 5          |        |        | No          | =          | =         | Objects 1 and 2 are the same (same object  |
# |            |        |        |             |            |           | class and location) and object is          |
# |            |        |        |             |            |           | recognised twice (object present in two    |
# |            |        |        |             |            |           | distinct chunks).                          |
# | 6          |        |        |             |            | !=        | Objects 1 and 2 are two distinct objects   |
# |            |        |        |             |            |           | (different locations) and object 2 is      |
# |            |        |        |             |            |           | recognised after object 1.                 |
# | 7          |        |        |             | !=         | =         | IMPOSSIBLE: objects 1 and 2 are two        |
# |            |        |        |             |            |           | distinct objects (different object class)  |
# |            |        |        |             |            |           | but are located on the same coordinates.   |
# |            |        |        |             |            |           | Since the "realness" of an object is based |
# |            |        |        |             |            |           | upon its existence in reality, this would  |
# |            |        |        |             |            |           | mean that 1 of the objects is actually a   |
# |            |        |        |             |            |           | ghost.                                     |
# | 8          |        |        |             |            | !=        | Objects 1 and 2 are two distinct objects   |
# |            |        |        |             |            |           | (different object class and location) and  |
# |            |        |        |             |            |           | object 2 is recognised after object 1.     |
# | 9          |        | Ghost  | Yes         | =          | =         | IMPOSSIBLE: see scenario 1 description.    |
# |            |        |        |             |            |           | Also, object 2 is not a ghost since 1 is   |
# |            |        |        |             |            |           | real and 1 and 2 are the same.             |
# | 10         |        |        |             |            | !=        | See scenario 2 description.                |
# | 11         |        |        |             | !=         | =         | IMPOSSIBLE: See scenario 3 description.    |
# | 12         |        |        |             |            | !=        | See scenario 4 description.                |
# | 13         |        |        | No          | =          | =         | See scenario 5 description.  Also, object  |
# |            |        |        |             |            |           | 2 is not a ghost since 1 is real and 1 and |
# |            |        |        |             |            |           | 2 are the same.                            |
# | 14         |        |        |             |            | !=        | See scenario 6 description.                |
# | 15         |        |        |             | !=         | =         | Objects 1 and 2 are different (different   |
# |            |        |        |             |            |           | object class) and object 2 is recognised   |
# |            |        |        |             |            |           | after object 1.                            |
# | 16         |        |        |             |            | !=        | See scenario 8 description.                |
# | 17         | Ghost  | Real   | Yes         | =          | =         | IMPOSSIBLE: see scenario 1 description.    |
# |            |        |        |             |            |           | Also, object 1 is not a ghost since 2 is   |
# |            |        |        |             |            |           | real and 1 and 2 are the same.             |
# | 18         |        |        |             |            | !=        | See scenario 2 description.                |
# | 19         |        |        |             | !=         | =         | IMPOSSIBLE: see scenario 3 description.    |
# | 20         |        |        |             |            | !=        | See scenario 4 description.                |
# | 21         |        |        | No          | =          | =         | See scenario 5 description. Also, object   |
# |            |        |        |             |            |           | 1 is not a ghost since 2 is real and 1 and |
# |            |        |        |             |            |           | 2 are the same.                            |
# | 22         |        |        |             |            | !=        | See scenario 6 description.                |
# | 23         |        |        |             | !=         | =         | See scenario 15 description.                |
# | 24         |        |        |             |            | !=        | See scenario 8 description.                |
# | 25         |        | Ghost  | Yes         | =          | =         | IMPOSSIBLE: see scenario 1 description.    |
# | 26         |        |        |             |            | !=        | See scenario 2 description.                |
# | 27         |        |        |             | !=         | =         | IMPOSSIBLE: see scenario 3 description.    |
# | 28         |        |        |             |            | !=        | See scenario 4 description.                |
# | 29         |        |        | No          | =          | =         | See scenario 5 description.                |
# | 30         |        |        |             |            | !=        | See scenario 6 description.                |
# | 31         |        |        |             | !=         | =         | See scenario 15 description.                |
# | 32         |        |        |             |            | !=        | See scenario 8 description.                |
# |------------|--------|--------|-------------|------------|-----------|--------------------------------------------|
#  
# Scenarios 1, 3, 7, 9, 11, 17, 19, 25 and 27 should not be modelled since their 
# occurrence during normal CHREST operation is impossible.  Furthermore, 
# scenarios 13 and 21 are not modelled since the ghost object in these scenarios 
# is actually a real object and this scenario is already modelled as scenario 5.
# 
# The scenarios modelled are listed below (original scenario numbers given in 
# the table above are included in brackets beside the actual scenario 
# numbering).
# 
# For each scenario, the list patterns CHREST is trained with to create the
# scenario are detailed along with the important patterns in these list patterns
# that create the scenario delineated (if not immediately obvious).  Ghost 
# objects are represented by lower case object classes, in the code, their 
# object class will be upper-case.  Individual patterns are denoted by square 
# brackets and chunks are denoted by angled brackets.
# 
# 1(2): 2 real objects with same class but diff. location in same chunk
#       - List pattern(s) used: <[A, 1, 2][A, 1, 3]>
#    
# 2(4): 2 real objects with diff. class and location in same chunk
#       - List pattern(s) used: <[A, 1, 2][B, 1, 3]>
#    
# 3(5): 2 real objects with same class and location in diff. chunks        
#       - List pattern(s) used: <[A, 1, 2][B, 1, 3]><[D, 2, 2][A, 1, 2]>
#       - Pattern 1 in chunk 1 and pattern 2 in chunk 2 create the scenario.
#    
# 4(6): 2 real objects with same class but diff. location in diff. chunks  
#       - List pattern(s) used: <[A, 1, 2][B, 1, 3]><[D, 2, 2][A, 1, 4]>
#       - Pattern 1 in chunk 1 and pattern 2 in chunk 2 create the scenario.
# 
# 5(8): 2 real objects with diff. class and location in diff. chunks
#       - List pattern(s) used: <[A, 1, 2][B, 1, 3]><[D, 2, 2][C, 2, 3]>
#       - All object classes and locations are unique.
# 
# 6(10): Real before ghost with same class but diff. location in same chunk
#        - List pattern(s) used: <[A, 1, 2][a, 1, 3]>
# 
# 7(12): Real before ghost with diff. class and location in same chunk
#        - List pattern(s) used: <[A, 1, 2][b, 1, 3]>
#   
# 8(14): Real before ghost with same class but diff. location in diff. chunks
#        - List pattern(s) used: <[A, 1, 2][b, 1, 3]><[D, 2, 2][a, 2, 4]>
#        - Pattern 1 in chunk 1 and pattern 2 in chunk 2 create the scenario.
# 
# 9(15): Real before ghost with diff. class but same location in diff. chunks
#        - List pattern(s) used: <[A, 1, 2][b, 1, 3]><[D, 2, 2][c, 1, 2]>
#        - Pattern 1 in chunk 1 and pattern 2 in chunk 2 create the scenario.
# 
# 10(16): Real before ghost with diff. class and location in diff. chunks
#         - List pattern(s) used: <[A, 1, 2][B, 1, 3]><[D, 2, 2][c, 2, 3]>
#         - All object classes and locations are unique and real objects come
#           before the ghost object.
#    
# NOTE: In remaining scenarios, the list patterns don't just consist of a 
#       ghost and real/ghost, i.e. in some cases, there aren't just two 
#       patterns in a chunk.  This is because a ghost can't be the first 
#       pattern in a list pattern to be learned since the chunk created would 
#       never be retrieved. The only way chunks can be retrieved in these 
#       scenarios is by CHREST scanning reality for recognised objects; ghosts 
#       aren't present in reality so the test-links leading to a chunk that has 
#       a ghost object as its first pattern would never be traversed in LTM.
#    
# 11(18): Ghost before real with same class but diff. location in same chunk
#         - List pattern(s) used: <[A, 1, 2][b, 1, 3][B, 3, 2]>
#         - Patterns 2 and 3 in the chunk create the scenario.
# 
# 12(20): Ghost before real with diff. class and location in same chunk
#         - List pattern(s) used: <[A, 1, 2][b, 1, 3][C, 3, 2]>
#         - Patterns 2 and 3 in the chunk create the scenario.
#   
# 13(22): Ghost before real with same class but diff. location in diff. chunks
#         - List pattern(s) used: <[A, 1, 2][b, 1, 3]><[B, 3, 2][C, 2, 4]>
#         - Pattern 2 in chunk 1 and pattern 1 in chunk 2 create the scenario.
# 
# 14(23): Ghost before real with diff. class but same location in diff. chunks
#         - List pattern(s) used: <[A, 1, 2][b, 1, 3]><[B, 3, 2][D, 1, 3]>
#         - Pattern 2 in chunk 1 and pattern 2 in chunk 2 create the scenario.
# 
# 15(24): Ghost before real with diff. class and location in diff. chunks
#         - List pattern(s) used: <[A, 1, 2][b, 1, 3]><[C, 3, 2][D, 2, 4]>
#         - No pattern in chunk 2 has same object class or location as the
#           ghost object represented in pattern 2 of chunk 1.
# 
# 16(26): 2 ghosts with same class but diff. location in same chunk
#         - List pattern(s) used: <[A, 1, 2][b, 1, 3][b, 3, 2]>
#    
# 17(28): 2 ghosts with diff. class and location in same chunk
#         - List pattern(s) used: <[A, 1, 2][b, 1, 3][c, 3, 2]>
# 
# 18(29): 2 ghosts with same class and location in diff. chunks
#         - List pattern(s) used: <[A, 1, 2][b, 1, 3]><[D, 2, 2][b, 1, 3]>
#         - Pattern 2 in chunks 1 and 2 create the scenario.
#    
# 19(62): 2 ghosts with same class but diff. location in diff. chunks
#         - List pattern(s) used: <[A, 1, 2][b, 1, 3]><[D, 2, 2][b, 2, 4]>
#         - Pattern 2 in chunks 1 and 2 create the scenario.
#    
# 20(63): 2 ghosts with diff. class but same location in diff. chunks
#         - List pattern(s) used: <[A, 1, 2][b, 1, 3]><[D, 2, 2][c, 1, 3]>
#         - Pattern 2 in chunks 1 and 2 create the scenario.
# 
# 21(64): 2 ghosts with diff. class and location in diff. chunks
#         - List pattern(s) used: <[A, 1, 2][b, 1, 3]><[D, 2, 2][c, 2, 4]>
# 
# In addition, another 3 scenarios are modelled:
# 
# 22: A ghost object and blind square in reality occupy the same coordinates.
# 23: A ghost object and an empty square in reality occupy the same coordinates.
# 24: A ghost object and an unrecognised non-empty object occupies the same
#     coordinates.
#     
# Finally, if the scene creator should be present in reality and ghost objects
# are to be encoded, one additional scenario is encoded to ensure that the 
# creator's avatar overwrites the ghost object:
# 
# 25: A ghost object occupies the same coordinates as the scene creator.
#
# Note that correct encoding of squares that are blind, empty or occupied by an 
# unrecognised object is tested in each scenario modelled.
def get_visual_spatial_field_construction_scenario_data(
    encode_scene_creator, 
    encode_ghost_objects, 
    time_to_encode_objects, 
    time_to_encode_empty_squares,
    recognised_object_lifespan
  )
  
  # This data structure will be populated with the following data for each 
  # scenario and returned:
  # 
  # 1) The reality that has been created and should be used by the CHREST model
  #    being tested.
  # 2) The list-patterns to learn by the CHREST model being tested.
  # 3) The number of chunks that should be recognised by the CHREST model being
  #    tested.
  # 4) The basic expected values for the objects on the visual spatial field 
  #    that should be constructed, i.e. expected ID, object class, recognised 
  #    status and ghost status of all blind objects on all squares (the 
  #    visual-spatial field is entirely blind when first constructed).  This is
  #    provided for convenience.
  # 5) The jchrest.lib.Scene instances that are used by the 
  #    "add_expected_values_for_unrecognised_visual_spatial_objects" to skip 
  #    over squares that contain recognised real objects when adding expected 
  #    values for unrecognised objects on visual-spatial squares.
  # 6) The number of unrecognised objects present in reality.
  # 7) The number of empty squares present in reality.
  scenario_data = Array.new
  
  max_scenario = 24
  if(encode_scene_creator and encode_ghost_objects)
    max_scenario = 25
  end
  
  for scenario in 1..max_scenario
    
    # Create reality and populate with empty squares.  The reality created and 
    # used contains blind and empty squares in an elaborate diamond shape.  This
    # provides a difficult and rich test environment to test for correct 
    # operation of the visual-spatial field constructor mechanism.
    # 
    # For each scenario, reality is embellished with additional objects that 
    # may be recognised/unrecognised (there are always 2 unrecognised objects 
    # added to ensure that unrecognised object encoding is performed 
    # successfully).  The initial state of reality is illustrated below, if the
    # "encode_scene_creator" parameter is set to true, the relevant creator 
    # avatar (see Scene.getCreatorToken()) is added to the centre of reality at
    # coordinates (2, 2):
    #
    #                -------
    # 4     x     x  |     |  x     x
    #          ------------------- 
    # 3     x  |     |     |     |  x
    #    -------------------------------
    # 2  |     |     |     |     |     |
    #    -------------------------------
    # 1     x  |     |     |     |  x
    #          -------------------
    # 0     x     x  |     |  x     x
    #                -------
    #       0     1     2     3     4     COORDINATES
    #
    # ==================
    # ===== LEGEND =====
    # ==================
    # 
    # - "x": blind square
    # 
    #   -------
    # - |     | : empty square
    #   -------
    # 
    reality = Scene.new("Reality", 5, 5, nil)
    reality.addItemToSquare(2, 0, "", Scene.getEmptySquareIdentifier())
    reality.addItemToSquare(1, 1, "", Scene.getEmptySquareIdentifier())
    reality.addItemToSquare(2, 1, "", Scene.getEmptySquareIdentifier())
    reality.addItemToSquare(3, 1, "", Scene.getEmptySquareIdentifier())
    reality.addItemToSquare(0, 2, "", Scene.getEmptySquareIdentifier())
    reality.addItemToSquare(1, 2, "", Scene.getEmptySquareIdentifier())
    reality.addItemToSquare(3, 2, "", Scene.getEmptySquareIdentifier())
    reality.addItemToSquare(4, 2, "", Scene.getEmptySquareIdentifier())
    reality.addItemToSquare(1, 3, "", Scene.getEmptySquareIdentifier())
    reality.addItemToSquare(2, 3, "", Scene.getEmptySquareIdentifier())
    reality.addItemToSquare(3, 3, "", Scene.getEmptySquareIdentifier())
    reality.addItemToSquare(2, 4, "", Scene.getEmptySquareIdentifier())
    
    #Encode scene creator avatar, if specified.
    if(encode_scene_creator) 
      reality.addItemToSquare(2, 2, "00", Scene.getCreatorToken())
    else
      reality.addItemToSquare(2, 2, "", Scene.getEmptySquareIdentifier())
    end
    
    # Initialise the data structure used to store what list patterns should be
    # learned by the CHREST model being tested for this scenario.
    list_patterns_to_learn = Array.new
    
    # Initialise the data structure used to indicate how many chunks should be
    # recognised when the CHREST model being tested scans the reality 
    # constructed by this scenario when constructing its visual-spatial
    # field.
    number_recognised_chunks = 0
    
    # Create the data structure that stores the basic expected values for 
    # VisualSpatialFieldObjects on the visual spatial field that should be 
    # constructed when the CHREST model uses the reality specified by this 
    # scenario. As mentioned above, the first VisualSpatialFieldObject on each 
    # coordinate is expected to be a blind square whose creation and terminus 
    # times are not yet known since the actual creation time of the 
    # VisualSpatialField to test is not  known.
    expected_visual_spatial_field_object_properties = Array.new
    for col in 0...reality.getWidth()
      expected_visual_spatial_field_object_properties.push(Array.new)
      for row in 0...reality.getHeight()
        expected_visual_spatial_field_object_properties[col].push(Array.new)
        expected_visual_spatial_field_object_properties[col][row].push([
          Scene.getBlindSquareIdentifier, #Expected ID
          Scene.getBlindSquareIdentifier, #Expected class
          0, #Expected creation time.
          nil, #Expected lifespan (not exact terminus) of the object.
          false, #Expected recognised status
          false # Expected ghost status
        ])
      end
    end
    
    squares_to_be_ignored = Array.new
    number_unrecognised_objects = 0
    number_empty_squares = 0
    
    ############################################################################
    if scenario == 1
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |  A  |  G  |  F  |  x
      #    -------------------------------
      # 2  |     |  A  |     |     |     |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][A, 1, 3]>
      # 
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, the same 
      # outcome should always be produced for this scenario.  Two distinct, 
      # recognised VisualSpatialFieldObject instances should be encoded (to differentiate 
      # between the "A" objects, the second "A" object will be referred to as 
      # "A*").
      # 
      # - Creation times
      #   ~ A/A*: The first occurrence of "A" and "A*" is in the first chunk 
      #           processed so both objects are encoded at the same time (when 
      #           the first chunk is processed).
      #           
      # - Terminus times
      #   ~ A/A*: The last occurrence of "A" and "A*" is in the first chunk 
      #           processed and no other objects (recognised or unrecognised) 
      #           overwrite them.  Therefore, their lifespan will be set to the 
      #           lifespan specified for recognised objects.
      # 
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      #     
      # Blind objects on coordinates (1, 2) and (1, 3) should be overwritten at 
      # the same time (when the chunk is processed) so their termini should be 
      # equal.
      
      # Create list patterns to learn.
      list_pattern = ListPattern.new
      list_pattern.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern.add(ItemSquarePattern.new("A", 1, 3))
      list_patterns_to_learn.push(list_pattern)
      
      # All objects learned should be real so add them to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(1, 3, "1", "A")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(3, 3, "2", "F")
      reality.addItemToSquare(2, 3, "3", "G")

      #Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0", 
        "A", 
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])

      expected_visual_spatial_field_object_properties[1][3].push([
        "1", 
        "A", 
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])

      #Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(1, 3))

      #Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = (time_to_encode_objects)
      expected_visual_spatial_field_object_properties[1][3][0][3] = (time_to_encode_objects)
      
      number_recognised_chunks = 1
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 8 : 9
             
    ############################################################################
    elsif scenario == 2
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |  B  |     |  F  |  x
      #    -------------------------------
      # 2  |     |  A  |     |     |  G  |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][B, 1, 3]>
      # 
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, the same 
      # outcome should always be produced for this scenario.  Two distinct, 
      # recognised VisualSpatialFieldObject instances should be encoded.
      #   
      # - Creation times
      #   ~ A/B: The first occurrence of "A" and "B" is in the first chunk 
      #          processed so both objects are encoded at the same time (when 
      #          the first chunk is processed).
      #          
      # - Terminus times
      #   ~ A/B: The last occurrence of "A" and "B" is in the first chunk 
      #          processed and no other objects (recognised or unrecognised) 
      #          overwrite them.  Therefore, their lifespan will be set to the 
      #          lifespan specified for recognised objects.
      #      
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on coordinates (1, 2) and (1, 3) should be overwritten at 
      # the same time (when the chunk is processed) so their termini should be 
      # equal.
      
      # Create list patterns to learn.
      list_pattern = ListPattern.new
      list_pattern.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern.add(ItemSquarePattern.new("B", 1, 3))
      list_patterns_to_learn.push(list_pattern)
      
      # All objects learned should be real so add them to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(1, 3, "1", "B")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(3, 3, "2", "F")
      reality.addItemToSquare(4, 2, "3", "G")

      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0", 
        "A", 
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])

      expected_visual_spatial_field_object_properties[1][3].push([
        "1", 
        "B", 
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])

      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(1, 3))

      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = (time_to_encode_objects)
      expected_visual_spatial_field_object_properties[1][3][0][3] = (time_to_encode_objects)
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 1
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 8 : 9
 
    ############################################################################
    elsif scenario == 3
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |  F  |  x     x
      #          ------------------- 
      # 3     x  |  B  |  D  |  G  |  x
      #    -------------------------------
      # 2  |     |  A  |     |     |     |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][B, 1, 3]><[D, 2, 2][A, 1, 2]>
      # 
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      #       
      # No matter what the "encode_ghost_objects" parameter is set to, the same 
      # outcome should always be produced for this scenario.  Three distinct, 
      # recognised VisualSpatialFieldObject instances should be encoded (the "A" objects 
      # recognised are actually the same object).
      # 
      # - Creation times
      #   ~ A/B: The first occurrence of "A" and "B" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed). 
      #   ~ D: The first occurrence of "D" is in the second chunk processed 
      #        so it is encoded when the second chunk is processed.
      #        
      # - Terminus times
      #   ~ B: The last occurrence of "B" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrites it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ A/D: The last occurrence of "A" and "D" is in the second chunk 
      #          processed and no other objects (recognised or 
      #          unrecognised) overwrite them.  Therefore, their lifespan 
      #          will be set to the lifespan specified for recognised 
      #          objects.  With regards to "A", its terminus will be extended 
      #          if its current terminus has not been reached when the second 
      #          chunk is encoded (timing parameters provided to 
      #          visual-spatial field construction method may prevent this if 
      #          changed from their original values).
      #      
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on (1, 2) and (1, 3) should be overwritten at the same
      # time (when the first chunk is processed) so their termini should be
      # equal.  The blind object on (2, 3) should be overwritten when the 
      # second chunk is processed.
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("D", 2, 3))
      list_pattern_2.add(ItemSquarePattern.new("A", 1, 2))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # All objects learned should be real so add them to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(1, 3, "1", "B")
      reality.addItemToSquare(2, 3, "2", "D")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(2, 4, "3", "F")
      reality.addItemToSquare(3, 3, "4", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0", 
        "A", 
        time_to_encode_objects,
        time_to_encode_objects + recognised_object_lifespan,
        true,
        false
      ])
    
      expected_visual_spatial_field_object_properties[1][3].push([
        "1", 
        "B", 
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
      
      expected_visual_spatial_field_object_properties[2][3].push([
        "2", 
        "D", 
        time_to_encode_objects * 2,
        recognised_object_lifespan,
        true,
        false
      ])
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(1, 3))
      squares_to_be_ignored.push(Square.new(2, 3))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[2][3][0][3] = (time_to_encode_objects * 2)
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 7 : 8
      
    ############################################################################
    elsif scenario == 4
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |  A  |  x     x
      #          ------------------- 
      # 3     x  |  B  |  F  |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |  D  |     |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |  G  |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][B, 1, 3]><[D, 3, 2][A, 2, 4]>
      #       
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, the same 
      # outcome should always be produced for this scenario.  Four distinct, 
      # recognised VisualSpatialFieldObject instances should be encoded (to differentiate 
      # between the "A" objects, the second "A" object will be referred to as 
      # "A*").
      # 
      # - Creation times
      #   ~ A/B: The first occurrence of "A" and "B" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed). 
      #   ~ D/A*: The first occurrence of "D" and "A*" is in the second 
      #           chunk processed so both objects are encoded at the same 
      #           time (when the second chunk is processed). 
      #           
      # - Terminus times
      #   ~ A/B: The last occurrence of "A" and "B" is in the first chunk 
      #          processed and no other objects (recognised or 
      #          unrecognised) overwrite them.  Therefore, their lifespan 
      #          will be set to the lifespan specified for recognised 
      #          objects.
      #   ~ D/A*: The last occurrence of "D" and "A*" is in the second chunk 
      #           processed and no other objects (recognised or 
      #           unrecognised) overwrite them.  Therefore, their lifespan 
      #           will be set to the lifespan specified for recognised 
      #           objects.
      #      
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on (1, 2) and (1, 3) should be overwritten at the same
      # time (when the first chunk is processed) so their termini should be
      # equal.  Blind objects on (3, 2) and (1, 4) should also be 
      # overwritten at the same time (when the second chunk is processed) so 
      # their termini should be equal.
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("D", 3, 2))
      list_pattern_2.add(ItemSquarePattern.new("A", 2, 4))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # All objects learned should be real so add them to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(1, 3, "1", "B")
      reality.addItemToSquare(3, 2, "2", "D")
      reality.addItemToSquare(2, 4, "3", "A")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(2, 3, "4", "F")
      reality.addItemToSquare(2, 0, "5", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      expected_visual_spatial_field_object_properties[1][3].push([
        "1",
        "B",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      expected_visual_spatial_field_object_properties[3][2].push([
        "2",
        "D",
        (time_to_encode_objects * 2),
        recognised_object_lifespan,
        true,
        false
      ])
      
      expected_visual_spatial_field_object_properties[2][4].push([
        "3",
        "A",
        (time_to_encode_objects * 2),
        recognised_object_lifespan,
        true,
        false
      ])
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(1, 3))
      squares_to_be_ignored.push(Square.new(3, 2))
      squares_to_be_ignored.push(Square.new(2, 4))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[3][2][0][3] = (time_to_encode_objects * 2)
      expected_visual_spatial_field_object_properties[2][4][0][3] = (time_to_encode_objects * 2)
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 6 : 7
      
    ############################################################################
    elsif scenario == 5
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |  B  |  C  |  F  |  x
      #    -------------------------------
      # 2  |     |  A  |     |     |  G  |
      #    -------------------------------
      # 1     x  |     |     |  D  |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][B, 1, 3]><[D, 3, 1][C, 2, 3]>
      #       
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, the same 
      # outcome should always be produced for this scenario.  Four distinct, 
      # recognised VisualSpatialFieldObject instances should be encoded.
      # 
      # - Creation times
      #   ~ A/B: The first occurrence of "A" and "B" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed).  
      #   ~ D/C: The first occurrence of "D" and "C" is in the second 
      #          chunk processed so both objects are encoded at the same 
      #          time (when the second chunk is processed).  
      #          
      # - Terminus times
      #   ~ A/B: The last occurrence of "A" and "B" is in the first chunk 
      #          processed and no other objects (recognised or 
      #          unrecognised) overwrite them.  Therefore, their lifespan 
      #          will be set to the lifespan specified for recognised 
      #          objects.
      #   ~ D/C: The last occurrence of "D" and "C" is in the second chunk 
      #          processed and no other objects (recognised or 
      #          unrecognised) overwrite them.  Therefore, their lifespan 
      #          will be set to the lifespan specified for recognised 
      #          objects.
      #
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on (1, 2) and (1, 3) should be overwritten at the same
      # time (when the first chunk is processed).  The blind objects on 
      # (3, 1) and (2, 3) should also be overwritten at the same time (when 
      # the second chunk is processed).
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("D", 3, 1))
      list_pattern_2.add(ItemSquarePattern.new("C", 2, 3))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # All objects learned should be real so add them to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(1, 3, "1", "B")
      reality.addItemToSquare(3, 1, "2", "D")
      reality.addItemToSquare(2, 3, "3", "C")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(3, 3, "4", "F")
      reality.addItemToSquare(4, 2, "5", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      expected_visual_spatial_field_object_properties[1][3].push([
        "1",
        "B",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      expected_visual_spatial_field_object_properties[3][1].push([
        "2",
        "D",
        (time_to_encode_objects * 2),
        recognised_object_lifespan,
        true,
        false
      ])
    
      expected_visual_spatial_field_object_properties[2][3].push([
        "3",
        "C",
        (time_to_encode_objects * 2),
        recognised_object_lifespan,
        true,
        false
      ])
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(1, 3))
      squares_to_be_ignored.push(Square.new(3, 1))
      squares_to_be_ignored.push(Square.new(2, 3))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[3][1][0][3] = (time_to_encode_objects * 2)
      expected_visual_spatial_field_object_properties[2][3][0][3] = (time_to_encode_objects * 2)
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 6 : 7
           
    ############################################################################
    elsif scenario == 6
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |     |     |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |  F  |  G  |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][a, 1, 3]>
      # 
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, one 
      # distinct, recognised VisualSpatialFieldObject instance for object "A" should be 
      # encoded.  If the "encode_ghost_objects" parameter is set to true, an
      # additional recognised VisualSpatialFieldObject instance for object "a" should be
      # encoded.
      # 
      # - ID
      #   ~ a: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/a:  The first occurrence of "A" and "a" is in the first chunk 
      #           processed so both objects are encoded at the same time 
      #           (when the first chunk is processed).
      #           
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ a: The last occurrence of "a" is in the first chunk processed but
      #        "a" exists on a square that is empty in reality, so it will be 
      #        overwritten. Therefore, the lifespan of "a" will be set to the 
      #        time taken to encode another two unrecognised objects ("F" and 
      #        "G") plus six/seven empty squares (six if the scene creator is 
      #        encoded).
      #      
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # The blind object on (1, 2) should be overwritten when the first chunk 
      # is processed.  If ghost objects are to be encoded, the blind object 
      # on (1, 3) should also be overwritten at the same time.
      
      # Create list patterns to learn.
      list_pattern = ListPattern.new
      list_pattern.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern.add(ItemSquarePattern.new("A", 1, 3))
      list_patterns_to_learn.push(list_pattern)
      
      # Only the first object learned should be real so add it to reality.
      reality.addItemToSquare(1, 2, "0", "A")

      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(3, 2, "1", "F")
      reality.addItemToSquare(4, 2, "2", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "A",
          time_to_encode_objects,
          (time_to_encode_objects * 2) + (time_to_encode_empty_squares * (encode_scene_creator ? 6 : 7)),
          true,
          true,
        ])
      end
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 1
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 9 : 10
    
    ############################################################################
    elsif scenario == 7
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |     |  G  |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |  F  |     |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3]>
      # 
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, one 
      # distinct, recognised VisualSpatialFieldObject instance for object "A" should be 
      # encoded.  If the "encode_ghost_objects" parameter is set to true, an
      # additional recognised VisualSpatialFieldObject instance for object "b" should be
      # encoded.
      # 
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/b:  The first occurrence of "A" and "b" is in the first chunk 
      #           processed so both objects are encoded at the same time 
      #           (when the first chunk is processed).
      #           
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed but
      #        "b" exists on a square that is empty in reality, so it will be 
      #        overwritten. Therefore, the lifespan of "b" will be set to the 
      #        time taken to encode another unrecognised object ("F") plus 
      #        seven/eight empty squares (seven if the scene creator is 
      #        encoded).
      #      
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # The blind object on (1, 2) should be overwritten when the first chunk 
      # is processed.  If ghost objects are to be encoded, the blind object 
      # on (1, 3) should also be overwritten at the same time.
      
      # Create list patterns to learn.
      list_pattern = ListPattern.new
      list_pattern.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern.add(ItemSquarePattern.new("B", 1, 3))
      list_patterns_to_learn.push(list_pattern)
      
      # Only the first object learned should be real so add it to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(3, 2, "1", "F")
      reality.addItemToSquare(2, 3, "2", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          time_to_encode_objects + (time_to_encode_empty_squares * (encode_scene_creator ? 7 : 8)),
          true,
          true,
        ])
      end
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 1
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 9 : 10
      
    ############################################################################
    elsif scenario == 8
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |  G  |  x     x
      #          ------------------- 
      # 3     x  |     |     |  F  |  x
      #    -------------------------------
      # 2  |     |  A  |     |     |     |
      #    -------------------------------
      # 1     x  |     |     |  D  |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3]><[D, 3, 1][a, 1, 1]>
      #       
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, two 
      # distinct, recognised VisualSpatialFieldObject instances for objects "A" and "D" 
      # should be encoded.  If the "encode_ghost_objects" parameter is set to 
      # true, two additional recognised VisualSpatialFieldObject instances for objects "b"
      # and "a" should be encoded.
      # 
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #   ~ a: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "1" appended 
      #        since it is the second ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/b: The first occurrence of "A" and "b" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed).
      #   ~ D/a: The first occurrence of "D" and "a" is in the second chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the second chunk is processed).
      #          
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed but
      #        "b" exists on a square that is empty in reality, so it will be 
      #        overwritten. Therefore, the lifespan of "b" will be set to the 
      #        time taken to encode the second chunk plus eight/nine empty 
      #        squares (eight if the scene creator is encoded).
      #   ~ D: The last occurrence of "D" is in the second chunk processed 
      #        and no other objects (recognised or unrecognised) overwrite 
      #        it.  Therefore, its lifespan will be set to the lifespan 
      #        specified for recognised objects.
      #   ~ a: The last occurrence of "a" is in the second chunk processed 
      #        but "a" exists on a square that is empty in reality, so it 
      #        will be overwritten. Therefore, the lifespan of "a" will be 
      #        set to the time taken to encode two empty squares (the 
      #        unrecognised objects and scene creator are not present on any 
      #        squares before (1, 1) is processed).
      #      
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on (1, 2) and (3, 1) should be overwritten when the first 
      # and second chunk, respectively, are processed.  If ghost objects are to
      # be encoded, blind objects on (1, 3) and (1, 1) should be overwritten 
      # when the first and second chunk, respectively, are processed.
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("D", 3, 1))
      list_pattern_2.add(ItemSquarePattern.new("A", 1, 1))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # Only the first object learned in each list pattern should be real so add 
      # these to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(3, 1, "1", "D")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(3, 3, "2", "F")
      reality.addItemToSquare(2, 4, "3", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          time_to_encode_objects + (time_to_encode_empty_squares * (encode_scene_creator ? 7 : 8)),
          true,
          true,
        ])
      end
    
      expected_visual_spatial_field_object_properties[3][1].push([
        "1",
        "D",
        time_to_encode_objects * 2,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][1].push([
          VisualSpatialField.getGhostObjectIdPrefix + "1",
          "A",
          time_to_encode_objects * 2,
          (time_to_encode_empty_squares * 2),
          true,
          true
        ])
      end
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(3, 1))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[3][1][0][3] = (time_to_encode_objects * 2)
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
        expected_visual_spatial_field_object_properties[1][1][0][3] = (time_to_encode_objects * 2)
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 8 : 9
      
    ############################################################################
    elsif scenario == 9
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |     |  D  |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |  F  |     |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |  G  |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3]><[D, 2, 3][c, 1, 2]>
      #       
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, two 
      # distinct, recognised VisualSpatialFieldObject instances for objects "A" and "D" 
      # should be encoded.  If the "encode_ghost_objects" parameter is set to 
      # true, one additional recognised VisualSpatialFieldObject instance for object "b"
      # should be encoded.  Object "c" is not encoded since it occupies the same 
      # visual-spatial coordinates as object "A" so, since "c" is a ghost object 
      # and "A" is not, despite "c" being recognised more recently than "A", 
      # ghost objects can not overwrite real objects.
      # 
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #   ~ c: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/b: The first occurrence of "A" and "b" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed).
      #   ~ D: The first occurrence of "D" is in the second chunk processed 
      #        so it is encoded when the second chunk is processed.
      #        
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.
      #        However, if ghost objects are to be encoded: "c" occupies 
      #        the same coordinates as "A" so "A"s lifespan will be updated so
      #        that it is equal to "D"s (if its current terminus has not been 
      #        reached when the second chunk is encoded depending upon timing 
      #        parameters provided to the visual-spatial field when it is 
      #        initialised).
      #        Otherwise, if ghost objects are not to be encoded, "A"s lifespan
      #        will be set to the lifespan specified for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed but
      #        "b" exists on a square that is empty in reality, so it will be 
      #        overwritten. Therefore, the lifespan of "b" will be set to the 
      #        time taken to encode the second chunk, two unrecognised 
      #        objects ("F" and "G") plus six/seven empty squares (six if the 
      #        scene creator is encoded).
      #   ~ D: The last occurrence of "D" is in the second chunk processed 
      #        and no other objects (recognised or unrecognised) overwrite 
      #        it.  Therefore, its lifespan will be set to the lifespan 
      #        specified for recognised objects.
      #      
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on (1, 2) and (2, 3) should be overwritten when the first 
      # and second chunk, respectively, are processed.  If ghost objects are to
      # be encoded, the blind object on (1, 3) should be overwritten when the
      # first chunk is processed.
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("D", 2, 3))
      list_pattern_2.add(ItemSquarePattern.new("C", 1, 2))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # Only the first object learned in each list pattern should be real so add 
      # these to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(2, 3, "1", "D")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(3, 2, "2", "F")
      reality.addItemToSquare(2, 0, "3", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        (encode_ghost_objects ? (time_to_encode_objects + recognised_object_lifespan) : recognised_object_lifespan),
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          (time_to_encode_objects * 3) + (time_to_encode_empty_squares * (encode_scene_creator ? 6 : 7)),
          true,
          true,
        ])
      end
    
      expected_visual_spatial_field_object_properties[2][3].push([
        "1",
        "D",
        time_to_encode_objects * 2,
        recognised_object_lifespan,
        true,
        false
      ])

      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(2, 3))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[2][3][0][3] = (time_to_encode_objects * 2)
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 8 : 9
      
    ############################################################################
    elsif scenario == 10
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |  B  |     |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |  F  |     |
      #    -------------------------------
      # 1     x  |     |  D  |  G  |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][B, 1, 3]><[D, 2, 1][c, 2, 3]>
      #       
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, three 
      # distinct, recognised VisualSpatialFieldObject instances for objects "A", "B" and 
      # "D" should be encoded.  If the "encode_ghost_objects" parameter is set 
      # to true, one additional recognised VisualSpatialFieldObject instance for object 
      # "c" should be encoded. 
      # 
      # - ID
      #   ~ c: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/B: The first occurrence of "A" and "B" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed).
      #   ~ D/c: The first occurrence of "D" and "c" is in the second chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the second chunk is processed).
      #          
      # - Terminus times
      #   ~ A/B: The last occurrences of "A" and "B" are in the first chunk 
      #          processed and no other objects (recognised or unrecognised) 
      #          overwrite them.  Therefore, their lifespan will be set to 
      #          the lifespan specified for recognised objects.
      #   ~ D: The last occurrence of "D" is in the second chunk processed 
      #        and no other objects (recognised or unrecognised) overwrite 
      #        it.  Therefore, its lifespan will be set to the lifespan 
      #        specified for recognised objects.
      #   ~ c: The last occurrence of "c" is in the second chunk processed 
      #        but "c" exists on a square that is empty in reality, so it 
      #        will be overwritten. Therefore, the lifespan of "c" will be 
      #        set to the time taken to encode another two unrecognised 
      #        objects ("F" and "G") plus five/six empty squares (five if the 
      #        scene creator is encoded).
      #      
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on (1, 2) and (1, 3) should be overwritten at the same
      # when the first chunk is processed.  The blind object on (2, 1) should be 
      # overwritten when the second chunk is processed.  If ghost objects are to
      # be encoded, the blind object on (2, 3) should be overwritten when the
      # second chunk is processed.
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("D", 2, 1))
      list_pattern_2.add(ItemSquarePattern.new("C", 2, 3))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # Both objects in the first list pattern and the first object in the 
      # second list pattern learned should be real so add these to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(1, 3, "1", "B")
      reality.addItemToSquare(2, 1, "2", "D")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(3, 2, "3", "F")
      reality.addItemToSquare(3, 1, "4", "G")

      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      expected_visual_spatial_field_object_properties[1][3].push([
        "1",
        "B",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false,
      ])
    
      expected_visual_spatial_field_object_properties[2][1].push([
        "2",
        "D",
        time_to_encode_objects * 2,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[2][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "C",
          (time_to_encode_objects * 2),
          (time_to_encode_objects * 2) + (time_to_encode_empty_squares * (encode_scene_creator ? 5 : 6)),
          true,
          true
        ])
      end
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(2, 1))
      squares_to_be_ignored.push(Square.new(1, 3))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[2][1][0][3] = (time_to_encode_objects * 2)
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[2][3][0][3] = (time_to_encode_objects * 2)
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 7 : 8
      
    ############################################################################
    elsif scenario == 11
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |  F  |  x     x
      #          ------------------- 
      # 3     x  |     |     |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |  B  |     |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |  G  |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3][B, 3, 2]>
      # 
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, two 
      # distinct, recognised VisualSpatialFieldObject instances for objects "A" and "B"
      # should be encoded.  If the "encode_ghost_objects" parameter is set 
      # to true, one additional recognised VisualSpatialFieldObject instance for object 
      # "b" should be encoded. 
      # 
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/b/B: The first occurrence of "A", "b" and "B" is in the first 
      #            chunk processed so all three objects are encoded at the 
      #            same time (when the first chunk is processed).
      #            
      # - Terminus times:
      #   ~ A/B: The last occurrences of "A" and "B" are in the first chunk 
      #          processed and no other objects (recognised or unrecognised) 
      #          overwrite them.  Therefore, their lifespan will be set to 
      #          the lifespan specified for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed 
      #        but "b" exists on a square that is empty in reality, so it 
      #        will be overwritten. Therefore, the lifespan of "b" will be 
      #        set to the time taken to encode one unrecognised object ("G") 
      #        plus six/seven empty squares (six if the scene creator is 
      #        encoded).
      #           
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on (1, 2) and (3, 2) should be overwritten when the 
      # first chunk is processed.  If ghost objects are to be encoded, the
      # blind object on (1, 3) should also be encoded when the first chunk is
      # processed.
      
      # Create list patterns to learn.
      list_pattern = ListPattern.new
      list_pattern.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern.add(ItemSquarePattern.new("B", 3, 2))
      list_patterns_to_learn.push(list_pattern)
      
      # First and last object in list pattern learned should be real so add 
      # these to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(3, 2, "1", "B")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(2, 4, "3", "F")
      reality.addItemToSquare(2, 0, "4", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          time_to_encode_objects + (time_to_encode_empty_squares * (encode_scene_creator ? 6 : 7)),
          true,
          true,
        ])
      end
      
      expected_visual_spatial_field_object_properties[3][2].push([
        "1",
        "B",
        time_to_encode_objects ,
        recognised_object_lifespan,
        true,
        false
      ])

      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(3, 2))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[3][2][0][3] = time_to_encode_objects
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 1
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 8 : 9
      
    ############################################################################
    elsif scenario == 12
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |     |  F  |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |  C  |     |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |  G  |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3][C, 3, 2]>
      #       
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, two 
      # distinct, recognised VisualSpatialFieldObject instances for objects "A" and "C"
      # should be encoded.  If the "encode_ghost_objects" parameter is set 
      # to true, one additional recognised VisualSpatialFieldObject instance for object 
      # "b" should be encoded. 
      # 
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/b/C: The first occurrence of "A", "b" and "C" is in the first 
      #            chunk processed so all three objects are encoded at the 
      #            same time (when the first chunk is processed).
      #            
      # - Terminus times:
      #   ~ A/C: The last occurrences of "A" and "C" are in the first chunk 
      #          processed and no other objects (recognised or unrecognised) 
      #          overwrite them.  Therefore, their lifespan will be set to 
      #          the lifespan specified for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed 
      #        but "b" exists on a square that is empty in reality, so it 
      #        will be overwritten. Therefore, the lifespan of "b" will be 
      #        set to the time taken to encode one unrecognised object ("G")
      #        plus six/seven empty squares (six if the scene creator is 
      #        encoded).
      #           
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on (1, 2) and (3, 2) should be overwritten when the 
      # first chunk is processed.  If ghost objects are to be encoded, the
      # blind object on (1, 3) should also be encoded when the first chunk is
      # processed.
      
      # Create list patterns to learn.
      list_pattern = ListPattern.new
      list_pattern.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern.add(ItemSquarePattern.new("C", 3, 2))
      list_patterns_to_learn.push(list_pattern)
      
      # First and last object in list pattern learned should be real so add 
      # these to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(3, 2, "1", "C")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(2, 3, "2", "F")
      reality.addItemToSquare(2, 0, "3", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          time_to_encode_objects + (time_to_encode_empty_squares * (encode_scene_creator ? 6 : 7)),
          true,
          true,
        ])
      end
    
      expected_visual_spatial_field_object_properties[3][2].push([
        "1",
        "C",
        time_to_encode_objects ,
        recognised_object_lifespan,
        true,
        false
      ])
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(3, 2))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[3][2][0][3] = time_to_encode_objects
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 1
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 8 : 9
      
    ############################################################################
    elsif scenario == 13
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |  C  |  x     x
      #          ------------------- 
      # 3     x  |     |     |     |  x
      #    -------------------------------
      # 2  |  F  |  A  |     |  B  |     |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |  G  |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3]><[B, 3, 2][C, 2, 4]>
      #       
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, three 
      # distinct, recognised VisualSpatialFieldObject instances for objects "A", "B" and 
      # "C" should be encoded.  If the "encode_ghost_objects" parameter is set 
      # to true, one additional recognised VisualSpatialFieldObject instance for object 
      # "b" should be encoded. 
      # 
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/b: The first occurrence of "A" and "b" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed).
      #   ~ B/C: The first occurrence of "B" and "C" is in the second chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the second chunk is processed).
      #          
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed but
      #        "b" exists on a square that is empty in reality, so it will be 
      #        overwritten. Therefore, the lifespan of "b" will be set to the 
      #        time taken to encode the second chunk, two unrecognised 
      #        objects ("F" and "G") plus five/six empty squares (five if the 
      #        scene creator is encoded).
      #   ~ B/C: The last occurrence of "B" and "C" is in the second chunk 
      #          processed and no other objects (recognised or unrecognised) 
      #          overwrite them.  Therefore, their lifespan will be set to 
      #          the lifespan specified for recognised objects.
      #      
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # The blind object on (1, 2) should be overwritten when the first chunk is 
      # processed.  The blind objects on (3, 2) and (2, 4) should be overwritten
      # when the second chunk is processed.  If ghost objects are to be encoded, 
      # the blind object on (1, 3) should also be encoded when the first chunk 
      # is processed.
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("B", 3, 2))
      list_pattern_2.add(ItemSquarePattern.new("C", 2, 4))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # All objects except the second object in the first list pattern learned 
      # should be real so add them to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(3, 2, "1", "B")
      reality.addItemToSquare(2, 4, "2", "C")

      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(0, 2, "3", "F")
      reality.addItemToSquare(2, 0, "4", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          (time_to_encode_objects * 3) + (time_to_encode_empty_squares * (encode_scene_creator ? 5 : 6)),
          true,
          true,
        ])
      end
    
      expected_visual_spatial_field_object_properties[3][2].push([
        "1",
        "B",
        (time_to_encode_objects * 2) ,
        recognised_object_lifespan,
        true,
        false
      ])

      expected_visual_spatial_field_object_properties[2][4].push([
        "2",
        "C",
        (time_to_encode_objects * 2),
        recognised_object_lifespan,
        true,
        false
      ])

      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(3, 2))
      squares_to_be_ignored.push(Square.new(2, 4))
       
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[3][2][0][3] = (time_to_encode_objects * 2)
      expected_visual_spatial_field_object_properties[2][4][0][3] = (time_to_encode_objects * 2)
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 7 : 8
      
    ############################################################################  
    elsif scenario == 14
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |  D  |     |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |  B  |  G  |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |  F  |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3]><[B, 3, 2][D, 1, 3]>
      # 
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, three 
      # distinct, recognised VisualSpatialFieldObject instances for objects "A", "B" and 
      # "D" should be encoded.  If the "encode_ghost_objects" parameter is set 
      # to true, one additional recognised VisualSpatialFieldObject instance for object 
      # "b" should be encoded. 
      #
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/b: The first occurrence of "A" and "b" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed).
      #   ~ B/D: The first occurrence of "B" and "D" is in the second chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the second chunk is processed).
      #          
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed but
      #        "b" will be overwritten by "D" since "D" is recognised more
      #        recently and is not a ghost object.  Therefore, "b"s lifespan
      #        will be set to the time taken to encode the second chunk.
      #   ~ B/D: The last occurrence of "B" and "D" is in the second chunk 
      #          processed and no other objects (recognised or unrecognised) 
      #          overwrite them.  Therefore, their lifespan will be set to 
      #          the lifespan specified for recognised objects.
      #
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # The blind object on (1, 2) should be overwritten when the first chunk is 
      # processed.  The blind objects on (3, 2) should be overwritten when the 
      # second chunk is processed.  If ghost objects are to be encoded, the 
      # blind object on (1, 3) should be overwritten when the first chunk is 
      # processed.  Otherwise, it should be overwritten when the second chunk is
      # processed.
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("B", 3, 2))
      list_pattern_2.add(ItemSquarePattern.new("D", 1, 3))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # All objects except the second object in the first list pattern learned 
      # should be real so add them to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(3, 2, "1", "B")
      reality.addItemToSquare(1, 3, "2", "D")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(2, 0, "3", "F")
      reality.addItemToSquare(4, 2, "4", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          time_to_encode_objects,
          true,
          true
        ])
      end
    
      expected_visual_spatial_field_object_properties[3][2].push([
        "1",
        "B",
        time_to_encode_objects * 2,
        recognised_object_lifespan,
        true,
        false
      ])
    
      expected_visual_spatial_field_object_properties[1][3].push([
        "2",
        "D",
        time_to_encode_objects * 2,
        recognised_object_lifespan,
        true,
        false
      ])
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(3, 2))
      squares_to_be_ignored.push(Square.new(1, 3))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[1][3][0][3] = (time_to_encode_objects * 2)
      expected_visual_spatial_field_object_properties[3][2][0][3] = (time_to_encode_objects * 2)
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 7 : 8
        
    ############################################################################  
    elsif scenario == 15
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |  D  |  x     x
      #          ------------------- 
      # 3     x  |     |     |     |  x
      #    -------------------------------
      # 2  |  F  |  A  |     |  C  |  G  |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3]><[C, 3, 2][D, 2, 4]>
      #       
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, three 
      # distinct, recognised VisualSpatialFieldObject instances for objects "A", "C" and 
      # "D" should be encoded.  If the "encode_ghost_objects" parameter is set 
      # to true, one additional recognised VisualSpatialFieldObject instance for object 
      # "b" should be encoded. 
      #
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/b: The first occurrence of "A" and "b" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed).
      #   ~ C/D: The first occurrence of "C" and "D" is in the second chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the second chunk is processed).
      #          
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed but
      #        "b" exists on a square that is empty in reality, so it will be 
      #        overwritten. Therefore, the lifespan of "b" will be set to the 
      #        time taken to encode the second chunk, two unrecognised 
      #        objects ("F" and "G") plus five/six empty squares (five if the
      #        scene creator is encoded).
      #   ~ C/D: The last occurrence of "C" and "D" is in the second chunk 
      #          processed and no other objects (recognised or unrecognised) 
      #          overwrite them.  Therefore, their lifespan will be set to 
      #          the lifespan specified for recognised objects.
      #      
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # The blind object on (1, 2) should be overwritten when the first chunk is 
      # processed.  Blind objects on (3, 2) and (2, 4) should be overwritten 
      # when the second chunk is processed.  If ghost objects should be encoded,
      # the blind object on (1, 3) should be overwritten when the first chunk is
      # processed.
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("C", 3, 2))
      list_pattern_2.add(ItemSquarePattern.new("D", 2, 4))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # All objects except the second object in the first list pattern should be 
      # real so add them to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(3, 2, "1", "C")
      reality.addItemToSquare(2, 4, "2", "D")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(0, 2, "3", "F")
      reality.addItemToSquare(4, 2, "4", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          (time_to_encode_objects * 3) + (time_to_encode_empty_squares * (encode_scene_creator ? 5 : 6)),
          true,
          true
        ])
      end
    
      expected_visual_spatial_field_object_properties[3][2].push([
        "1",
        "C",
        time_to_encode_objects * 2,
        recognised_object_lifespan,
        true,
        false
      ])
    
      expected_visual_spatial_field_object_properties[2][4].push([
        "2",
        "D",
        time_to_encode_objects * 2,
        recognised_object_lifespan,
        true,
        false
      ])
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(3, 2))
      squares_to_be_ignored.push(Square.new(2, 4))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[3][2][0][3] = (time_to_encode_objects * 2)
      expected_visual_spatial_field_object_properties[2][4][0][3] = (time_to_encode_objects * 2)
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 7 : 8
      
    ############################################################################
    elsif scenario == 16
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |     |     |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |     |     |
      #    -------------------------------
      # 1     x  |     |     |  G  |  x
      #          -------------------
      # 0     x     x  |  F  |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3][b, 3, 2]>
      # 
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, one 
      # distinct, recognised VisualSpatialFieldObject instance for object "A" should be 
      # encoded.  If the "encode_ghost_objects" parameter is set to true, two 
      # additional recognised VisualSpatialFieldObject instances for objects "b" should be 
      # encoded (to differentiate between the "b" objects, the second "b" object 
      # will be referred to as "b*"). 
      #
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #   ~ b*: should equal the result of calling the 
      #         "VisualSpatialField.getGhostObjectIdPrefix()" method with "1" appended 
      #         since it is the second ghost object encoded in the chunks 
      #         recognised.
      #         
      # - Creation times
      #   ~ A/b/b*: The first occurrence of "A", "b" and "b*" is in the first 
      #             chunk processed so all three objects are encoded at the 
      #             same time (when the first chunk is processed).
      #             
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed but 
      #        it exists on a square that is empty in reality, so it will be 
      #        overwritten. Therefore, the lifespan of "b" will be set to the 
      #        time taken to encode two unrecognised objects ("F" and "G") plus 
      #        six/seven empty squares (six if the scene creator is encoded).
      #   ~ b*: The last occurrence of "b*" is in the first chunk processed but 
      #         it exists on a square that is empty in reality, so it will be 
      #         overwritten. Therefore, the lifespan of "b*" will be set to the 
      #         time taken to encode two unrecognised objects ("F" and "G") plus 
      #         four/five empty squares (four if the scene creator is encoded).
      #              
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # The blind object on (1, 2) should be overwritten when the first chunk is 
      # processed.  If blind objects are to be encoded, blind objects on (1, 3) 
      # and (3, 2) are also overwritten when the first chunk is processed.
      
      # Create list patterns to learn.
      list_pattern = ListPattern.new
      list_pattern.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern.add(ItemSquarePattern.new("B", 3, 2))
      list_patterns_to_learn.push(list_pattern)
      
      # Only the first object learned should be real so add it to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(2, 0, "1", "F")
      reality.addItemToSquare(3, 2, "2", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          (time_to_encode_objects * 2) + (time_to_encode_empty_squares * (encode_scene_creator ? 6 : 7)),
          true,
          true
        ])

        expected_visual_spatial_field_object_properties[3][2].push([
          VisualSpatialField.getGhostObjectIdPrefix + "1",
          "B",
          time_to_encode_objects,
          (time_to_encode_objects * 2) + (time_to_encode_empty_squares * (encode_scene_creator ? 4 : 5)),
          true,
          true
        ])
      end
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
        expected_visual_spatial_field_object_properties[3][2][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 1
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 9 : 10
      
    ############################################################################
    elsif scenario == 17
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |     |     |  G  |  x
      #    -------------------------------
      # 2  |     |  A  |     |     |  F  |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3][c, 3, 2]>
      #       
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, one 
      # distinct, recognised VisualSpatialFieldObject instance for object "A" should be 
      # encoded.  If the "encode_ghost_objects" parameter is set to true, two 
      # additional recognised VisualSpatialFieldObject instances for objects "b" and "c" 
      # should be encoded. 
      #
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #   ~ c: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "1" appended 
      #        since it is the second ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/b/c: The first occurrence of "A", "b" and "c" is in the first 
      #            chunk processed so all three objects are encoded at the 
      #            same time (when the first chunk is processed).
      #            
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to its creation time plus 
      #        the lifespan specified for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed but 
      #        it exists on a square that is empty in reality, so it will be 
      #        overwritten. Therefore, the lifespan of "b" will be set to the 
      #        time taken to encode one unrecognised object ("F") plus 
      #        seven/eight empty squares (seven if the scene creator is 
      #        encoded).
      #   ~ c: The last occurrence of "c" is in the first chunk processed but 
      #        it exists on a square that is empty in reality, so it will be 
      #        overwritten. Therefore, the lifespan of "c" will be set to the 
      #        time taken to encode six/seven empty squares (six if the 
      #        scene creator is encoded).
      #              
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # The blind object on (1, 2) should be overwritten when the first chunk is 
      # processed.  If ghost objects should be encoded, the blind objects on 
      # (1, 3) and (3, 2) should be overwritten at the same time.
     
      # Create list patterns to learn.
      list_pattern = ListPattern.new
      list_pattern.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern.add(ItemSquarePattern.new("C", 3, 2))
      list_patterns_to_learn.push(list_pattern)
      
      # Only the first object learned should be real so add it to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(4, 2, "1", "F")
      reality.addItemToSquare(3, 3, "2", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          time_to_encode_objects + (time_to_encode_empty_squares * (encode_scene_creator ? 7 : 8)),
          true,
          true
        ])
    
        expected_visual_spatial_field_object_properties[3][2].push([
          VisualSpatialField.getGhostObjectIdPrefix + "1",
          "C",
          time_to_encode_objects,
          (time_to_encode_empty_squares * (encode_scene_creator ? 6 : 7)),
          true,
          true
        ])
      end
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
        expected_visual_spatial_field_object_properties[3][2][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 1
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 9 : 10
      
    ############################################################################
    elsif scenario == 18
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |  F  |  x     x
      #          ------------------- 
      # 3     x  |     |     |  G  |  x
      #    -------------------------------
      # 2  |     |  A  |     |     |     |
      #    -------------------------------
      # 1     x  |     |     |  D  |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3]><[D, 3, 1][b, 1, 3]>
      # 
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, two 
      # distinct, recognised VisualSpatialFieldObject instances for objects "A" and "D" 
      # should be encoded.  If the "encode_ghost_objects" parameter is set to 
      # true, one additional recognised VisualSpatialFieldObject instance for object 
      # "b" should be encoded (the two "b" objects refer to the same object). 
      #
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/b: The first occurrence of "A" and "b" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed). 
      #   ~ D: The first occurrence of "D" is in the second chunk processed 
      #        so it is encoded when the second chunk is processed.
      #        
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrites it.  
      #        Therefore, its lifespan will be set to its creation time plus 
      #        the lifespan specified for recognised objects.
      #   ~ D: The last occurrence of "D" is in the second chunk processed 
      #        and no other objects (recognised or unrecognised) overwrite 
      #        it.  Therefore, its lifespan will be set to the lifespan 
      #        specified for recognised objects.
      #   ~ b: The last occurrence of "b" is in the second chunk processed 
      #        and its terminus will be extended if its current terminus has 
      #        not been reached when the second chunk is encoded (timing 
      #        parameters provided to visual-spatial field construction 
      #        method may prevent this if changed from their original
      #        values).  Object "b" is, however, overwritten by an empty 
      #        square so its lifespan is set to the time taken to encode 
      #        the second chunk plus the time taken to encode seven/eight empty 
      #        squares (seven if the scene creator is encoded).
      # 
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on (1, 2) and (3, 1) should be overwritten when the first 
      # and second chunks are processed, respectively.  If ghost objects are to
      # be encoded, the blind object on (1, 3) should be overwritten when the 
      # first chunk is processed.
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("D", 3, 1))
      list_pattern_2.add(ItemSquarePattern.new("B", 1, 3))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # Only the first object in each list pattern learned should be real so add 
      # them to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(3, 1, "1", "D")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(2, 4, "2", "F")
      reality.addItemToSquare(3, 3, "3", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          time_to_encode_objects + (time_to_encode_empty_squares * (encode_scene_creator ? 7 : 8)),
          true,
          true
        ])
      end
    
      expected_visual_spatial_field_object_properties[3][1].push([
        "1",
        "D",
        time_to_encode_objects * 2,
        recognised_object_lifespan,
        true,
        false
      ])
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(3, 1))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[3][1][0][3] = (time_to_encode_objects * 2)
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 8 : 9
      
    ############################################################################
    elsif scenario == 19
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |     |  D  |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |     |  F  |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |  G  |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3]><[D, 2, 3][b, 2, 4]>
      # 
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, two 
      # distinct, recognised VisualSpatialFieldObject instances for objects "A" and "D" 
      # should be encoded.  If the "encode_ghost_objects" parameter is set to 
      # true, two additional recognised VisualSpatialFieldObject instances for objects 
      # "b" should be encoded (to differentiate between the "b" objects, the 
      # second "b" object will be referred to as "b*").
      # 
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #   ~ b*: should equal the result of calling the 
      #         "VisualSpatialField.getGhostObjectIdPrefix()" method with "1" appended 
      #         since it is the first ghost object encoded in the chunks 
      #         recognised.
      #         
      # - Creation times
      #   ~ A/b: The first occurrence of "A" and "b" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed). 
      #   ~ D/b*: The first occurrence of "D" and "b*" is in the second 
      #           chunk processed so both objects are encoded at the same 
      #           time (when the second chunk is processed). 
      #           
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrites it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed but
      #        "b" exists on a square that is empty in reality, so it will be 
      #        overwritten. Therefore, the lifespan of "b" will be set to the 
      #        time taken to encode the second chunk, two unrecognised 
      #        objects ("F" and "G") plus six/seven empty squares (six if the 
      #        scene creator is to be encoded).
      #   ~ D: The last occurrence of "D" is in the second chunk processed 
      #        and no other objects (recognised or unrecognised) overwrites 
      #        it.  Therefore, its lifespan will be set to the lifespan 
      #        specified for recognised objects.
      #   ~ b*: The last occurrence of "b*" is in the second chunk processed 
      #         but "b*" exists on a square that is empty in reality, so it 
      #         will be overwritten. Therefore, the lifespan of "b*" will be 
      #         set to the time taken to encode two unrecognised objects 
      #         ("F" and "G") plus eight/nine empty squares (eight if the scene
      #         creator is to be encoded).
      #      
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on (1, 2) and (2, 3) should be overwritten when the first
      # and second chunks are processed, respectively.  If ghost objects should
      # be encoded then the blind objects on (1, 3) and (2, 4) should be 
      # overwritten when the first and second chunks are processed, 
      # respectively.
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("D", 2, 3))
      list_pattern_2.add(ItemSquarePattern.new("B", 2, 4))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # Only the first object in each list pattern learned should be real so add 
      # them to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(2, 3, "1", "D")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(4, 2, "2", "F")
      reality.addItemToSquare(2, 0, "3", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          (time_to_encode_objects * 3) + (time_to_encode_empty_squares * (encode_scene_creator ? 6 : 7)),
          true,
          true
        ])
      end
    
      expected_visual_spatial_field_object_properties[2][3].push([
        "1",
        "D",
        time_to_encode_objects * 2,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[2][4].push([
          VisualSpatialField.getGhostObjectIdPrefix + "1",
          "B",
          (time_to_encode_objects * 2),
          (time_to_encode_objects * 2) + (time_to_encode_empty_squares * (encode_scene_creator ? 8 : 9)),
          true,
          true
        ])
      end
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(2, 3))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[2][3][0][3] = (time_to_encode_objects * 2)
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
        expected_visual_spatial_field_object_properties[2][4][0][3] = (time_to_encode_objects * 2)
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 8 : 9
      
    ############################################################################
    elsif scenario == 20
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |     |  D  |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |     |  F  |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |  G  |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3]><[D, 2, 3][c, 1, 3]>
      # 
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, two 
      # distinct, recognised VisualSpatialFieldObject instances for objects "A" and "D" 
      # should be encoded.  If the "encode_ghost_objects" parameter is set to 
      # true, two additional recognised VisualSpatialFieldObject instances for objects 
      # "b" and "c" should be encoded.
      # 
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #   ~ c: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "1" appended 
      #        since it is the secomd ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/b: The first occurrence of "A" and "b" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed).
      #   ~ D/c: The first occurrence of "D" and "c" is in the second chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the second chunk is processed).
      #          
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed but
      #        "b" will be overwritten by "c" since "c" is recognised more
      #        recently.  Therefore, "b"s lifespan will be set to the time 
      #        taken to encode the second chunk.
      #   ~ D: The last occurrence of "D" is in the second chunk processed 
      #        and no other objects (recognised or unrecognised) overwrite 
      #        it.  Therefore, its lifespan will be set to the lifespan 
      #        specified for recognised objects.
      #   ~ c: The last occurrence of "c" is in the second chunk processed 
      #        but "c" exists on a square that is empty in reality, so it 
      #        will be overwritten. Therefore, the lifespan of "c" will be 
      #        set to the time taken to encode two unrecognised objects 
      #        ("F" and "G") plus six/seven empty squares (seven if the scene
      #        creator is encoded).
      #
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on (1, 2) and (2, 3) should be overwritten when the first 
      # and second chunk are processed, respectively.  If ghost objects are to 
      # be encoded, the blind object on (1, 3) will be overwritten when the 
      # first chunk is processed.
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("D", 2, 3))
      list_pattern_2.add(ItemSquarePattern.new("C", 1, 3))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # Only the first object in each list pattern learned should be real so add 
      # them to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(2, 3, "1", "D")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(4, 2, "2", "F")
      reality.addItemToSquare(2, 0, "3", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          time_to_encode_objects,
          true,
          true
        ])
      end
    
      expected_visual_spatial_field_object_properties[2][3].push([
        "1",
        "D",
        time_to_encode_objects * 2,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "1",
          "C",
          time_to_encode_objects * 2,
          (time_to_encode_objects * 2) + (time_to_encode_empty_squares * (encode_scene_creator ? 6 : 7)),
          true,
          true
        ])
      end
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(2, 3))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[2][3][0][3] = (time_to_encode_objects * 2)
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 8 : 9
      
    ############################################################################
    elsif scenario == 21
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |     |  D  |     |  x
      #    -------------------------------
      # 2  |  F  |  A  |     |  G  |     |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A, 1, 2][b, 1, 3]><[D, 2, 3][c, 2, 4]>
      # 
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, two 
      # distinct, recognised VisualSpatialFieldObject instances for objects "A" and "D" 
      # should be encoded.  If the "encode_ghost_objects" parameter is set to 
      # true, two additional recognised VisualSpatialFieldObject instances for objects 
      # "b" and "c" should be encoded.
      # 
      # - ID
      #   ~ b: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #   ~ c: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "1" appended 
      #        since it is the second ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/b: The first occurrence of "A" and "b" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed).
      #   ~ D/c: The first occurrence of "D" and "c" is in the second chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the second chunk is processed).
      #          
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ b: The last occurrence of "b" is in the first chunk processed but
      #        "b" will be overwritten by an empty square.  Therefore, "b"s 
      #        lifespan will be set to the time taken to encode the second 
      #        chunk, two unrecognised objects ("F" and "G") and the time 
      #        taken to encode six/seven empty squares (six if the scene creator
      #        is encoded).
      #   ~ D: The last occurrence of "D" is in the second chunk processed 
      #        and no other objects (recognised or unrecognised) overwrite 
      #        it.  Therefore, its lifespan will be set to the lifespan 
      #        specified for recognised objects.
      #   ~ c: The last occurrence of "c" is in the second chunk processed 
      #        but "c" will be overwritten by an empty square.  Therefore, 
      #        "c"s lifespan will be set to the time taken to encode two 
      #        unrecognised objects ("F" and "G") and the time taken to 
      #        encode eight/nine empty squares (nine if the scene creator
      #        is encoded).
      #
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # Blind objects on (1, 2) and (2, 3) should be overwritten when the first 
      # and second chunk are processed, respectively.  If ghost objects are 
      # encoded, the blind objects on (1, 3) and (2, 4) will be overwritten when 
      # the first and second chunk are processed, respectively.
      
      # Create list patterns to learn.
      list_pattern_1 = ListPattern.new
      list_pattern_1.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern_1.add(ItemSquarePattern.new("B", 1, 3))
      list_pattern_2 = ListPattern.new
      list_pattern_2.add(ItemSquarePattern.new("D", 2, 3))
      list_pattern_2.add(ItemSquarePattern.new("C", 2, 4))
      list_patterns_to_learn.push(list_pattern_1)
      list_patterns_to_learn.push(list_pattern_2)
      
      # Only the first object in each list pattern learned should be real so add 
      # them to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      reality.addItemToSquare(2, 3, "1", "D")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(0, 2, "2", "F")
      reality.addItemToSquare(3, 2, "3", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "B",
          time_to_encode_objects,
          (time_to_encode_objects * 3) + (time_to_encode_empty_squares * (encode_scene_creator ? 6 : 7)),
          true,
          true
        ])
      end
    
      expected_visual_spatial_field_object_properties[2][3].push([
        "1",
        "D",
        time_to_encode_objects * 2,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[2][4].push([
          VisualSpatialField.getGhostObjectIdPrefix + "1",
          "C",
          (time_to_encode_objects * 2),
          (time_to_encode_objects * 2) + (time_to_encode_empty_squares * (encode_scene_creator ? 8 : 9)),
          true,
          true
        ])
      end
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      squares_to_be_ignored.push(Square.new(2, 3))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      expected_visual_spatial_field_object_properties[2][3][0][3] = (time_to_encode_objects * 2)
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[1][3][0][3] = time_to_encode_objects
        expected_visual_spatial_field_object_properties[2][4][0][3] = (time_to_encode_objects * 2)
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 2
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 8 : 9
      
    ############################################################################
    elsif scenario == 22
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |     |  x     x
      #          ------------------- 
      # 3     x  |     |     |  G  |  x
      #    -------------------------------
      # 2  |     |  A  |     |     |  F  |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     a     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A 1 2][a 0 0]>
      #       
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, one 
      # distinct, recognised VisualSpatialFieldObject instances for object "A" should be 
      # encoded.  If the "encode_ghost_objects" parameter is set to true, one 
      # additional recognised VisualSpatialFieldObject instance for object "a" should be 
      # encoded.
      # 
      # - ID
      #   ~ a: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/a: The first occurrence of "A" and "a" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed).
      #          
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ a: The last occurrence of "a" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it 
      #        since it is located on a blind square in reality and blind
      #        squares can not overwrite ghost objects. Therefore, its 
      #        lifespan will be set to the lifespan specified for recognised 
      #        objects.
      #        
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # The blind object on (1, 2) should be overwritten when the first chunk is 
      # processed.  If ghost objects should be encoded, the blind square on 
      # (0, 0) will also be encoded when the first chunk is processed.
      
      # Create list patterns to learn.
      list_pattern = ListPattern.new
      list_pattern.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern.add(ItemSquarePattern.new("A", 0, 0))
      list_patterns_to_learn.push(list_pattern)
      
      # Only the first object learned should be real so add it to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(4, 2, "2", "F")
      reality.addItemToSquare(3, 3, "3", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[0][0].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "A",
          time_to_encode_objects,
          recognised_object_lifespan,
          true,
          true
        ])
      end
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      
      if(encode_ghost_objects)
        squares_to_be_ignored.push(Square.new(0, 0))
      end
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[0][0][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 1
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 9 : 10
      
    ############################################################################
    elsif scenario == 23
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |  G  |  x     x
      #          ------------------- 
      # 3     x  |     |     |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |  F  |     |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A 1 2][a 2 0]>
      #       
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, one 
      # distinct, recognised VisualSpatialFieldObject instances for object "A" should be 
      # encoded.  If the "encode_ghost_objects" parameter is set to true, one 
      # additional recognised VisualSpatialFieldObject instance for object "a" should be 
      # encoded.
      # 
      # - ID
      #   ~ a: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/a: The first occurrence of "A" and "a" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed).
      #          
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ a: The last occurrence of "a" is in the first chunk processed 
      #        but "a" will be overwritten by an empty square. Therefore, its 
      #        lifespan will be set to the time taken to encode an empty 
      #        square.
      #           
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # The blind object on (1, 2) should be overwritten when the first chunk is 
      # processed.  If ghost objects should be encoded, the blind square on 
      # (2, 0) will also be encoded when the first chunk is processed.
      
      # Create list patterns to learn.
      list_pattern = ListPattern.new
      list_pattern.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern.add(ItemSquarePattern.new("A", 2, 0))
      list_patterns_to_learn.push(list_pattern)
      
      # Only the first object learned should be real so add it to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(3, 2, "2", "F")
      reality.addItemToSquare(2, 4, "3", "G")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[2][0].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "A",
          time_to_encode_objects,
          time_to_encode_empty_squares,
          true,
          true
        ])
      end
      
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[2][0][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 1
      number_unrecognised_objects = 2
      number_empty_squares = encode_scene_creator ? 9 : 10
     
    ############################################################################
    elsif scenario == 24
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |  B  |  x     x
      #          ------------------- 
      # 3     x  |     |     |     |  x
      #    -------------------------------
      # 2  |     |  A  |     |  G  |  F  |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A 1 2][a 2 4]>
      #       
      # ==============================================================
      # Expected VisualSpatialFieldObjects and Properties for Recognised Objects
      # ==============================================================
      # 
      # No matter what the "encode_ghost_objects" parameter is set to, one 
      # distinct, recognised VisualSpatialFieldObject instances for object "A" should be 
      # encoded.  If the "encode_ghost_objects" parameter is set to true, one 
      # additional recognised VisualSpatialFieldObject instance for object "a" should be 
      # encoded.
      # 
      # - ID
      #   ~ a: should equal the result of calling the 
      #        "VisualSpatialField.getGhostObjectIdPrefix()" method with "0" appended 
      #        since it is the first ghost object encoded in the chunks 
      #        recognised.
      #        
      # - Creation times
      #   ~ A/a: The first occurrence of "A" and "a" is in the first chunk 
      #          processed so both objects are encoded at the same time 
      #          (when the first chunk is processed).
      #          
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrite it.  
      #        Therefore, its lifespan will be set to the lifespan specified 
      #        for recognised objects.
      #   ~ a: The last occurrence of "a" is in the first chunk processed 
      #        but "a" will be overwritten by an unrecognised object. Therefore, 
      #        its lifespan will be set to the time taken to encode three 
      #        unrecognised objects ("B", "F" and "G") and eight/nine empty 
      #        squares (eight if the scene creator is encoded).
      #           
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # The blind object on (1, 2) should be overwritten when the first chunk is 
      # processed.  If ghost objects should be encoded, the blind square on 
      # (2, 4) will also be encoded when the first chunk is processed.
      
      # Create list patterns to learn.
      list_pattern = ListPattern.new
      list_pattern.add(ItemSquarePattern.new("A", 1, 2))
      list_pattern.add(ItemSquarePattern.new("A", 2, 4))
      list_patterns_to_learn.push(list_pattern)
      
      # The first object learned should be real so add it to reality.
      reality.addItemToSquare(1, 2, "0", "A")
      
      # Add an object to reality that wasn't learned on the same coordinates as 
      # the ghost object.
      reality.addItemToSquare(2, 4, "1", "B")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(3, 2, "2", "G")
      reality.addItemToSquare(4, 2, "3", "F")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[1][2].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[2][4].push([
          VisualSpatialField.getGhostObjectIdPrefix + "0",
          "A",
          time_to_encode_objects,
          (time_to_encode_objects * 3) + (time_to_encode_empty_squares * (encode_scene_creator ? 8 : 9)),
          true,
          true
        ])
      end
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(1, 2))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[1][2][0][3] = time_to_encode_objects
      
      if(encode_ghost_objects)
        expected_visual_spatial_field_object_properties[2][4][0][3] = time_to_encode_objects
      end
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 1
      number_unrecognised_objects = 3
      number_empty_squares = encode_scene_creator ? 8 : 9
      
    ############################################################################
    elsif scenario == 25
      
      # =============================
      # Expected Visual-Spatial Field
      # =============================
      # 
      #                -------
      # 4     x     x  |  F  |  x     x
      #          ------------------- 
      # 3     x  |     |  A  |     |  x
      #    -------------------------------
      # 2  |     |     | SELF|     |  G  |
      #    -------------------------------
      # 1     x  |     |     |     |  x
      #          -------------------
      # 0     x     x  |     |  x     x
      #                -------
      #       0     1     2     3     4
      #       
      # ======================
      # List Patterns to Learn
      # ======================
      # 
      # <[A 2 3][b 2 2]> (a real object must be encoded so that CHREST attempts 
      # to add the ghost object).
      # 
      # =========================================================
      # Expected VisualSpatialFieldObject Properties for Recognised Objects
      # =========================================================
      # 
      # One distinct, recognised VisualSpatialFieldObject instance for object "A" should 
      # be encoded.  Despite ghost object encoding being enabled, object "a" is 
      # not encoded since it occupies the same coordinates as the Scene 
      # creator's avatar.
      # 
      # - Creation times
      #   ~ A: The first occurrence of "A" is in the first chunk processed so 
      #        it is encoded when the first chunk is processed.
      #        
      # - Terminus times
      #   ~ A: The last occurrence of "A" is in the first chunk processed and 
      #        no other objects (recognised or unrecognised) overwrites it.  
      #        Therefore, its lifespan will be set to its creation time plus 
      #        the lifespan specified for recognised objects.
      # 
      # =======================================================
      # Terminus for Blind Objects on Recognised Object Squares
      # =======================================================
      # 
      # The blind object on (2, 3) should be overwritten when the first chunk is 
      # processed.
      
      # Create list patterns to learn.
      list_pattern = ListPattern.new
      list_pattern.add(ItemSquarePattern.new("A", 2, 3))
      list_pattern.add(ItemSquarePattern.new("B", 2, 2))
      list_patterns_to_learn.push(list_pattern)
      
      # The first object learned should be real so add it to reality.
      reality.addItemToSquare(2, 3, "0", "A")
      
      # Add two unrecognised, non-empty objects to reality.
      reality.addItemToSquare(4, 2, "2", "G")
      reality.addItemToSquare(2, 4, "3", "F")
      
      # Add expected values for recognised VisualSpatialFieldObjects.
      expected_visual_spatial_field_object_properties[2][3].push([
        "0",
        "A",
        time_to_encode_objects,
        recognised_object_lifespan,
        true,
        false
      ])
    
      # Add coordinates to the "squares_to_be_ignored" variable.
      squares_to_be_ignored.push(Square.new(2, 3))
      
      # Set termini for blind objects to be overwritten by recognised objects.
      expected_visual_spatial_field_object_properties[2][3][0][3] = time_to_encode_objects
      
      # Set variables for recognised, unrecognised and empty square counters.
      number_recognised_chunks = 1
      number_unrecognised_objects = 2
      number_empty_squares = 9
    end
    
    # If the scene's creator has been encoded, the patterns contained in the 
    # "list_patterns_to_learn" array should have creator-specific coordinates
    # since, when learning, CHREST will translate the locations of objects so 
    # they are relative to the location of the creator in the Scene.   
    # 
    # If this isn't done, tests that make use of the data prepared in this 
    # function will not complete since they check the string representations of 
    # what is being learned against what is learned to control progression 
    # through the test itself.  For example, if reality has the creator's 
    # location encoded but the coordinates of objects to learn in the 
    # "list_patterns_to_learn" array are not translated into creator-relative 
    # coordinates then, the strings compared will be something like:
    # 
    # TO BE LEARNED        LEARNED
    # <[A 1 2][B 1 3]>     <[A -1 0][B -1 1]> 
    # 
    # This results in an infinite loop of learning within a test even though the
    # object coordinates indicate the same absolute location.
    if(encode_scene_creator)
      for i in 0...list_patterns_to_learn.count
        list_pattern_with_translated_coords = ListPattern.new
        for pattern in list_patterns_to_learn[i]
          list_pattern_with_translated_coords.add(ItemSquarePattern.new(pattern.getItem(), pattern.getColumn() - 2, pattern.getRow() - 2))
        end
        list_patterns_to_learn[i] = list_pattern_with_translated_coords
      end
    end
    
    #Populate the "scenario_data" array with the last scenario data set 
    #constructed.
    scenario_data.push([
      reality, 
      list_patterns_to_learn,
      number_recognised_chunks,
      expected_visual_spatial_field_object_properties,
      squares_to_be_ignored,
      number_unrecognised_objects,
      number_empty_squares
    ])
  end
  
  return scenario_data
end

# This function performs a number of actions:
# 
# 1) Adds expected VisualSpatialFieldObject values for visual-spatial squares that should 
#    be empty.
# 2) Adds expected VisualSpatialFieldObject values for visual-spatial squares that should 
#    contain unrecognised, real objects.
# 3) Sets terminus values for blind objects that are placed initially on the
#    visual-spatial squares referenced in the first two actions.
# 4) Calculates the number of empty squares on the scene encoded.
# 5) Calculates the number of unrecognised objects on the scene encoded. 
# 
# Unless a coordinate is present in the "squares_to_be_ignored" data structure,
# a square represented in the current expected VisualSpatialFieldObject values data 
# structure will have actions 1-3 applied to it.
# 
# The function returns an array consisting of three elements:
# 
# 1) The modified data structure containing expected VisualSpatialFieldObject values.
# 2) The number of unrecognised objects present on the Scene passed as a 
#    parameter.
# 3) The number of empty squares present on the Scene passed as a parameter.
# 
def add_expected_values_for_unrecognised_visual_spatial_objects(
    scene_encoded_into_visual_spatial_field, 
    expected_visual_spatial_field_object_properties, 
    squares_to_be_ignored,
    time_to_encode_objects,
    time_to_encode_empty_squares,
    unrecognised_object_lifespan,
    number_chunks_recognised 
  )
    #First, overwrite all Square instances in the "squares_to_ignore" data 
    #structure with their String representations so that it can be determined if 
    #a square should be processed in the loop below (the "include?" statement 
    #will always evaluate to false otherwise since it will compare object 
    #references rather than the actual coordinates specified).
    for i in 0...squares_to_be_ignored.count
      squares_to_be_ignored[i] = squares_to_be_ignored[i].toString()
    end
    
    #For any coordinates that shouldn't be ignored:
    #
    # 1) Check if the square indicated by the coordinates in the scene encoded
    #    into the visual-spatial field should be blind.  If so, skip to the next
    #    coordinates. 
    # 2) If the square indicated by the coordinates in the scene encoded
    #    into the visual-spatial field shouldn't be blind and shouldn't be 
    #    ignored, set the terminus for the first blind object on the square, if 
    #    this hasn't been done already (the terminus for such an object should 
    #    be set if there is a ghost object on the square that will be 
    #    overwritten by an empty square).
    # 3) Add a new data structure containing the expected object values for the
    #    unrecognised object to be added to the square (the object to be added
    #    is determined by checking the contents of this square in the scene that 
    #    has been encoded into the visual-spatial field consequently, this may
    #    only be either an empty square or an unreocgnised object) and set its 
    #    values accordingly:
    #    - ID: should equal the ID of the SceneObject that exists on this square
    #          in the Scene that has been encoded into the visual-spatial field.
    #    - Class: should equal the class of the SceneObject that exists on this 
    #             square in the Scene that has been encoded into the 
    #             visual-spatial field.
    #    - Creation time: dependent on number of unrecognised objects and empty
    #                     squares encountered thus far.  Note that the main loop
    #                     here processes squares from west -> east and south -> 
    #                     north to ensure that creation time setting is correct
    #                     (this is the order in which unrecognised objects and
    #                     empty squares are encoded during visual-spatial 
    #                     construction).
    #    - Terminus: should always be equal to the specified unrecognised object
    #                lifespan since these objects shouldn't be overwritten.
    #    - Recognised status: should be false.
    #    - Ghost status: should be false.
    number_empty_squares = 0
    number_unrecognised_objects = 0
    for row in 0...scene_encoded_into_visual_spatial_field.getHeight()
      for col in 0...scene_encoded_into_visual_spatial_field.getWidth()
        
        if( !squares_to_be_ignored.include?(Square.new(col, row).toString()) )
          object_on_square_in_scene_encoded = scene_encoded_into_visual_spatial_field.getSquareContents(col, row)
          class_of_object_on_square_in_reality = object_on_square_in_scene_encoded.getObjectClass
          
          if(class_of_object_on_square_in_reality != Scene.getBlindSquareIdentifier())
            
            if(class_of_object_on_square_in_reality == Scene.getEmptySquareIdentifier())
              number_empty_squares += 1
            elsif(class_of_object_on_square_in_reality != Scene.getCreatorToken())
              number_unrecognised_objects += 1
            end
            
            if(class_of_object_on_square_in_reality == Scene.getCreatorToken())
              expected_visual_spatial_field_object_properties[col][row][0] = [
                object_on_square_in_scene_encoded.getIdentifier(),
                class_of_object_on_square_in_reality,
                0,
                nil,
                false,
                false
              ]
            else
              #If the blind object identifier on this square hasn't already had
              #its terminus set, do so now.
              if (expected_visual_spatial_field_object_properties[col][row][0][3] == nil)
                expected_visual_spatial_field_object_properties[col][row][0][3] = (time_to_encode_objects * (number_chunks_recognised + number_unrecognised_objects)) + (time_to_encode_empty_squares * number_empty_squares)
              end

              expected_visual_spatial_field_object_properties[col][row].push([
                object_on_square_in_scene_encoded.getIdentifier(),
                class_of_object_on_square_in_reality,
                (time_to_encode_objects * (number_chunks_recognised + number_unrecognised_objects)) + (time_to_encode_empty_squares * number_empty_squares),
                unrecognised_object_lifespan,
                false,
                false
              ])
            end
          end
        end
      end
    end
    
    return expected_visual_spatial_field_object_properties
  end
  
def get_visual_spatial_field_instantiation_complete_time(creation_time, visual_spatial_field_access_time, time_to_encode_objects, time_to_encode_empty_squares, number_recognised_chunks, number_unrecognised_objects, number_empty_squares)
  return creation_time +
    visual_spatial_field_access_time + 
    (time_to_encode_objects * number_recognised_chunks) + 
    (time_to_encode_objects * number_unrecognised_objects) + 
    (time_to_encode_empty_squares * number_empty_squares)
end

def check_values_of_visual_spatial_objects_against_expected(visual_spatial_field, expected_visual_spatial_field_object_properties, time_to_check_recognised_status_against, test_description)

  for row in 0...visual_spatial_field.getSceneEncoded().getHeight()
    for col in 0...visual_spatial_field.getSceneEncoded().getWidth()

      visual_spatial_field_objects = visual_spatial_field.getSquareContents(col, row)
      assert_equal(expected_visual_spatial_field_object_properties[col][row].count(), visual_spatial_field_objects.size(), "occurred when checking the number of items on col " + col.to_s + ", row " + row.to_s + " " + test_description)

      for i in 0...visual_spatial_field_objects.size()
        error_message_postscript = " for object " + i.to_s  + " on col " + col.to_s + ", row " + row.to_s + "."
        expected_visual_spatial_field_object = expected_visual_spatial_field_object_properties[col][row][i]
        visual_spatial_field_object = visual_spatial_field_objects[i]
        assert_equal(expected_visual_spatial_field_object[0], visual_spatial_field_object.getIdentifier(), "occurred when checking the identifier" + error_message_postscript + " " + test_description)
        assert_equal(expected_visual_spatial_field_object[1], visual_spatial_field_object.getObjectClass(), "occurred when checking the object class" + error_message_postscript + " " + test_description)
        assert_equal(expected_visual_spatial_field_object[2], visual_spatial_field_object.getTimeCreated(), "occurred when checking the creation time" + error_message_postscript + " " + test_description)
        assert_equal(expected_visual_spatial_field_object[3], visual_spatial_field_object.getTerminus(), "occurred when checking the terminus" + error_message_postscript + " " + test_description)
        assert_equal(expected_visual_spatial_field_object[4], visual_spatial_field_object.recognised(time_to_check_recognised_status_against), "occurred when checking the recognised status" + error_message_postscript + " " + test_description)
        assert_equal(expected_visual_spatial_field_object[5], visual_spatial_field_object.isGhost(), "occurred when checking the ghost status" + error_message_postscript + " " + test_description)
      end
    end
  end
end
