<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<%@ page import="java.util.*, java.io.*"%>
<%@ page import="
com.opencloud.slee.example.j2ee.callejb.ejb.*,
javax.naming.*,
javax.rmi.PortableRemoteObject,
java.rmi.RemoteException,
javax.ejb.FinderException,
javax.ejb.CreateException,
javax.ejb.RemoveException,
javax.slee.EventTypeID,
javax.slee.connection.SleeConnectionFactory,
javax.slee.connection.SleeConnection,
javax.slee.connection.ExternalActivityHandle,
com.opencloud.slee.example.j2ee.connector.events.IntegrationEvent
"%>
<%!
  private SleeConnectionFactory factory;
  private AccountHome accountHome;
  private final String name = "IntegrationEvent";
  private final String vendor = "OpenCloud";
  private final String version = "2.1";

  private final int TYPE_CREATE = 0;
  private final int TYPE_REMOVE = 1;
  private final int TYPE_WITHDRAW = 2;
  private final int TYPE_DEPOSIT = 3;


  public int validateIntArg(final String arg) throws IllegalArgumentException {
      if (arg == null)
          throw new IllegalArgumentException("'null' argument cannot be converted to integer.");

      if ("".equals(arg) )
          throw new IllegalArgumentException("'' argument cannot be converted to integer.");

      try {
          int value = Integer.parseInt(arg);
          return value;
      } catch (NumberFormatException e) {
          throw new IllegalArgumentException("Argument could not be converted to 'int': "+arg);
      }
  }

  public double validateDoubleArg(final String arg) throws IllegalArgumentException {
      if (arg == null)
          throw new IllegalArgumentException("'null' argument cannot be converted to double.");

      if ("".equals(arg) )
          throw new IllegalArgumentException("'' argument cannot be converted to double.");

      try {
          double value = Double.parseDouble(arg);
          return value;
      } catch (NumberFormatException e) {
          throw new IllegalArgumentException("Argument could not be converted to 'double': "+arg);
      }
  }


  public void withdraw(final String accNo, final String amount) throws FinderException, ProcessingErrorException, RemoteException, FinderException, IllegalArgumentException {
      int accNoInt = validateIntArg (accNo);
      double amountDouble = validateDoubleArg(amount);

      Account account = accountHome.findByPrimaryKey(accNoInt);
      account.withdraw(amountDouble);
      sendEvent(TYPE_WITHDRAW, "Withdrew amount="+amount+" from account accountNo="+accNo);
  }

  public void deposit(final String accNo, final String amount) throws FinderException, RemoteException, IllegalArgumentException {
      int accNoInt = validateIntArg (accNo);
      double amountDouble = validateDoubleArg(amount);

      Account account = accountHome.findByPrimaryKey(new Integer(accNoInt));
      account.deposit(new Double(amountDouble));
      sendEvent(TYPE_DEPOSIT, "Deposited amount=" + amount + " into account accountNo=" + accNo);
  }

  public void remove(final String accNo) throws RemoveException, RemoteException, IllegalArgumentException {
      int accNoInt = validateIntArg (accNo);

      accountHome.remove(accNoInt);
      sendEvent(TYPE_REMOVE, "Removed account with accountNo="+accNo);
  }

  public void create(final String accNo, final String accType) throws CreateException, RemoteException, IllegalArgumentException {
      int accNoInt = validateIntArg (accNo);

      accountHome.create(new Integer(accNoInt), accType, new Double(0.0));
      sendEvent(TYPE_CREATE, "Created account [accountNo="+accNo+" accountType="+accType+"]");
  }


  public void sendEvent(final int type, final String msg) {
        new Thread(){
            public void run(){
                SleeConnection connection = null;
                try {

                    connection = factory.getConnection();

                    if (connection != null)
                        System.err.println("I have a connection of type: " + connection.getClass().getName());

                    EventTypeID typeID = connection.getEventTypeID( name, vendor, version );
                    System.err.println("EventTypeID: " + typeID);

                    ExternalActivityHandle handle = connection.createActivityHandle();

                    System.err.println("handle: " + handle);

                    IntegrationEvent ie = new IntegrationEvent(type, msg);
                    System.err.println("ie : " + ie);
                    connection.fireEvent(ie, typeID, handle, null);
                }catch (Exception e) {
                    javax.ejb.EJBException ee = new javax.ejb.EJBException("Exception sending events");
                    ee.initCause(e);
                    throw ee;
                }
                finally {
                    if (connection != null) {
                        try { connection.close(); }
                        catch (Exception e) {}
                    }
                }
            }
        }.start();
  }

  String getStackTraceAsString(Exception e)
  {
    /* Dump the stack trace to a buffered stream, then send its contentsto the JSPWriter.
    */

    ByteArrayOutputStream ostr = new ByteArrayOutputStream();
    PrintWriter writer = new PrintWriter(ostr);
    e.printStackTrace(writer);
    writer.flush();
    return(ostr.toString());
  }
