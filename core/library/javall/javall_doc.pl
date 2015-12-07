:- module(_,[],[assertions]).

%% ---------------------------------------------------------------------------
%% Intro
%% ---------------------------------------------------------------------------

:- doc(title,"Prolog/Java Bidirectional Interface").

:- doc(subtitle_extra,"@bf{The CIAO System Documentation Series}").
%:- doc(subtitle_extra,"Technical Report CLIP 5/97.1").
:- doc(subtitle_extra,"@em{Printed on:} @today{}").

:- doc(author, "Jes@'{u}s Correas").
:- doc(author, "The CLIP Group").
:- doc(address, "@tt{clip@@dia.fi.upm.es}").
:- doc(address, "@tt{http://www.clip.dia.fi.upm.es/}").
:- doc(address, "Facultad de Inform@'{a}tica").
:- doc(address, "Universidad Polit@'{e}cnica de Madrid").

:- doc(copyright,"
Copyright @copyright{} 1996-2002 Jes@'{u}s Correas Fern@'{a}ndez/The CLIP Group.

@include{DocCopyright.lpdoc}
").

:- doc(summary,"@include{JavallSumm.lpdoc}").

:- doc(module,"
@cindex{Platform independence}
The increasing diversity of platforms used today and the diffusion of
Internet and the World Wide Web makes compatibility between platforms
a key factor to run the software everywhere with no change. Java seems to
achieve this goal, using a bytecode intermediate language and a large
library of platform-dependent and independent classes which fully
implements many. On the other
hand, Prolog provides a powerful implementation of logic programming
paradigm.  This document includes the reference manual of the Prolog/Java
bidirectional interface implemented in Ciao. In addition, it has been
developed an application of this interface that makes use of an object
oriented extension of Prolog to encapsulate the java classes, O'Ciao, both
the ones defined in the JDK as well as new classes developed in Java. These
classes can be used in the object oriented prolog extension of Ciao just
like native O'Ciao classes.

The proposed interaction between both languages is realized as an interface
between two processes, a Java process and a Prolog process, running
separately. This approach allows the programmer to use of both Java and Prolog,
without the compiler-dependent glue code used in other
linkage-oriented approaches, and preserves the philosophy of Java as an
independent language. The interface communication is based on a
clean socket-based protocol, providing hardware and software
independence. This allows also both processes to be run in different
machines connected by a TCP/IP transport protocol, based on a client/server 
model that can evolve to a more cooperative model.

The present manual includes reference information about the Prolog side of the
bidirectional Java/Prolog interface. The Java side of this
interface is explained in the HTML pages generated by Javadoc.

@section{Distributed Programming Model}
@cindex{Distributed Programming Model}
The differences between Prolog and Java impose the division of the
interface in two main parts: a prolog-to-java and a java-to-prolog
interfaces. Most of the applications that will use this interface will
consider that will be a ``client' side that request actions and queries to a
``server' side, which accomplish the actions and answer the queries. In a
first approach, any of the both one-way interfaces implement a pure
client/server model: the server waits for a query, performs the received
query and sleeps until the next query comes; the client starts the server,
carries out the initial part of the job initiating all the conversations
with the server, and requests the server to do some things sometimes.

This model cannot handle correctly the tasks regarding an event oriented
programming environment like java. A usual application of the
prolog-to-java interface could be a graphical user interface server made in
java, and a prolog client on the other side. A pure client/server model
based on requests and results is not powerful enough to leave the prolog
side managing all the application specific work of this example: some java
specific stuff is needed to catch and manipulate properly the events thrown
by the graphical user interface. This problem can be solved in a
distributed context, on which both languages are clients and servers
simultaneously, and can perform requests and do actions at a time. Using
this model, the prolog side can add a prolog goal as listener of a specific
event, and the java side launches that goal when the event raises.

In any case, the client/server approach simplifies the design of the
interface, so both interfaces have been designed in such way, but keeping in
mind that the goal is to reach a distributed environment, so each side do
the things it is best designed for. 

").
:- push_prolog_flag(unused_pred_warnings, no).
main.
:- pop_prolog_flag(unused_pred_warnings).