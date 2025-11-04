Fork Notes
==================
This is a fork of a [SQLite JDBC driver] ( https://github.com/decamp/sqlcipher-jdbc) to work for 64-bit Windows and Linux
Note that decamp itself was a fork of a [SQLite JDBC driver](https://bitbucket.org/xerial/sqlite-jdbc) that as modified originally
to work for for 64-bit OS X. Hence a lot of the documentation here is originally from decamp, but copied here for the sake of completeness.
I have tried to add the build related aspects for 64-bit Windows and Linux, that are not currently available at decamp site.



About SqlCipher
==================
[SQLCipher](https://www.zetetic.net/sqlcipher/) is a version of SQLite that is modified to support encryption.
SQLCipher is included here as a submodule. The only native binaries included here currently are for 64-bit OS X.
I've tried to keep modifications minimal, though, and it might not be difficult to get things to build for other
platforms by fiddling with the makefiles.

To create/open an encrypted database, try something like:
```
Class.forName("org.sqlite.JDBC");
Properties props = new Properties();
props.put( "key", "some_passphrase" )
Connection conn = DriverManager.getConnection( url, props );
```

See SQLCipher documentation for the relevant pragmas that control encryption. These include:
- key
- cipher
- kdf_iter
- cipher_page_size
- rekey
- cipher_use_hmac
- cipher_migrate
- cipher_profile

-decamp



SQLite JDBC Driver
==================
SQLite JDBC, developed by [Taro L. Saito](http://www.xerial.org/leo), is a library for accessing and creating [SQLite](http://sqlite.org) database files in Java.

Our SQLiteJDBC library requires no configuration since native libraries for major OSs, including Windows, Mac OS X, Linux etc., are assembled into a single JAR (Java Archive) file. The usage is quite simple; [download](https://bitbucket.org/xerial/sqlite-jdbc/downloads) 
our sqlite-jdbc library, then append the library (JAR file) to your class path. 

See [the sample code](#markdown-header-usage).


What is different from Zentus's SQLite JDBC?
--------------------------------------------
The current sqlite-jdbc implementation is based on the code of [Zentus's SQLite JDBC driver (missing link)](http://www.zentus.com/sqlitejdbc/). We have improved it in two ways:

* Support major operating systems by embedding native libraries of SQLite, compiled for each of them.
* Remove manual configurations

In the original version, in order to use the native version of sqlite-jdbc, users had to set a path to the native codes (dll, jnilib, so files, etc.) through the command-line arguments, 
e.g., `-Djava.library.path=(path to the dll, jnilib, etc.)`, or `-Dorg.sqlite.lib.path`, etc. 
This process was error-prone and bothersome to tell every user to set these variables. 
Our SQLiteJDBC library completely does away these inconveniences. 

Another difference is that we are keeping this SQLiteJDBC library up-to-date to 
the newest version of SQLite engine, because we are one of the hottest users of 
this library. For example, SQLite JDBC is a core component of 
[UTGB (University of Tokyo Genome Browser) Toolkit](http://utgenome.org/), which 
is our utility to create personalized genome browsers.


Public Discussion Forum
=======================
*  [Xerial Public Discussion Group](http://groups.google.com/group/xerial?hl=en) 
*  Post bug reports or feqture requests to [Issue Tracker](https://bitbucket.org/xerial/sqlite-jdbc/issues)


Usage
============ 
SQLite JDBC is a library for accessing SQLite databases through the JDBC API. For the general usage of JDBC, see [JDBC Tutorial](http://docs.oracle.com/javase/tutorial/jdbc/index.html) or [Oracle JDBC Documentation](http://www.oracle.com/technetwork/java/javase/tech/index-jsp-136101.html).

1.  Download sqlite-jdbc-(VERSION).jar from the [download page](https://bitbucket.org/xerial/sqlite-jdbc/downloads) (or by using [Maven](#markdown-header-using-sqlitejdbc-with-maven2))
then append this jar file into your classpath. 
2.  Load the JDBC driver `org.sqlite.JDBC` from your code. (see the example below) 

** More usage examples are available at <https://bitbucket.org/xerial/sqlite-jdbc/wiki/Usage> **

** Usage Example (Assuming `sqlite-jdbc-(VERSION).jar` is placed in the current directory)**

    > javac Sample.java
    > java -classpath ".;sqlite-jdbc-(VERSION).jar" Sample   # in Windows
    or 
    > java -classpath ".:sqlite-jdbc-(VERSION).jar" Sample   # in Mac or Linux
    name = leo
    id = 1
    name = yui
    id = 2
    

** Sample.java**
	
	:::java
    import java.sql.Connection;
    import java.sql.DriverManager;
    import java.sql.ResultSet;
    import java.sql.SQLException;
    import java.sql.Statement;
    
    public class Sample
    {
      public static void main(String[] args) throws ClassNotFoundException
      {
        // load the sqlite-JDBC driver using the current class loader
        Class.forName("org.sqlite.JDBC");
        
        Connection connection = null;
        try
        {
          // create a database connection
          connection = DriverManager.getConnection("jdbc:sqlite:sample.db");
          Statement statement = connection.createStatement();
          statement.setQueryTimeout(30);  // set timeout to 30 sec.
          
          statement.executeUpdate("drop table if exists person");
          statement.executeUpdate("create table person (id integer, name string)");
          statement.executeUpdate("insert into person values(1, 'leo')");
          statement.executeUpdate("insert into person values(2, 'yui')");
          ResultSet rs = statement.executeQuery("select * from person");
          while(rs.next())
          {
            // read the result set
            System.out.println("name = " + rs.getString("name"));
            System.out.println("id = " + rs.getInt("id"));
          }
        }
        catch(SQLException e)
        {
          // if the error message is "out of memory", 
          // it probably means no database file is found
          System.err.println(e.getMessage());
        }
        finally
        {
          try
          {
            if(connection != null)
              connection.close();
          }
          catch(SQLException e)
          {
            // connection close failed.
            System.err.println(e);
          }
        }
      }
    }
    


How to Specify Database Files
-----------------------------

Here is an example to select a file `C:\work\mydatabase.db` (in Windows)

    Connection connection = DriverManager.getConnection("jdbc:sqlite:C:/work/mydatabase.db");
    

A UNIX (Linux, Mac OS X, etc) file `/home/leo/work/mydatabase.db`

    Connection connection = DriverManager.getConnection("jdbc:sqlite:/home/leo/work/mydatabase.db");
    


How to Use Memory Databases
---------------------------
SQLite supports on-memory database management, which does not create any database files. 
To use a memory database in your Java code, get the database connection as follows:

    Connection connection = DriverManager.getConnection("jdbc:sqlite::memory:");
    

Supported Operating Systems
===========================
Since sqlite-jdbc-3.6.19, the natively compiled SQLite engines will be used for 
the following operating systems:

*   Windows XP, Vista (Windows, x86 architecture, x86_64) 
*   Mac OS X 10.4 (Tiger), 10.5(Leopard), 10.6 SnowLeopard (for i386, x86_64, Intel CPU machines) 
*   Linux i386 (Intel), amd64 (64-bit X86 Intel processor) 

In the other OSs not listed above, the pure-java SQLite is used. (Applies to versions before 3.7.15)

If you want to use the native library for your OS, [build the source from scratch.


How does SQLiteJDBC work?
-------------------------
Our SQLite JDBC driver package (i.e., `sqlite-jdbc-(VERSION).jar`) contains three 
types of native SQLite libraries (`sqlite-jdbc.dll`, `sqlite-jdbc.jnilib`, `sqlite-jdbc.so`), 
each of them is compiled for Windows, Mac OS and Linux. An appropriate native library 
file is automatically extracted into your OS's temporary folder, when your program 
loads `org.sqlite.JDBC` driver. 


Dependency Tests
----------------
*   Windows XP (32-bit) 
*   dependency check 

    > DUMPBIN /DEPENDENTS sqlitejdbc.dll
    
      KERNEL32.dll
      msvcrt.dll
    

*   Mac OS X (10.4.10 Tiger ~ 10.5 Leopard) 
*   dependency check 

    > otool -L libsqlitejdbc.jnilib  
    libsqlitejdbc.jnilib:
            build/Darwin-i386/libsqlitejdbc.jnilib (compatibility version 0.0.0, current version 0.0.0)
            /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 88.3.9)
    

*   Linux (glibc-2.5.12) 
*   Dependency check 

    > ldd libsqlitejdbc.so    
            linux-gate.so.1 =>  (0x00b45000)
            libc.so.6 => /lib/i686/nosegneg/libc.so.6 (0x002dd000)
            /lib/ld-linux.so.2 (0x47969000)


Source Codes
============
*   Mercurial Repository: <http://bitbucket.org/xerial/sqlite-jdbc> 

License
-------
This program follows the Apache License version 2.0 (<http://www.apache.org/licenses/> ) That means:

It allows you to:

*   freely download and use this software, in whole or in part, for personal, company internal, or commercial purposes; 
*   use this software in packages or distributions that you create. 

It forbids you to:

*   redistribute any piece of our originated software without proper attribution; 
*   use any marks owned by us in any way that might state or imply that we xerial.org endorse your distribution; 
*   use any marks owned by us in any way that might state or imply that you created this software in question. 

It requires you to:

*   include a copy of the license in any redistribution you may make that includes this software; 
*   provide clear attribution to us, xerial.org for any distributions that include this software 

It does not require you to:

*   include the source of this software itself, or of any modifications you may have 
    made to it, in any redistribution you may assemble that includes it; 
*   submit changes that you make to the software back to this software (though such feedback is encouraged). 

See License FAQ <http://www.apache.org/foundation/licence-FAQ.html> for more details.



Using SQLiteJDBC with Maven2
============================
If you are familiar with [Maven2](http://maven.apache.org), add the following XML 
fragments into your pom.xml file. With those settings, your Maven will automatically download our SQLiteJDBC library into your local Maven repository, since our sqlite-jdbc libraries are synchronized with the [Maven's central repository](http://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/). 

    <dependencies>
        <dependency>
          <groupId>org.xerial</groupId>
          <artifactId>sqlite-jdbc</artifactId>
          <version>3.7.2</version>
        </dependency>
    </dependencies>

To use snapshot/pre-release versions, add the following repository to your Maven settings:
* Pre-release repository: <https://oss.sonatype.org/content/repositories/releases>
* Snapshot repository: <https://oss.sonatype.org/content/repositories/snapshots>

Using SQLiteJDBC with Tomcat6 Web Server
========================================
Do not include sqlite-jdbc-(version).jar in WEB-INF/lib folder of your web application 
package, since multiple web applications hosted by the same Tomcat server cannot 
load the sqlite-jdbc native library more than once. That is the specification of 
JNI (Java Native Interface). You will observe `UnsatisfiedLinkError` exception with 
the message "no SQLite library found".

Work-around of this problem is to put `sqlite-jdbc-(version).jar` file into `(TOMCAT_HOME)/lib` 
direcotry, in which multiple web applications can share the same native library 
file (.dll, .jnilib, .so) extracted from this sqlite-jdbc jar file. 

If you are using Maven for your web application, set the dependency scope as 'provided', 
and manually put the SQLite JDBC jar file into (TOMCAT_HOME)/lib folder.

    <dependency>
        <groupId>org.xerial</groupId>
        <artifactId>sqlite-jdbc</artifactId>
        <version>3.7.2</version>
        <scope>provided</scope>
    </dependency>