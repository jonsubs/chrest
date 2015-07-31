// Copyright (c) 2012, Peter C. R. Lane
// Released under Open Works License, http://owl.apotheon.org/

package jchrest.lib;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import jchrest.architecture.Chrest;

/**
  * The GenericDomain is used when no domain-specific methods have been created.
  */
public class GenericDomain extends DomainSpecifics {
  
  public GenericDomain(Chrest model) {
    super(model);
  }
  
  /**
   * Remove self and empty identifiers along with duplicates from pattern passed 
   * since: 
   * 1) The creator will never need to learn its own location given that 
   *    everything will be relative to it if it exists in the pattern passed
   * 2) Empty identifiers are useless
   * 3) Duplicates are useless.
   */
  public ListPattern normalise (ListPattern pattern) {
    ListPattern result = new ListPattern(pattern.getModality());
    
    for(PrimitivePattern prim : pattern){
      if(prim instanceof ItemSquarePattern){
        ItemSquarePattern itemSquarePrim = (ItemSquarePattern)prim;
        String identifier = itemSquarePrim.getItem();
        if( 
          !identifier.equalsIgnoreCase(Scene.getSelfIdentifier()) &&
          !identifier.equals(Scene.getEmptySquareIdentifier()) && 
          !result.contains(prim)
        ){
          result.add(prim);
        } 
      }
      else{
        result.add(prim);
      }
    }
    result.setFinished();
    
    if(this._associatedModel != null){
      HashMap<String, Object> historyRowToInsert = new HashMap<>();
      
      //Generic operation name setter for current method.  Ensures for the row to 
      //be added that, if this method's name is changed, the entry for the 
      //"Operation" column in the execution history table will be updated without 
      //manual intervention and "Filter By Operation" queries run on the execution 
      //history DB table will still work.
      class Local{};
      historyRowToInsert.put(Chrest._executionHistoryTableOperationColumnName, 
        ExecutionHistoryOperations.getOperationString(this.getClass(), Local.class.getEnclosingMethod())
      );
      historyRowToInsert.put(Chrest._executionHistoryTableInputColumnName, pattern.toString() + "(" + pattern.getModalityString() + ")");
      historyRowToInsert.put(Chrest._executionHistoryTableOutputColumnName, result.toString() + "(" + result.getModalityString() + ")");
      this._associatedModel.addEpisodeToExecutionHistory(historyRowToInsert);
    }
    
    return result;
  }

  /** 
   * Return a random square on scene that isn't blind or empty.
   * @param scene
   * @param model
   * @return 
   */
  public Set<Square> proposeSalientSquareFixations (Scene scene, Chrest model) {
    Set<Square> result = new HashSet<Square> ();
    
    int randomCol = new java.util.Random().nextInt(scene.getWidth ());
    int randomRow = new java.util.Random().nextInt(scene.getHeight ());
    
    while( scene.getItemsOnSquareAsListPattern(randomCol, randomRow, false, false).isEmpty() ){
      randomCol = new java.util.Random().nextInt(scene.getWidth ());
      randomRow = new java.util.Random().nextInt(scene.getHeight ());
    }
    
    result.add (new Square(randomCol, randomRow));
    return result;
  }

  /**
   * No possible movement fixations, so return empty list of proposals.
   */
  public List<Square> proposeMovementFixations (Scene scene, Square square) {
    return new ArrayList<Square> ();
  }

  @Override
  public int getCurrentTime() {
    throw new UnsupportedOperationException("Not supported yet.");
  }
}
