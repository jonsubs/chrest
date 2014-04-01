// Copyright (c) 2012, Peter C. R. Lane
// Released under Open Works License, http://owl.apotheon.org/

package jchrest.gui;

import jchrest.architecture.*;
import java.awt.*;
import javax.swing.*;

public class NodeIcon implements Icon {
  private NodeDisplay _node;
  private Component _parent;
//  private JList _stmList

  public NodeIcon (Node node, Component parent) {
    _node = new NodeDisplay (node);
    _parent = parent;
//    _stmList = stmList;
  }

  public void paintIcon (Component c, Graphics g, int x, int y) {
    ((Graphics2D)g).setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
    _node.draw ((Graphics2D)g, x, y, getIconWidth(), getIconHeight(), Size.getValues().get (1));
  }

  public int getIconWidth  () { return _node.getWidth ( (Graphics2D)_parent.getGraphics(), Size.getValues().get (1)); }
  public int getIconHeight () { return _node.getHeight( (Graphics2D)_parent.getGraphics(), Size.getValues().get (1)); }
}

