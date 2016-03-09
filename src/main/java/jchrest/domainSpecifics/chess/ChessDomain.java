// Copyright (c) 2012, Peter C. R. Lane
// Released under Open Works License, http://owl.apotheon.org/

package jchrest.lib;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import jchrest.architecture.Chrest;

/**
  * The ChessDomain is used for chess modelling.
  */
public class ChessDomain extends DomainSpecifics {
  
  public ChessDomain(Chrest model) {
    super(model);
  }

  // map stores the canonical order of the chess pieces
  private static Map<String, Integer> pieceOrder;
  static {
    pieceOrder = new HashMap<String, Integer> ();
    pieceOrder.put("P", 0);
    pieceOrder.put("p", 1);
    pieceOrder.put("K", 2);
    pieceOrder.put("k", 3);
    pieceOrder.put("B", 4);
    pieceOrder.put("b", 5);
    pieceOrder.put("N", 6);
    pieceOrder.put("n", 7);
    pieceOrder.put("Q", 8);
    pieceOrder.put("q", 9);
    pieceOrder.put("R", 10);
    pieceOrder.put("r", 11);
  }

  /**
   * Sort given list pattern into a canonical order of chess pieces, as 
   * defined in deGroot and Gobet (1996).
   * The order is:  P p K k B b N n Q q R r 
   * If the pieces are the same, then order is based on column, and then on row.
   * @param pattern
   * @return 
   */
  @Override
  public ListPattern normalise (ListPattern pattern) {
    ListPattern result = new ListPattern (pattern.getModality ());
    
    // remove any duplicates from 'pattern'
    for (PrimitivePattern prim : pattern) {
      if (!result.contains (prim)) {
        result = result.append (prim);
      }
    }
    
    // and sort into canonical order before returning
    result = result.sort (new Comparator<PrimitivePattern> () {
      @Override
      public int compare (PrimitivePattern left, PrimitivePattern right) {
        assert (left instanceof ItemSquarePattern);
        assert (right instanceof ItemSquarePattern);
        ItemSquarePattern leftIos = (ItemSquarePattern)left;
        ItemSquarePattern rightIos = (ItemSquarePattern)right;

        // check item
        if (pieceOrder.get (leftIos.getItem()) < pieceOrder.get (rightIos.getItem ())) return -1;
        if (pieceOrder.get (leftIos.getItem()) > pieceOrder.get (rightIos.getItem ())) return 1;
        // check column
        if (leftIos.getColumn () < rightIos.getColumn ()) return -1;
        if (leftIos.getColumn () > rightIos.getColumn ()) return 1;
        // check row
        if (leftIos.getRow () < rightIos.getRow ()) return -1;
        if (leftIos.getRow () > rightIos.getRow ()) return 1;
        return 0;
      }
    });
    
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
   * Use level of expertise to determine salient square fixations.
   * @param scene
   * @param model
   * @return 
   */
  @Override
  public Set<Square> proposeSalientSquareFixations (Scene scene, Chrest model, int time) {
    return (model.isExperienced (time) ? getOffensivePieces (scene) : getBigPieces (scene));
  }

  /**
   * Construct a chess board given a string definition.
   * Order should be in FEN style, with row 8 (black side) first.
   * Empty square indicated with full stop - counts of empty squares not permitted.
   * @param definition
   * @return 
   */
  public static Scene constructBoard (String definition) {
    assert (definition.length () == 71);
    Scene board = new Scene ("chess-board", 8, 8, null);

    for (int col = 0; col < 8; ++col) {
      for (int row = 0; row < 8; ++row) {
        String piece = definition.substring (col + 9*row, 1 + col + 9*row);
        String uniqueIdentifier = String.valueOf(col + 9*row);
        
        board.addItemToSquare (col, row, uniqueIdentifier, piece);
      }
    }

    return board;
  }

  /**
   * Returns the set of big pieces in given scene.
   * A 'big piece' is anything other than a pawn.  
   * Used to indicate a salient piece for a novice chess player.
   * @param scene
   * @return 
   */
  public Set<Square> getBigPieces (Scene scene) {
    Set<Square> result = new HashSet<Square> ();

    for (int i = 0; i < scene.getWidth (); ++i) {
      for (int j = 0; j < scene.getHeight (); ++j) {
        if (!scene.isSquareEmpty (i, j) && !scene.isSquareBlind(i, j)) {
          ListPattern itemsOnSquare = scene.getSquareContentsAsListPattern(i, j, true);
          for(PrimitivePattern itemOnSquare : itemsOnSquare){
            ItemSquarePattern ios = (ItemSquarePattern)itemOnSquare;
            if( !ios.getItem().equals("P") && !ios.getItem().equals("p") ){
              result.add (new Square (i, j));
            }
          }
        }
      }
    }

    return result;
  }

  /**
   * Return the set of offensive pieces in given scene.
   * An 'offensive piece' is a piece on the other player's side.
   * e.g. a black piece on white's side of the board.
   * Used to indicate a salient piece for an inexperienced chess player.
   * @param scene
   * @return 
   */
  public Set<Square> getOffensivePieces (Scene scene) {
    Set<Square> result = new HashSet<Square> ();

    for (int i = 0; i < scene.getWidth (); ++i) {
      for (int j = 0; j < scene.getHeight (); ++j) {
        if(!scene.isSquareBlind(i, j)){
          ListPattern itemsOnSquare = scene.getSquareContentsAsListPattern(i, j, true);
          for(PrimitivePattern itemOnSquare : itemsOnSquare){
            ItemSquarePattern ios = (ItemSquarePattern)itemOnSquare;
            
            //If algebraic chess notation is being used the char conversion here
            //should be OK.
            char piece = ios.getItem().charAt(0);
            if (Character.isLowerCase (piece) && j >= 4) { // black piece on white side
              result.add (new Square (i, j));
            } else if (Character.isUpperCase (piece) && j <= 3) { // white piece on black side
              result.add (new Square (i, j));
            }
          }
        }
      }
    }

    return result;
  }

  private boolean differentColour (Scene board, Square square1, Square square2) {
    char item1 = ( (ItemSquarePattern)board.getSquareContentsAsListPattern(square1.getColumn(), square1.getRow(), true).getItem(0) ).getItem().charAt (0);
    char item2 = ( (ItemSquarePattern)board.getSquareContentsAsListPattern(square2.getColumn(), square2.getRow(), true).getItem(0) ).getItem().charAt (0);

    return 
      (Character.isUpperCase (item1) && Character.isLowerCase (item2)) ||
      (Character.isUpperCase (item2) && Character.isLowerCase (item1));
  }

  // add destination square to given list if the move would be to an empty square, or a capture
  private void addValidMove (Scene board, Square source, Square destination, List<Square> moves) {
    if (board.isSquareEmpty (destination.getColumn (), destination.getRow ()) ||
        differentColour (board, source, destination)) {
      moves.add (destination);
        }
  }

  // compute possible pawn moves
  // -- assume square is position of a black pawn
  private List<Square> findBlackPawnMoves (Scene board, Square square) {
    List<Square> moves = new ArrayList<Square> ();

    // check move forward
    if (board.isSquareEmpty (square.getColumn (), square.getRow () + 1)) {
      moves.add (new Square (square.getColumn (), square.getRow () + 1));
      // initial move
      if (square.getRow () == 1 && board.isSquareEmpty (square.getColumn (), square.getRow () + 2)) {
        moves.add (new Square (square.getColumn (), square.getRow () + 2));
      }
    }

    // check captures - e.p. ignored
    if (square.getColumn () > 0) { // not in column a
      Square destination = new Square (square.getColumn () - 1, square.getRow () + 1);
      if (differentColour (board, square, destination)) {
        moves.add (destination);
      }
    }
    if (square.getColumn () < 7) { // not in column h
      Square destination = new Square (square.getColumn () + 1, square.getRow () + 1);
      if (differentColour (board, square, destination)) {
        moves.add (destination);
      }
    }

    return moves;
  }

  // -- assume square is position of a white pawn
  private List<Square> findWhitePawnMoves (Scene board, Square square) {
    List<Square> moves = new ArrayList<Square> ();

    // check move forward
    if (board.isSquareEmpty (square.getColumn (), square.getRow () - 1)) {
      moves.add (new Square (square.getColumn (), square.getRow () - 1));
      // initial move
      if (square.getRow () == 1 && board.isSquareEmpty (square.getColumn (), square.getRow () - 2)) {
        moves.add (new Square (square.getColumn (), square.getRow () - 2));
      }
    }

    // check captures - e.p. ignored
    if (square.getColumn () > 0) { // not in column a
      Square destination = new Square (square.getColumn () - 1, square.getRow () - 1);
      if (differentColour (board, square, destination)) {
        moves.add (destination);
      }
    }
    if (square.getColumn () < 7) { // not in column h
      Square destination = new Square (square.getColumn () + 1, square.getRow () - 1);
      if (differentColour (board, square, destination)) {
        moves.add (destination);
      }
    }

    return moves;
  }

  // compute possible knight moves
  // -- assume square is position of a knight 
  private List<Square> findKnightMoves (Scene board, Square square) {
    List<Square> moves = new ArrayList<Square> ();

    if (square.getRow () < 6) { // not rows 7 or 8
      if (square.getColumn () > 0) { // not column a
        addValidMove (board, square, new Square (square.getColumn () - 1, square.getRow () + 2), moves);
      }
      if (square.getColumn () < 7) { // not column h
        addValidMove (board, square, new Square (square.getColumn () + 1, square.getRow () + 2), moves);
      }
    }

    if (square.getRow () > 1) { // not rows 1 or 2
      if (square.getColumn () > 0) { // not column a
        addValidMove (board, square, new Square (square.getColumn () - 1, square.getRow () - 2), moves);
      }
      if (square.getColumn () < 7) { // not column h
        addValidMove (board, square, new Square (square.getColumn () + 1, square.getRow () - 2), moves);
      }
    }

    if (square.getColumn () > 1) { // not columns a or b
      if (square.getRow () > 0) { // not row 1
        addValidMove (board, square, new Square (square.getColumn () - 2, square.getRow () - 1), moves);
      }
      if (square.getRow () < 7) { // not row 8
        addValidMove (board, square, new Square (square.getColumn () - 2, square.getRow () + 1), moves);
      }
    }

    if (square.getColumn () < 6) { // not columns g or h
      if (square.getRow () > 0) { // not row 1
        addValidMove (board, square, new Square (square.getColumn () + 2, square.getRow () - 1), moves);
      }
      if (square.getRow () < 7) { // not row 8
        addValidMove (board, square, new Square (square.getColumn () + 2, square.getRow () + 1), moves);
      }
    }

    return moves;
  }

  // compute possible king moves
  // -- assume square is position of a king
  // -- does not check if move is to an undefended square
  private List<Square> findKingMoves (Scene board, Square square) {
    List<Square> moves = new ArrayList<Square> ();

    if (square.getRow () > 0) { // not in row 8
      addValidMove (board, square, new Square (square.getColumn (), square.getRow () - 1), moves);
    }
    if (square.getRow () < 7) { // not in row 1
      addValidMove (board, square, new Square (square.getColumn (), square.getRow () + 1), moves);
    }
    if (square.getColumn () > 0) { // not in column 1
      addValidMove (board, square, new Square (square.getColumn () - 1, square.getRow ()), moves);
    }
    if (square.getColumn () < 7) { // not in column 8
      addValidMove (board, square, new Square (square.getColumn () + 1, square.getRow ()), moves);
    }
    if (square.getRow () > 0 && square.getColumn () > 0) { // not in row 8 or column 1
      addValidMove (board, square, new Square (square.getColumn () - 1, square.getRow () - 1), moves);
    }
    if (square.getRow () > 0 && square.getColumn () < 7) { // not in row 8 or column 8
      addValidMove (board, square, new Square (square.getColumn () + 1, square.getRow () - 1), moves);
    }
    if (square.getRow () < 7 && square.getColumn () > 0) { // not in row 1 or column 1
      addValidMove (board, square, new Square (square.getColumn () - 1, square.getRow () + 1), moves);
    }
    if (square.getRow () < 7 && square.getColumn () < 7) { // not in row 8 or column 8
      addValidMove (board, square, new Square (square.getColumn () + 1, square.getRow () + 1), moves);
    }

    return moves;
  }

  // compute possible queen moves
  // -- assume square is position of a queen
  private List<Square> findQueenMoves (Scene board, Square square) {
    List<Square> moves = new ArrayList<Square> ();

    lineMove (board, moves, square, -1, 0); // moves upwards
    lineMove (board, moves, square, 1, 0); // moves down
    lineMove (board, moves, square, 0, -1); // moves left
    lineMove (board, moves, square, 0, +1); // moves right
    lineMove (board, moves, square, -1, -1); // moves up and left
    lineMove (board, moves, square, +1, -1); // moves down and left
    lineMove (board, moves, square, -1, +1); // moves up and right
    lineMove (board, moves, square, +1, +1); // moves down and right

    return moves;
  }

  // compute possible rook moves
  // -- assume square is position of a rook
  private List<Square> findRookMoves (Scene board, Square square) {
    List<Square> moves = new ArrayList<Square> ();

    lineMove (board, moves, square, -1, 0); // moves upwards
    lineMove (board, moves, square, 1, 0); // moves down
    lineMove (board, moves, square, 0, -1); // moves left
    lineMove (board, moves, square, 0, +1); // moves right

    return moves;
  }

  // compute possible bishop moves
  // -- assume square is location of a bishop
  private List<Square> findBishopMoves (Scene board, Square square) {
    List<Square> moves = new ArrayList<Square> ();
    
    lineMove (board, moves, square, -1, -1); // moves up and left
    lineMove (board, moves, square, +1, -1); // moves down and left
    lineMove (board, moves, square, -1, +1); // moves up and right
    lineMove (board, moves, square, +1, +1); // moves down and right

    return moves;
  }

  // move piece in direction given by deltas, until reach edge of board or a piece.
  // in case where piece reached is of different colour, include that piece's square.
  private void lineMove (Scene board, List<Square> moves, Square square, int rowDelta, int colDelta) {
    int tryRow = square.getRow () + rowDelta;
    int tryCol = square.getColumn () + colDelta;
    boolean metPiece = false;
    while (!metPiece && tryRow >=0 && tryRow <= 7 && tryCol >= 0 && tryCol <= 7) {
      Square destination = new Square (tryCol, tryRow);
      if (board.isSquareEmpty (destination.getColumn (), destination.getRow ())) {
        moves.add (destination);
        tryRow += rowDelta;
        tryCol += colDelta;
      } else {
        metPiece = true;
        if (differentColour (board, square, destination)) {
          moves.add (destination);
        } 
      }
    }
  }

  /**
   * Calculate a list of possible destination squares for a piece in a scene.
   * @param board
   * @param square
   * @return 
   */
  @Override
  public List<Square> proposeMovementFixations (Scene board, Square square) {
    String piece = ( (ItemSquarePattern)board.getSquareContentsAsListPattern(square.getColumn(), square.getRow(), true).getItem(0) ).getItem();

    if (piece.equals ("P")) {
      return findWhitePawnMoves (board, square);
    } else if (piece.equals ("p")) {
      return findBlackPawnMoves (board, square);
    } else if (piece.equalsIgnoreCase ("N")) {
      return findKnightMoves (board, square);
    } else if (piece.equalsIgnoreCase ("K")) {
      return findKingMoves (board, square);
    } else if (piece.equalsIgnoreCase ("Q")) {
      return findQueenMoves (board, square);
    } else if (piece.equalsIgnoreCase ("R")) {
      return findRookMoves (board, square);
    } else if (piece.equalsIgnoreCase ("B")) {
      return findBishopMoves (board, square);
    } else {
      return new ArrayList<Square> (); // no moves
    }
  }

  @Override
  public int getCurrentTime() {
    throw new UnsupportedOperationException("Not supported yet.");
  }

  /**
   * Converts coordinates in {@link jchrest.lib.ItemSquarePattern}s 
   * contained in a {@link jchrest.lib.ListPattern} to zero-indexed coordinates
   * so the information in the {@link jchrest.lib.ListPattern}'s {@link 
   * jchrest.lib.ItemSquarePattern}s can be mapped onto a 
   * {@link jchrest.lib.Scene}.
   * 
   * @param listPattern
   * @param scene Not used so can be set to null.
   * @return 
   */
  @Override
  public ListPattern convertDomainSpecificCoordinatesToSceneSpecificCoordinates(ListPattern listPattern, Scene scene) {
    ListPattern preparedListPattern = new ListPattern(Modality.VISUAL);
    Iterator<PrimitivePattern> listPatternIterator = listPattern.iterator();
    
    while(listPatternIterator.hasNext()){
      ItemSquarePattern isp = (ItemSquarePattern)listPatternIterator.next();
      preparedListPattern.add(
        new ItemSquarePattern(
          isp.getItem(),
          isp.getColumn() - 1, 
          isp.getRow() - 1
        )
      );
    }
    
    return preparedListPattern;
  }

  /**
   * Converts coordinates in {@link jchrest.lib.ItemSquarePattern}s 
   * contained in a {@link jchrest.lib.ListPattern} from zero-indexed 
   * coordinates so the information in the {@link jchrest.lib.ListPattern}'s 
   * {@link jchrest.lib.ItemSquarePattern}s can be used in chess.
   * 
   * @param listPattern
   * @param scene Not used so can be set to null.
   * @return 
   */
  @Override
  public ListPattern convertSceneSpecificCoordinatesToDomainSpecificCoordinates(ListPattern listPattern, Scene scene) {
    ListPattern preparedListPattern = new ListPattern(Modality.VISUAL);
    Iterator<PrimitivePattern> listPatternIterator = listPattern.iterator();
    
    while(listPatternIterator.hasNext()){
      ItemSquarePattern isp = (ItemSquarePattern)listPatternIterator.next();
      preparedListPattern.add(
        new ItemSquarePattern(
          isp.getItem(),
          isp.getColumn() + 1, 
          isp.getRow() + 1
        )
      );
    }
    
    return preparedListPattern;
  }
}
