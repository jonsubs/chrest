package jchrest.architecture;

import jchrest.lib.*;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Observable;

/**
 * The parent class for an instance of a Chrest model.
 *
 * @author Peter C. R. Lane
 */
public class Chrest extends Observable {
  // Domain definitions, if used
  private DomainSpecifics _domainSpecifics;
  // internal clock
  private int _clock;  
  // timing parameters
  private int _addLinkTime;
  private int _discriminationTime;
  private int _familiarisationTime;
  // rho is the probability that a given learning operation will occur
  private float _rho;
  // parameter for construction of similarity link
  // - determines number of overlapping items in node images
  private int _similarityThreshold;
  // template construction parameters
  private boolean _createTemplates;
  private int _minTemplateLevel = 3;
  private int _minTemplateOccurrences = 2;
  // long-term-memory holds information within the model permanently
  private int _totalNodes;
  private Node _visualLtm;
  private Node _verbalLtm;
  private Node _actionLtm;
  // short-term-memory holds information within the model temporarily, usually within one experiment
  private final Stm _visualStm;
  private final Stm _verbalStm;
  private final Stm _actionStm; // TODO: Incorporate into displays
  // Perception module
  private final Perceiver _perceiver;

  public Chrest () {
    _domainSpecifics = new GenericDomain ();
    _addLinkTime = 10000;
    _discriminationTime = 10000;
    _familiarisationTime = 2000;
    _rho = 1.0f;
    _similarityThreshold = 3;

    _clock = 0;
    _totalNodes = 0;
    _visualLtm = new Node (this, 0, Pattern.makeVisualList (new String[]{"Root"}));
    _verbalLtm = new Node (this, 0, Pattern.makeVerbalList (new String[]{"Root"}));
    _actionLtm = new Node (this, 0, Pattern.makeActionList (new String[]{"Root"}));
    _totalNodes = 0; // Node constructor will have incremented _totalNodes, so reset to 0
    _visualStm = new Stm (4);
    _verbalStm = new Stm (2);
    _actionStm = new Stm (4);

    _createTemplates = true;
    _perceiver = new Perceiver (this);
  }

  /**
   * Retrieve the model's current domain specification.
   */
  public DomainSpecifics getDomainSpecifics () {
    return _domainSpecifics;
  }

  /**
   * Set the domain specification.
   */
  public void setDomain (DomainSpecifics domain) {
    _domainSpecifics = domain;
  }

  /**
   * Accessor to retrieve time to add a new link.
   */
  public int getAddLinkTime () {
    return _addLinkTime;
  }

  /**
   * Modify time to add a new link.
   */
  public void setAddLinkTime (int time) {
    _addLinkTime = time;
  }

  /**
   * Accessor to retrieve time to discriminate a new node.
   */
  public int getDiscriminationTime () {
    return _discriminationTime;
  }

  /**
   * Modify time to discriminate a new node.
   */
  public void setDiscriminationTime (int time) {
    _discriminationTime = time;
  }

  /**
   * Accessor to retrieve time to familiarise image of a node.
   */
  public int getFamiliarisationTime () {
    return _familiarisationTime;
  }

  /**
   * Modify time to familiarise image of a node.
   */
  public void setFamiliarisationTime (int time) {
    _familiarisationTime = time;
  }

  /**
   * Accessor to retrieve value of rho, the probability of learning an item.
   */
  public float getRho () {
    return _rho;
  }

  /**
   * Modify value of rho, the probability of learning an item.
   */
  public void setRho (float rho) {
    _rho = rho;
  }

  /**
   * Accessor to retrieve value of similarity threshold, the number of items 
   * which must be shared between two images for a similarity link to be formed.
   */
  public float getSimilarityThreshold () {
    return _similarityThreshold;
  }

  /**
   * Modify value of similarity threshold.
   */
  public void setSimilarityThreshold (int threshold) {
    _similarityThreshold = threshold;
  }

  /**
   * Modify option to create templates.
   */
  public void setCreateTemplates (boolean value) {
    _createTemplates = value;
  }

