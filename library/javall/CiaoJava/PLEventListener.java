package  CiaoJava;

import java.awt.event.*;
import java.util.*;
import java.awt.*;
import java.io.*;

/**
 * Listens events directly from the system event queue.
 * Keeps a list of prolog listeners associated with objects and event Ids.
 * A key element of this implementation is that the prolog listeners
 * will be evaluated when the event raises, so the arguments of the
 * listeners will be updated correctly in the prolog side.
 */
public class PLEventListener implements AWTEventListener {

  /**
   * Internal constants.
   */
  private static final int STARTING_CAPACITY = 16;
  private static final float FACTOR = 0.2f;

  /**
   * System queue
   */
  private EventQueue queue;

  /**
   * Object/event Hashtable.
   */
  private Hashtable objTable;

  /**
   * Interpreter to evaluate goal arguments.
   */
  private PLInterpreter interpreter;

  /**
   * Prolog connection for the goals to be launched when an event occurs.
   */
  private PLConnection pl;

  /**
   * Creates a new event listener.
   *
   * @param pl          Connection to the prolog process
   * @param interpreter The <code>PLInterpreter</code> object to be
   *                    used for the goal argument calculation.
   */
  public PLEventListener(PLConnection pl, PLInterpreter interpreter) {

    Toolkit.getDefaultToolkit().addAWTEventListener(this, Long.MAX_VALUE);

    objTable = new Hashtable(STARTING_CAPACITY, FACTOR);
    this.pl = pl;
    this.interpreter = interpreter;

  }

  /**
   * Inserts a new listener. Given an object, event class and goal,
   * updates the listener list.
   *
   * @param obj  object on which the listener listens.
   * @param ec   event class that will be listened.
   * @param goal Prolog goal that will be evaluated when the
   *             event raises.
   */
  public void addListener(Object obj, Class ec, PLTerm goal) {

    PLEvents events = null;
    if ((events = (PLEvents)objTable.get(obj)) == null) {
      events = new PLEvents(ec, goal);
      objTable.put(obj, events);
    }
    else
      events.addEvent(ec, goal);

  }

  /**
   * Removes a listener. Given an object and event class,
   * updates the listener structure removing the listener to this
   * object and event.
   *
   * @param obj  object on which the listener listens.
   * @param ec   event class that is being listened.
   * @param goal Prolog goal that will be evaluated when the
   *             event raises.
   */
  public void removeListener(Object obj, Class ec, PLTerm goal) {
    PLEvents events = null;
    if ((events = (PLEvents)objTable.get(obj)) != null) {
      events.removeEvent(ec, goal);
      if (events.isEmpty())
        objTable.remove(obj);
    }
  }

  /**
   * Method called on each event queued on the system queue.
   * Selects and runs the goals that must be launched for the object and
   * event raised.
   *
   * @param ev <code>AWTEvent</code> object represented the
   *           event raised.
   */
  public synchronized void eventDispatched(AWTEvent eventRaised) {
    
    Object obj = eventRaised.getSource();
    PLEvents events;
    if ((events = (PLEvents)objTable.get(obj)) != null)
      events.eventDispatched(eventRaised.getClass(), interpreter, pl);

  }
}

/**
 * This class represents the set of events that are being listened for an 
 * object.
 **/
class PLEvents {

  /*
   * Internal constants.
   */
  private static final int STARTING_CAPACITY = 16;
  private static final float FACTOR = 0.2f;

  /*
   * Events table.
   */
  private Hashtable events;

  /**
   * Creates a new event class to be listened for an object,
   * and inserts the class and goal given.
   *
   * @param ec   Event class that will be listened.
   * @param goal Prolog goal to be launched when the event raises.
   */
  public PLEvents(Class ec, PLTerm goal) {
    events = new Hashtable(STARTING_CAPACITY, FACTOR);
    addEvent(ec, goal);
  }

  /**
   * Inserts a new event listener.
   *
   * @param ec   Event class that will be listened.
   * @param goal Prolog goal to be launched when the event raises.
   */
  public void addEvent(Class ec, PLTerm goal) {
    PLGoals pl = null;
    if ((pl = (PLGoals)events.get(ec)) == null) {
      pl = new PLGoals(goal);
      events.put(ec, pl);
    }
    else
      pl.addGoal(goal);
  }

  /**
   * Removes an event class from the event list.
   *
   * @param ec   Event class that is being listened.
   * @param goal Prolog goal to be launched when the event raises.
   */
  public void removeEvent(Class ec, PLTerm goal) {
    PLGoals pl = null;
    if ((pl = (PLGoals)events.get(ec)) != null) {
      pl.removeGoal(goal);
      if (pl.isEmpty())
        events.remove(ec);
    }
  }

  /**
   * Returns true if this PLEvent object is empty (has no events).
   */
  public boolean isEmpty() {
    return events.isEmpty();
  }

  /**
   * Launches goals associated to the given event, using the java
   * object table of the interpreter given as 2nd argument.
   *
   * @param ec          Event class that is being listened.
   * @param interpreter prolog to java interpreter.
   * @param pl          Prolog process on which evaluate the
   *                    prolog event handlers.
   */
  public void eventDispatched(Class ec,
                          PLInterpreter interpreter,
                          PLConnection pl) {

    PLGoals goals;
    if ((goals = (PLGoals)events.get(ec)) != null)
      goals.launchGoals(interpreter, pl);
  }

}

/**
 * This class represents the set of listeners for an event type.
 */
class PLGoals {
  /*
   * Internal constants.
   */
  private static final int STARTING_CAPACITY = 10;
  private static final int INCREMENT = 10;

  private Vector goals;

  /**
   * Creates a new empty goal set.
   */
  public PLGoals() {
    goals = new Vector(STARTING_CAPACITY, INCREMENT);
  }

  /**
   * Creates a new goal set with the goal given.
   *
   * @param goal Prolog goal to be evaluated.
   */
  public PLGoals(PLTerm goal) {
    goals = new Vector(STARTING_CAPACITY, INCREMENT);
    goals.addElement(goal);
  }

  /**
   * Adds a goal to this goal set.
   *
   * @param goal Prolog goal to be added.
   */
  public void addGoal(PLTerm goal) {
    if (goals.indexOf(goal) == -1)
      goals.addElement(goal);
  }

  /**
   * Removes the goal given from this goal set.
   */
  public void removeGoal(PLTerm pl) {
    int i;
    if ((i = goals.indexOf(pl)) != -1)
      goals.removeElementAt(i);
  }

  /**
   * Returns true if this PLGoals object is empty (has no goals).
   */
  public boolean isEmpty() {

    return goals.isEmpty();

  }

  /**
   * Launches the goals of this set, based on the interpreter
   * given as argument.
   */
  public void launchGoals(PLInterpreter interpreter,
			  PLConnection pl) {

    PLStructure el;
    for (Enumeration c = goals.elements(); c.hasMoreElements();) {
      el = (PLStructure)c.nextElement();
      el.launchGoal(interpreter, pl);
    }
  }
}

