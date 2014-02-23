<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<%@ page import="java.util.*, java.io.*"%>
<%@ page import="
com.opencloud.slee.example.j2ee.callejb.ejb.*,
javax.naming.*,
javax.rmi.PortableRemoteObject,
java.rmi.RemoteException,
javax.ejb.FinderException,
java.util.Properties,
java.util.Collection,
java.util.Iterator,
java.util.Arrays,
com.opencloud.slee.example.j2ee.AccountComparator
"%>
<%!
  private AccountHome accountHome;

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

  <TABLE CLASS="TableColourDark" WIDTH="100%" border="0" ALIGN="center" cellspacing="0" cellpadding="0">
        <TR>
        <TD/>
        <TD align="center" width="80%"><b>OpenClound SLEE<->J2EE examples</b></TD>
        <TD/>
        <TD ALIGN="right"><IMG SRC="oc_strip_sm.gif"/></TD>
        </TR>
    </TABLE>
<hr/>
<TABLE width="80%" ALIGN="center" border="0" >
<TR>
<TD>

  <p>
    Listing accounts...
  </p>

<%

  try {

     // **** lookup AccountHome in JRMP naming context
     InitialContext ic = new InitialContext();
     Object o = ic.lookup("java:comp/env/ejb/AccountHome");
     System.out.println("Lookup object: "+o);
     if (o!=null)
         System.out.println("Lookup object class: "+o.getClass().getName());

     accountHome = (AccountHome)PortableRemoteObject.narrow(o, AccountHome.class);
     System.out.println("AccountHome.class: "+AccountHome.class);
     System.out.println("AccountHome: "+accountHome);
     if (accountHome!=null)
         System.out.println("AccountHome object class: "+accountHome.getClass().getName());

     // **** List all accounts with their current status ****//
     Collection col = accountHome.findAll();
     Iterator iter = col.iterator();
     Account[] accs = new Account[col.size()];
     %>
     <table>
     <tr><td>Account No.</td><td>Account Type</td><td>Balance</td></tr>
     <%for (int i=0;i<col.size();i++) {
         Account account = (Account)PortableRemoteObject.narrow(iter.next(), Account.class);
         accs[i] = account;
     }
     AccountComparator c = new AccountComparator();
     Arrays.sort(accs, c);

     for (int i=0;i<accs.length;i++) {
         Account account = accs[i]; %>
     <tr>
     <td><%=account.getAccountNumber()%></td><td><%=account.getAccountType()%></td><td><%=account.getBalance()%></td>
     <td><a href="operations.jsp?op=remove&accNo=<%=account.getAccountNumber()%>"><img src="images/delete.gif"></td>
     </tr>
     <%}%>
     </table>

     <!-- **** Forms for create, deposit, withdraw operations ****-->
     <hr/>
     <p>Create new account</p>
     <form action="operations.jsp">
        Acc No. <input type="text" name="accNo">
        Acc Type. <select name="accType">
          <option value="No interest maximum fee">No interest maximum fee</option>
          <option value="Account 42">Account 42</option>
          <option value="Never See Money Again Investment Trust">Never See Money Again Investment Trust</option>
        </select>
        <input type="submit" name="op" value="create">
        <br>
     </form>
     <hr/>
     <p>Deposit</p>
     <form action="operations.jsp">
        Acc No. <select name="accNo">
        <% for (int i=0;i<accs.length;i++) {%>
          <option value="<%=accs[i].getAccountNumber()%>"><%=accs[i].getAccountNumber()%></option>
        <%}%>
        </select>
        Amount <input type="text" name="amount">
        <input type="submit" name="op" value="deposit">
        <br>
     </form>
     <hr/>
     <p>Withdraw</p>
     <form action="operations.jsp">
        Acc No. <select name="accNo">
        <% for (int i=0;i<accs.length;i++) {%>
          <option value="<%=accs[i].getAccountNumber()%>"><%=accs[i].getAccountNumber()%></option>
        <%}%>
        </select>
        Amount <input type="text" name="amount">
        <input type="submit" name="op" value="withdraw">
        <br>
     </form>
     <hr/>

  <%} catch (Exception e) {
    e.printStackTrace();%>
<br/>
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
  </TD>
  </TR>
  </TABLE>
  </body>
</html>