  /**
   * Accessor to option of whether to create templates.
   */
  public boolean getCreateTemplates () {
    return _createTemplates;
  }

  /**
   * Accessor to value of minimum template level.
   */
  protected int getMinTemplateLevel () {
    return _minTemplateLevel;
  }

  /**
   * Accessor to minimum require occurrences for forming template.
   */
  protected int getMinTemplateOccurrences () {
    return _minTemplateOccurrences;
  }

  /**
   * Modify values for template construction.
   */
  public void setTemplateConstructionParameters (int minLevel, int minOccurrences) {
    _minTemplateLevel = minLevel;
    _minTemplateOccurrences = minOccurrences;
  }

  /**
   * Accessor to retrieve the size of visual short-term memory.
   */
  public int getVisualStmSize () {
    return _visualStm.getSize ();
  }

  /**
   * Modify size of visual short-term memory.
   */
  public void setVisualStmSize (int size) {
    _visualStm.setSize (size);
    setChanged ();
    if (!_frozen) notifyObservers ();
  }

  /**
   * Accessor to retrieve the size of verbal short-term memory.
   */
  public int getVerbalStmSize () {
    return _verbalStm.getSize ();
  }

  /**
   * Modify size of verbal short-term memory.
   */
  public void setVerbalStmSize (int size) {
    _verbalStm.setSize (size);
    setChanged ();
    if (!_frozen) notifyObservers ();
  }

  /**
   * Accessor to retrieve current time of model.
   */
  public int getClock () {
    return _clock;
  }

  /**
   * Advance the clock by given amount.
   */
  public void advanceClock (int time) {
    _clock += time;
    setChanged ();
  }

  /**
   * Retrieve the next available node number.
   * Package access only, as should only be used by Node.java.
   */
  int getNextNodeNumber () {
    _totalNodes += 1;
    return _totalNodes;
  }

  /**
   * Accessor to retrieve the total number of nodes within LTM.
   */
  public int getTotalLtmNodes () {
    return _totalNodes;
  }

  /**
   * Accessor to retrieve visual short-term memory of model.
   */
  public Stm getVisualStm () {
    return _visualStm;
  }

  /**
   * Accessor to retrieve verbal short-term memory of model.
   */
  public Stm getVerbalStm () {
    return _verbalStm;
  }

  /**
   * Accessor to retrieve visual long-term memory of model.
   */
  public Node getVisualLtm () {
    return _visualLtm;
  }

  /** 
   * Return a count of the number of nodes in visual long-term memory.
   */
  public int ltmVisualSize () {
    return _visualLtm.size ();
  }

  /**
   * Return the average depth of nodes in visual long-term memory.
   */
  public double getVisualLtmAverageDepth () {
    return _visualLtm.averageDepth ();
  }

  /**
   * Return the average image size of nodes in visual long-term memory.
   */
  public double getVisualLtmAverageImageSize () {
    return _visualLtm.averageImageSize ();
  }

  /**
   * Return a count of the number of nodes in verbal long-term memory.
   */
  public int ltmVerbalSize () {
    return _verbalLtm.size ();
  }

  /**
   * Return the average depth of nodes in verbal long-term memory.
   */
  public double getVerbalLtmAverageDepth () {
    return _verbalLtm.averageDepth ();
  }

  /**
   * Return a count of the number of nodes in action long-term memory.
   */
  public int ltmActionSize () {
    return _actionLtm.size ();
  }

  /**
   * Return the average depth of nodes in action long-term memory.
   */
  public double getActionLtmAverageDepth () {
    return _actionLtm.averageDepth ();
  }

  /**
   * Instruct model to construct templates, if the 'constructTemplates' flag is true.  
   * This method should be called at the end of the learning process.
   * Note, the template construction process only currently works for visual patterns 
   * using the ItemSquarePattern primitive.
   */
  public void constructTemplates () {
    if (_createTemplates) {
      _visualLtm.constructTemplates ();
    }
  }

  /**
   * Return a count of the number of templates in the model's visual LTM.
   */
  public int countTemplates () {
    return _visualLtm.countTemplates ();
  }