%>
<html>
  <head>
    <title>OpenCloud SLEE<->J2EE examples</title>
    <LINK REL="stylesheet" TYPE="text/css" HREF="stylesheet.css" />
    <META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE" />
    <META HTTP-EQUIV="EXPIRES" CONTENT="0"/>
  </head>
  <body style="margin:0">

<%

  try {

     // **** lookup SleeConnectionFactory JRMP naming context
     InitialContext ic = new InitialContext();
     this.factory = (SleeConnectionFactory)ic.lookup("java:comp/env/slee/SleeConnectionFactory");

     // **** lookup AccountHome in JRMP naming context
     Object o = ic.lookup("java:comp/env/ejb/AccountHome");
     System.out.println("Lookup object: "+o);
     if (o!=null)
         System.out.println("Lookup object class: "+o.getClass().getName());

     accountHome = (AccountHome)PortableRemoteObject.narrow(o, AccountHome.class);
     System.out.println("AccountHome.class: "+AccountHome.class);
     System.out.println("AccountHome: "+accountHome);
     if (accountHome!=null)
         System.out.println("AccountHome object class: "+accountHome.getClass().getName());

     // **** Request parameter definitions
     String op = null;
     String accNo = null;
     String amount = null;
     String accType = null;

     // **** get parameter values from request
     op = request.getParameter("op");
     accNo = request.getParameter("accNo");
     amount = request.getParameter("amount");
     accType = request.getParameter("accType");


     // **** debug printout for parameters
     System.out.println("op: " + op);
     System.out.println("accNo: " + accNo);
     System.out.println("amount: " + amount);
     System.out.println("accType: " + accType);


     // **** perform operations as indicated via extracted parameters; send appropriate events to SLEE
     if ("create".equalsIgnoreCase(op)) {
         create(accNo, accType);

     } else if ("deposit".equalsIgnoreCase(op)) {
         deposit(accNo, amount);

     } else if ("withdraw".equalsIgnoreCase(op)) {
         withdraw(accNo, amount);

     } else if ("remove".equalsIgnoreCase(op)) {
         remove(accNo);

     }

     // **** Redirect to account survey page ****//
     String redirectURL = "accountSurvey.jsp";
     response.sendRedirect(redirectURL);

  } catch (Exception e) {
    e.printStackTrace();%>

<table class="ExceptionHeading">
    <tr>
    <td>
    Unexpected Error
    </td>
    </tr>
    <tr>
    <td CLASS="ExceptionSubHeading">
    <pre><%=e.getMessage()%></pre>
    </td>
    </tr>
    <tr>
    <td CLASS="ExceptionBody" >
    <pre><%=getStackTraceAsString(e)%></pre>
    </td>
    </tr>
</table>
<%
  } finally {
  }
%>
  </body>
</html>