  /**
   * Return the root node of the long-term memory which the given pattern
   * would be sorted through, based on its modality.
   */
  public Node getLtmByModality (ListPattern pattern) {
    if (pattern.isVisual ()) {
      return _visualLtm;
    } else if (pattern.isVerbal ()) {
      return _verbalLtm;
    } else { // if (pattern.isAction ()) 
      return _actionLtm;
    }
  }

  private Stm getStmByModality (ListPattern pattern) {
    if (pattern.isVisual ()) {
      return _visualStm;
    } else if (pattern.isVerbal ()) {
      return _verbalStm;
    } else { // if (pattern.isAction ()) 
      return _actionStm;
    }
  }

  // use to freeze/unfreeze updates to the model to prevent GUI
  // seizing up during training
  private boolean _frozen = false;
  
  /**
   * Instruct model not to update observers.
   */
  public void freeze () {
    _frozen = true;
  }

  /**
   * Instruct model to now update observers for future changes.
   * Also triggers an immediate update of current observers.
   */
  public void unfreeze () {
    _frozen = false;
    setChanged ();
    notifyObservers ();
  }

  /**
   * Return a map from content sizes to frequencies for the model's LTM.
   */ 
  public Map<Integer, Integer> getContentCounts () {
    Map<Integer, Integer> size = new HashMap<Integer, Integer> ();

    _visualLtm.getContentCounts (size);
    _verbalLtm.getContentCounts (size);
    _actionLtm.getContentCounts (size);

    return size;
  }

  /**
   * Return a map from image sizes to frequencies for the model's LTM.
   */ 
  public Map<Integer, Integer> getImageCounts () {
    Map<Integer, Integer> size = new HashMap<Integer, Integer> ();

    _visualLtm.getImageCounts (size);
    _verbalLtm.getImageCounts (size);
    _actionLtm.getImageCounts (size);

    return size;
  }

  /**
   * Return a map from number of similarity nodes to frequencies for the model's LTM.
   */ 
  public Map<Integer, Integer> getSimilarityCounts () {
    Map<Integer, Integer> size = new HashMap<Integer, Integer> ();

    _visualLtm.getSimilarityCounts (size);
    _verbalLtm.getSimilarityCounts (size);
    _actionLtm.getSimilarityCounts (size);

    return size;
  }

  /**
   * Add given node to STM.  Check for formation of similarity links by
   * comparing incoming node with the hypothesis, or 'largest', node.
   */
  private void addToStm (Node node) {
    Stm stm = getStmByModality (node.getImage ());

    if (stm.getCount () > 0) {
      Node check = stm.getItem (0); // TODO: make this the hypothesis node
      if (check != node && 
          node.getImage().isSimilarTo (check.getImage (), _similarityThreshold)) {
        node.addSimilarNode (check); 
        check.addSimilarNode (node); // two-way similarity link
      }
    }

    // TODO: Check if this is the best place
    // Idea is that node's filled slots are cleared when put into STM, 
    // are filled whilst in STM, and forgotten when it leaves.
    node.clearFilledSlots (); 
    stm.add (node);

    // inform observers of a change in model's state
    setChanged ();
    if (!_frozen) notifyObservers ();
  }

  /**
   * Accessor to retrieve the model's perceiver object.
   */
  public Perceiver getPerceiver () {
    return _perceiver;
  }

  /** 
   * Retrieve a node in long-term memory using the given ListPattern.
   * The sorting process works through the children of the currentNode.
   * If the link's test matches the remaining part of the pattern, then 
   * the current node is updated, and searching continues through the 
   * children of the new node.
   */
  public Node recognise (ListPattern pattern) {
    Node currentNode = getLtmByModality (pattern);
    List<Link> children = currentNode.getChildren ();
    ListPattern sortedPattern = pattern;
    int nextLink = 0;

    while (nextLink < children.size ()) {
      Link link = children.get (nextLink);
      if (link.passes (sortedPattern)) { // descend a test link in network
        // reset the current node, list of children and link index
        currentNode = link.getChildNode ();
        children = link.getChildNode ().getChildren ();
        nextLink = 0;
        // remove the matched test from the sorted pattern
        sortedPattern = sortedPattern.remove (link.getTest ());
      } else { // move on to the next link on same level
        nextLink += 1;
      }
    }

    // see if more informative node in similarity links
    // TODO: Explore if this should be used during training
    //       leads to small image size, but quickly produces big networks
//    for (Node similar : currentNode.getSimilarNodes ()) {
//      if (similar.information () > currentNode.information ()) {
//        currentNode = similar;
//      }
//    }

    // add retrieved node to STM
    addToStm (currentNode);

    // return retrieved node
    return currentNode;
  }

  /** 
   * Use given ListPattern to perform a step of learning within the network.
   * First, the pattern is sorted.  Then, if the retrieved node is the 
   * root node or its image mismatches the pattern, discrimination is 
   * used to extend the network.  Otherwise, new information will be added 
   * to the image using the pattern.
   */
  public Node recogniseAndLearn (ListPattern pattern, int time) {
    Node currentNode = recognise (pattern);
    if (_clock <= time) { // only try to learn if model clock is 'behind' the time of the call
      if (Math.random () < _rho) { // depending on _rho, may refuse to learn some random times
        _clock = time; // bring clock up to date
        if (!currentNode.getImage().equals (pattern)) { // only try any learning if image differs from pattern
          if (currentNode == getLtmByModality (pattern) || // if is rootnode
              !currentNode.getImage().matches (pattern) || // or mismatch on image
              currentNode.getImage().isFinished ()) {      // or image finished
            currentNode = currentNode.discriminate (pattern); // then discriminate
          } else  { // else familiarise
            currentNode = currentNode.familiarise (pattern);
          }
          addToStm (currentNode); // add to stm, as node may have changed during learning
        }
      }
    }
    return currentNode;
  }

  public Node recogniseAndLearn (ListPattern pattern) {
    return recogniseAndLearn (pattern, _clock);
  }

  /**
   * Asks Chrest to return the image of the node obtained by sorting given 
   * pattern through the network.
   */
  public ListPattern recallPattern (ListPattern pattern) {
    return recognise(pattern).getImage ();
  }

  /** 
   * Asks Chrest to return the image of the node which follows the node 
   * obtained by sorting given pattern through the network.
   */
  public ListPattern followPattern (ListPattern pattern) {
    Node retrievedNode = recognise (pattern);
    if (retrievedNode.getFollowedBy () != null) {
      return retrievedNode.getFollowedBy().getImage ();
    } else {
      return null;
    }
  }

  /**
   * Asks Chrest to return the image of the node which names the node 
   * obtained by sorting given pattern through the network.
   */
  public ListPattern namePattern (ListPattern pattern) {
    Node retrievedNode = recognise (pattern);
    if (retrievedNode.getNamedBy () != null) {
      return retrievedNode.getNamedBy().getImage ();
    } else {
      return null;
    }
  }

  /**
   * Presents Chrest with a pair of patterns, which it should learn and 
   * then attempt to learn a link.
   */
  public void learnAndLinkPatterns (ListPattern pattern1, ListPattern pattern2, int time) {
    recogniseAndLearn (pattern1, time);
    recogniseAndLearn (pattern2, time);
    if (_clock <= time) {
      if (pattern1.isVisual ()) {
        _visualStm.learnLateralLinks (this);
      } else if (pattern1.isVerbal ()) {
        _verbalStm.learnLateralLinks (this);
      } else { // if (pattern1.isAction ())
        _actionStm.learnLateralLinks (this);
      }
      setChanged ();
      if (!_frozen) notifyObservers ();
    }
  }

  /**
   * Learns the two patterns assuming the time of presentation is the current 
   * Chrest clock time.
   */
  public void learnAndLinkPatterns (ListPattern pattern1, ListPattern pattern2) {
    learnAndLinkPatterns (pattern1, pattern2, _clock);
  }

  /**
   * Learn and link a visual and verbal pattern with a naming link.
   */
  public void learnAndNamePatterns (ListPattern pattern1, ListPattern pattern2, int time) {
    recogniseAndLearn (pattern1, time);
    recogniseAndLearn (pattern2, time);
    if (_clock <= time) {
      if (pattern1.isVisual () && pattern2.isVerbal () && _visualStm.getCount () > 0 && _verbalStm.getCount () > 0) {
        _visualStm.getItem(0).setNamedBy (_verbalStm.getItem (0));
        advanceClock (getAddLinkTime ());
      }
      setChanged ();
      if (!_frozen) notifyObservers ();
    }
  }

  public void learnAndNamePatterns (ListPattern pattern1, ListPattern pattern2) {
    learnAndNamePatterns (pattern1, pattern2, _clock);
  }

  public void learnScene (Scene scene, int numFixations) {
    _perceiver.setScene (scene);
    _perceiver.start ();
    for (int i = 0; i < numFixations; i++) {
      _perceiver.moveEyeAndLearn ();
    }
  }

  /** 
   * Scan given scene, then return a scene which would be recalled.
   * Default behaviour is to clear STM before scanning a scene.
   */
  public Scene scanScene (Scene scene, int numFixations) {  
    return scanScene (scene, numFixations, true);
  }
  
  /** 
   * Scan given scene, then return a scene which would be recalled.
   */
  public Scene scanScene (Scene scene, int numFixations, boolean clearStm) {
    if (clearStm) { // only clear STM if flag is set
      _visualStm.clear ();
    }
    _perceiver.setScene (scene);
    _perceiver.start ();
    for (int i = 0; i < numFixations; i++) {
      _perceiver.moveEye ();
    }
    // build up and return recalled scene
    Scene recalledScene = new Scene ("Recalled scene of " + scene.getName (), 
        scene.getHeight (), scene.getWidth ());
    // -- get items from image in STM, and optionally template slots
    // TODO: use frequency count in recall
    for (Node node : _visualStm) {
      ListPattern recalledInformation = node.getImage();
      if (_createTemplates) { // check if templates needed
        recalledInformation = recalledInformation.append(node.getFilledSlots ());
      }
      for (PrimitivePattern item : recalledInformation) {
        if (item instanceof ItemSquarePattern) {
          ItemSquarePattern ios = (ItemSquarePattern)item;
          recalledScene.setItem (ios.getRow ()-1, ios.getColumn ()-1, ios.getItem ());
        }
      }
    }

    return recalledScene;
  }

  /** 
   * Clear the STM and LTM of the model.
   */
  public void clear () {
    _clock = 0;
    _visualLtm.clear ();
    _verbalLtm.clear ();
    _actionLtm.clear ();
    _visualLtm = new Node (this, 0, Pattern.makeVisualList (new String[]{"Root"}));
    _verbalLtm = new Node (this, 0, Pattern.makeVerbalList (new String[]{"Root"}));
    _actionLtm = new Node (this, 0, Pattern.makeActionList (new String[]{"Root"}));
    _totalNodes = 0;
    _visualStm.clear ();
    _verbalStm.clear ();
    setChanged ();
    if (!_frozen) notifyObservers ();
  }

  public String getHeuristicDescription () {
    return _perceiver.getHeuristicDescription ();
  }

  /** 
   * Write model to given Writer object in VNA format
   */
  public void writeModelAsVna (Writer writer) throws IOException {
    writer.write ("*Node data\n\"ID\", \"contents\"\n");
    _visualLtm.writeNodeAsVna (writer);
    writer.write ("*Tie data\nFROM TO\n");
    _visualLtm.writeLinksAsVna (writer);
  }

  /** 
   * Write model similarity links to given Writer object in VNA format
   */
  public void writeModelSimilarityLinksAsVna (Writer writer) throws IOException {
    writer.write ("*Node data\n\"ID\", \"contents\"\n");
    _visualLtm.writeNodeAsVna (writer);
    writer.write ("*Tie data\nFROM TO\n");
    _visualLtm.writeSimilarityLinksAsVna (writer);
  }
}
