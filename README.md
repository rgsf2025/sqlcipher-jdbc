Fork Notes
==================
This is a fork of a [SQLite JDBC driver] ( https://github.com/decamp/sqlcipher-jdbc) to work 
for 64-bit Windows and Linux. Note that decamp itself was a fork of a 
[SQLite JDBC driver](https://github.com/xerial/sqlite-jdbc) that as modified to work for
64-bit OS X. Although at some point in time, I think there was indeed support for Windows
and Linux also at this site. 

Hence the documentation on basic sqlite-jdbc driver is taken from xerial and updated to
include sqlcipher into it.

There are two major changes here, compared to decamp. They are,
1. Upgraded and tested for sqlcipher ver 4.10.0 (requires Java JDK17)
2. Built for 64-bit versions of Windows (specifically Windows-11) and Linux


About SqlCipher
==================
[SQLCipher](https://www.zetetic.net/sqlcipher/) is a version of SQLite that is modified to support encryption.
SQLCipher is included here as a submodule.

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

Existing Sqlite-Jdbc and sqlcipher-jdbc projects
===============================================

Several repositories at GitHub provide implementations or related information for using SQLCipher with JDBC:

1. Xerial Sqlite-Jdbc driver (https://github.com/xerial/sqlite-jdbc) by [Taro L. Saito]:
This is Sqlite Jdbc driver and hence it has all the everything required to connect native
[SQLite](http://sqlite.org) to the java world. However, this does not include the encryption,
which is added in SqlCipher (extension of sqlite with encryption).


2. Willena/sqlite-jdbc-crypt (https://github.com/Willena/sqlite-jdbc-crypt) : This is a prominent
fork of the SQLite JDBC driver that includes support for SQLCipher encryption. It allows Java
applications to access and create encrypted SQLite databases using SQLCipher.
BUT THIS IS FOR SQLITE-MULTIPLE-CIPHERS, a contemporary version of sqlite supporting cipher
but NOT same as SqlCipher and is NOT interoperative with SqlCipher!!


3. decamp/sqlcipher-jdbc (https://github.com/decamp/sqlcipher-jdbc) : This repository combines
the starts from Xerial Sqlite-Jdbc driver and adds SqlCipher (instead of plain sqlite).
Currently this caters to JDBC driver for SQLCipher, specifically noted for OS X compatibility
in the description section.


4. sqlcipher/sqlcipher-android (https://github.com/sqlcipher/sqlcipher-android) : While not a
direct JDBC driver, this repository provides the SQLCipher implementation for Android, which
is relevant for Java developers working on Android platforms. It demonstrates how SQLCipher
is integrated into the Android SQLite API. 


Other than the work recorded at GitHub, MingW also provides built SqlCipher DLL for windows-64
at https://packages.msys2.org/packages/ (search for "cipher"). But this is NOT enough for building
sqlcipher-jdbc.jar. In addition, the linux version is not available in MingW.


Apart from that, there is a visual-studio based project at
https://www.domstamand.com/compiling-sqlcipher-sqlite-encrypted-for-windows-using-visual-studio-2022/ .
Again, this goes only up to generating a DLL of sqlcipher, but does not give SqlCipher.jar
with native connections between Java and the DLL.


So, Here we decided to stick with decamp work, update it with sqlcipher ver 4.10.0 and build it
for 64-bit versions of Windows and Linux using Jave JDK17. For detailed instructions on building
the common jar file, see the last sections all the way below.


Public Discussion Forum on the JDBC driver
==========================================
*  [Xerial Public Discussion Group](http://groups.google.com/group/xerial?hl=en) 
	Note: for some time now, there are no discussions there. But the forum is open.


Usage
============ 
As in the original work (https://github.com/xerial/sqlite-jdbc)
by [Taro L. Saito](http://www.xerial.org/leo), sqlcipher-jdbc library
requires no configuration since native libraries for both Windows and Linux, are assembled
into a single JAR (Java Archive) file.
Just build the library (JAR file) and append it to your class path. 


1.  Build the jar file (see the last sections below) and then append this jar file into your classpath. 
2.  Load the JDBC driver `org.sqlite.JDBC` from your code. (see the example below)    

** Sample.java**
	
	:::java
    import java.sql.DriverManager;
    import java.sql.ResultSet;
    import java.sql.SQLException;
    import java.sql.Statement;
	import org.sqlite.SQLiteConnection;
	import org.sqlite.jdbc4.JDBC4PreparedStatement;
    
    public class Sample
    {
		public static void main(String[] args) throws ClassNotFoundException
		{
			if (!System.getProperty("os.name").contains("Windows"))
			{
				System.load("/usr/lib/x86_64-linux-gnu/libcrypto.so");
			}
			// load the sqlite-JDBC driver using the current class loader
			Class.forName("org.sqlite.JDBC");
			
			Connection connection = null;
			try
			{
				// add encryption key to properties
				Properties props = new Properties ();
				props.put ( "key", "your_encryption_key");

				// prepare URL with database file path and file name
				String strUrl="jdbc:sqlite:D:\\your_folder\\your_database_file";

				// create a database connection
				SQLiteConnection dbConnect = (SQLiteConnection) DriverManager.getConnection (strUrl, props);
				  
				String sqlVersionStmt = "select sqlite_version()";
				JDBC4PreparedStatement verStmt = new JDBC4PreparedStatement (dbConnect, sqlVersionStmt);
				ResultSet verRs = verStmt.executeQuery();
				String strSqliteVersion = "";
				if (verRs.next())
					strSqliteVersion += verRs.getString(1);
				System.out.println ("****** Sqlite version = " + strSqliteVersion + " ****** ");
				
				// List db tables
				String sqlStmt = "SELECT name FROM sqlite_master WHERE type='table'";
				JDBC4PreparedStatement stmt = new JDBC4PreparedStatement (dbConnect, sqlStmt);
				ResultSet rs = stmt.executeQuery();
				int nIndex = 0;
				while (rs.next())
				{
					String strTblTitle = rs.getString("name");
					System.out.println ("Table Index = " + ++nIndex + " :: Table Title = " + strTblTitle);
				}

				readStudentsTable(dbConnect);
				dbConnect.close();
				
				System.out.println ("****** Sqlite version = " + strSqliteVersion + " ****** ");
			} 
			catch (Exception ex) 
			{
				ex.printStackTrace();
			}
		}
	  
		private static int readStudentsTable (SQLiteConnection dbConnect)
		{
			// assumes that your-database has a table by name "Students" with columns "FirstName" and "FirstName",
			// and has entries to read
			int nIndex = 0;
			String sqlStmt = "SELECT * FROM Students;";
			try
			{
				JDBC4PreparedStatement stmt = new JDBC4PreparedStatement (dbConnect, sqlStmt);
				ResultSet rs = stmt.executeQuery();
				while (rs.next())
				{
					String strFirstName = rs.getString("FirstName");
					String strLastName = rs.getString("LastName");
					System.out.println (++nIndex + " :: FirstName = " + strFirstName + ", LastName = " + strLastName);
				}
			}
			catch (Exception ex)
			{
				ex.printStackTrace();
			}
			return nIndex;
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
---------------------------
Since sqlite-jdbc-3.6.19, the natively compiled SQLite engines will be used for 
the following operating systems:

*   Windows : x86_64
*   Linux : amd64 (64-bit X86 Intel processor) 

For the other OSs not listed above, if you want to use the native library for your OS,
you will need to build the source from scratch.


How does sqlcipher-jdbc work?
---------------------------
Similar to xerial's SQLite JDBC driver package, sqlcipher-jdbc
(i.e., `sqlcipher-jdbc-(VERSION).jar`) contains different 
types of native SQLite libraries (`sqlcipher-jdbc.dll`, `sqlcipher-jdbc.so`), 
each of them is compiled for Windows and Linux. An appropriate native library 
file is automatically extracted into your OS's temporary folder, when your program 
loads `org.sqlite.JDBC` driver. 


License
==========
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



Using with Tomcat6 Web Server
=============================
sqlcipher-jdbc can be used with Tomcat6 Web Server in the same way as xerial's SQLite JDBC driver package.

Do not include sqlcipher-jdbc-(version).jar in WEB-INF/lib folder of your web application 
package, since multiple web applications hosted by the same Tomcat server cannot 
load the sqlite-jdbc native library more than once. That is the specification of 
JNI (Java Native Interface). You will observe `UnsatisfiedLinkError` exception with 
the message "no SQLite library found".

Work-around of this problem is to put `sqlcipher-jdbc-(version).jar` file into `(TOMCAT_HOME)/lib` 
directory, in which multiple web applications can share the same native library 
file (.dll, .jnilib, .so) extracted from this sqlite-jdbc jar file. 

If you are using Maven for your web application, set the dependency scope as 'provided', 
and manually put the sqlcipher-jdbc jar file into (TOMCAT_HOME)/lib folder.

    <dependency>
        <groupId>org.xerial</groupId>
        <artifactId>sqlite-jdbc</artifactId>
        <version>3.7.2</version>
        <scope>provided</scope>
    </dependency>



Build process
==================
The following are the steps to follow to upgrade SqlCipher to the latest (or the version
that you desire) and build a common jar for 64-bit Windows and Linux.

1. Windows-x64: Building sqlcipher project and testing sqlite3.exe (sqlite with sqlCipher)

2. Windows-x64: Building SqlCipherJdbc.jar (for Windows only, for now)

3. Linux (amd64) : Building sqlcipher project

The above steps are explained in detail the following sections. I have also added an additional 
section on notes on tools and libraries used.


Building sqlcipher project for Windows-x64
-------------------------------------------
Steps to build sqlcipher related files that are needed for common sqlcipher-jdbc jar file

1. MSYS2 installation
    Download and install MSYS2 to C:\Tools\msys64\ folder from its official website (https://www.msys2.org/)
    Launch the MSYS2 MinGW 64-bit terminal (C:\Tools\msys64\msys2_shell.cmd -use-full-path)
    Update the package databases and core system packages using the following lines:

    pacman -Syuu # multiple times until there is nothing more gets updated
	pacman -S mingw-w64-ucrt-x86_64-toolchain # this installs 29 base utils like make, gcc, openssl and tcl etc. then exceute the lines below to get full versions
	pacman -S mingw-w64-ucrt-x86_64-openssl
	pacman -S mingw-w64-ucrt-x86_64-autotools
	pacman -S mingw-w64-ucrt-x86_64-tcl
    pacman -S mingw-w64-ucrt-x86_64-gcc # GCC to start compiling projects
	pacman -S mingw-w64-ucrt-x86_64-make
	
	pacman -Qqe # to list all the packages installed so far by pacman
	pacman -R <package_names|package_groups> # for removing packages
	pacman -Ss <package_names|package_groups> # for searching packages
	
	Add C:\Tools\msys64\ucrt\bin to PATH in system-env in windows
	
	Create a new system environment variable named MSYS2_PATH_TYPE.
	Set its value to inherit. This will apply the inheritance setting globally to all MSYS2 shells launched on the system.

	Create a shortcut using "C:\Tools\msys64\msys2_shell.cmd -use-full-path" and use this to launch msys2
	
	
2. TCL - NOT NEEDED if pacman instruction is used. Otherwise...
	Install TCL (tutorial says not needed, but another issue description at
	http://stackoverflow.com/questions/2515774/sqlcipher-mingw-msys-problem
	says that TCL is needed.
	
	Download TCL from
	https://sourceforge.net/projects/magicsplat/files/magicsplat-tcl/
	and select "tcl-8.6.16-installer-1.16.0-x64.msi" to download
	https://sourceforge.net/projects/magicsplat/files/magicsplat-tcl/tcl-8.6.16-installer-1.16.0-x64.msi/download
	
	Start a command prompt and use the following command (OTHERWISE it will install in Users/../AppData/...)
	msiexec /i tcl-8.6.16-installer-1.16.1-x64.msi ALLUSERS=1 APPLICATIONFOLDER="C:\Program Files\Tcl-x64\" /passive
	
	
3. Download SQL-Cipher by choosing a version or latest version (NOT MASTER)
	current version 4.10.0
	extract to C:\Tools\sqlcipher folder, after saving the original to repo


4. start msys2 shell using "C:\Tools\msys64\msys2_shell.cmd -use-full-path"
	gcc --version # to make sure that gcc path is correctly set
	
	cd /c # Change to C:
	cd C:\Tools\sqlcipher
	
	from https://github.com/sqlcipher/sqlcipher combine it with a few more learnings from ChatGPT and issue reports
	./configure --with-tempstore=yes \
		CFLAGS="-DSQLITE_ENABLE_LOAD_EXTENSION=1 \
		-DSQLITE_ENABLE_UPDATE_DELETE_LIMIT \
		-DSQLITE_ENABLE_COLUMN_METADATA \
		-DSQLITE_CORE \
		-DSQLITE_ENABLE_FTS3 \
		-DSQLITE_ENABLE_FTS3_PARENTHESIS \
		-DSQLITE_ENABLE_RTREE \
		-DSQLITE_ENABLE_STAT2 \
		-DSQLITE_HAS_CODEC \
		-DSQLCIPHER_CRYPTO_OPENSSL \
		-DSQLITE_THREADSAFE=1 \
		-DSQLITE_TEMP_STORE=2 \
		-DSQLITE_EXTRA_INIT=sqlcipher_extra_init \
		-DSQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown"  \
		LDFLAGS="-L/ucrt64/bin -lcrypto-3-x64"
	
	It prints the following lines at the end of a long set of logs
	
	Created Makefile from Makefile.in
	Created sqlite3.pc from sqlite3.pc.in
	Created sqlite_cfg.h
	That is a successful configuration!!


5. After this, the Makefile had to be MODIFIED manually to remove DSQLITE_OMIT_LOAD_EXTENSION=1 everywhere!!
	This is because, CFLAGS has --disable-load-extension in it!


6. Continuing with MSYS2 terminal...
	make clean
	make sqlite3.c --enable-load-extension
	make
	make dll 
	This creates the required output files (C:\Tools\sqlcipher\sqlite3.exe and C:\Tools\sqlcipher\sqlite3.dll)
	
	OUTPUTS : All in C:\Tools\sqlcipher folder 
	sqlite3.exe - used for testing later
	sqlite3.c, sqlite3.h, sqlite3ext.h and sqlite3.o - MUST NEED for bulding JDBC driver
			NOTE: Although the names are sqlite3, these are sqlcipher (based on sqlite3) related files.
	sqlite3.dll - THIS is the first DLL, but this is not of much use in common jar creation
		as the JDBC is going to use sqlite3.c, .h etc.
	libsqlite3.dll.a and libsqlite3.a - static libraries - again, not of much use!
	msys-sqlite3-0.dll - DLL with msys debug classes -  again, not of much use!
	a lot of other files, that are not of much use


7. ISSUES faced:
	while compiling if you see, "stdlib.h not found error" means msys2 installation has mixed up tools (ucrt, x64 etc.)
	Just uninstall msys2 using C:\Tools\mysys2\uninstall.exe
	Reinstall msys2 and follow the above steps and MORE IMPORTANTLY use  "ucrt" in every pacman instruction


8. Testing sqlite3.exe (sqlite with sqlCipher)
	In this example, created a new et with key="ezKey"

	cd C:\Tools\sqlcipher
	
	sqlcipher.exe et # this starts sqlcipher with new db named "et"

	sqlite> PRAGMA cipher_version;
	4.10.0 community
	sqlite> PRAGMA key="ezKey";
	sqlite> .database
	main: D:\ezTemp\SqlCipherTest\et r/w
	sqlite> CREATE TABLE Students (StudentId INTEGER PRIMARY KEY NOT NULL,
		FirstName TEXT NOT NULL, LastName TEXT NOT NULL, BirthDate TEXT, Email TEXT UNIQUE);
	sqlite> .tables
	Students
	sqlite> .schema
	CREATE TABLE Students (StudentId INTEGER PRIMARY KEY NOT NULL,
		FirstName TEXT NOT NULL, LastName TEXT NOT NULL, BirthDate TEXT, Email TEXT UNIQUE);
	sqlite> Insert into Students(FirstName, LastName, BirthDate, Email) VALUES ("Sri", "Ram", "01-01-2000", "sri_ram@zohomail.com");
	sqlite> select * from Students;
	1|Sri|Ram|01-01-2000|sri_ram@gmail.com
	sqlite>  Insert into Students(FirstName, LastName, BirthDate, Email) VALUES ("your", "name", "01-01-2010", "your_name@gmail.com");
	sqlite> select * from Students;
	1|Sri|Ram|01-01-2000|sri_ram@gmail.com
	2|your|name|01-01-2010|your_name@gmail.org
	sqlite> .quit


Build process : Building sqllitejdbc.dll library for Windows
------------------------------------------------------------
Steps to build sqlcipher related files (sqllitejdbc.dll for Windows) that are later used to
create a common sqlcipher-jdbc jar file

1. This fork has the entire project with all the source files for JDBC driver
	from https://github.com/decamp/sqlcipher-jdbc (2015) and modified for it to work with SqlCipher 4.10.0 and Java17 and 64-bit arch.
	download to (for example) C:\Tools\sqlcipher-jdbc

2. Makefile is modified to automatically Copy from C:\Tools\sqlcipher\sqlite3.dll to
	C:\Tools\sqlcipher-jdbc\src\main\resources\org\sqlite\native\Windows\amd64 (yes, it is amd64 and not x64)
	
3. Start MSYS2 terminal using "C:\Tools\msys64\msys2_shell.cmd -use-full-path"
	make clean;
	make win64;
	This creates sqllitejdbc.dll in the temp (target) dir first and then copies it to
		C:\Tools\sqlcipher-jdbc\src\main\resources\org\sqlite\native\Windows\amd64
	This is the SECOND DLL that includes both sqlite3 from previous set of instructions and NativeDB.c interfaces from this project
	This DLL is going to be used in creating sqlcipher-jdbc.jar in the next few steps
	
4. A Note about the JNI interface files and the DLL that is created using them 

	External Inputs: sqlite3.h and sqlite3.o copied (created by Make script) from sqlcipher folder

	Inputs within SqlCipherJdbc folder : "trio" files (DB.java, NativeDB.java and NativeDb.c)

	Output: sqllitejdbc.dll

	(a) DB.java has the interface functions defined (like _open, _close etc. for db).
		These are the interface functions that the next higher layer of callers use to make use of native library.

	(b) NativeDB.java - extends DB.java and redefines the interfaces defined in DB.java as
		the JNI interface functions. So, the next higher layer callers instantiate NativeDB class
		object and uses the interface functions defined in DB class. It is so as to abstract the 
		"native" nature of those interface functions to this layer and not expose the same to everyone above this layer.

	(c) NativeDB.c is the C counterpart of NativeDB.java where the JNI interfaces functions are implemented
		and inside those functions, the sqlcipher native functions are called to get the work done.
		Hence without the trio files (DB.java, NativeDB.java and NativeDb.c) the higher layer
		callers can never get to the native library functions.

	Any change or new interface needs to be implemented in these trio functions.


Build process : Building libsqlitejdbc.so library for Linux
-----------------------------------------------------------
Steps to build sqlcipher related files (sqlcipher-jdbc.so for Linux) that are later used to
create a common sqlcipher-jdbc jar file

1. Compile sqlcipher (ver 4.10.0) in <your-folder>/tools/sqlcipher folder to get sqlcipher.exe ((named sqlite3)

	./configure --with-tempstore=yes \
		CFLAGS="-DSQLITE_ENABLE_LOAD_EXTENSION=1 \
		-DSQLITE_ENABLE_LOAD_EXTENSION=1 \
		-DSQLITE_ENABLE_UPDATE_DELETE_LIMIT \
		-DSQLITE_ENABLE_COLUMN_METADATA \
		-DSQLITE_CORE \
		-DSQLITE_ENABLE_FTS3 \
		-DSQLITE_ENABLE_FTS3_PARENTHESIS \
		-DSQLITE_ENABLE_RTREE \
		-DSQLITE_ENABLE_STAT2 \
		-DSQLITE_HAS_CODEC \
		-DSQLCIPHER_CRYPTO_OPENSSL \
		-DSQLITE_THREADSAFE=1 \
		-DSQLITE_TEMP_STORE=2 \
		-DSQLITE_EXTRA_INIT=sqlcipher_extra_init \
		-DSQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown -fPIC" \
		LDFLAGS="-lcrypto"
			
	The above script prints lot of lines with "ok" at the end and finally the following three lines.
		Created Makefile from Makefile.in
		Created sqlite3.pc from sqlite3.pc.in
		Created sqlite_cfg.h
	That is a successful configuration!!
		
	make # build everything needed
	sudo make install # install the "libsqlite3.a" and "libsqlite.so" in "/usr/local/lib" folder

2. Test sqlcipher (named sqlite3) with the known et
	 > ./sqlite3 # it should give sqlite prompt
		% .version # it should give sqlite3 version 3.50.4 (SqlCipher version 4.10.0 Community)
	   a) "PRAGMA cipher_version;" should print the version of sqlcipher version, again!
	   b) .help for help
	   c) .quit for quit or exit
	   d) PRAGMA key="ezKey"; for the 'et' file provided in this folder
		   
3. Create libsqlitejdbc.so
	a) Copy C:\Tools\sqlcipher-jdbc to <your-folder>/tools/sqlcipher-jdbc folder 
	# all make files are modified appropriately to copy the appropriate files from sqlcipher folder
	make clean
	make Linux64

4. Copy the libsqlitejdbc.so file to C:\Tools\sqlcipher-jdbc folder.
	ie., copy <your-folder>/tools/sqlcipher-jdbc/src/main/resources/org/sqlite/native/Linux/amd64
	to C:\Tools\sqlcipher-jdbc\src\main\resources\org\sqlite\native\Linux\amd64


Build process : Building common sqlcipher-jdbc.jar (for Windows and Linux)
--------------------------------------------------------------------------
Steps for building sqlcipher-jdbc.jar (common for windows and linux) and test it. It is important to 
test the .dll and jar file so that any issues with native interface etc. are resolved here, before
a common jar file created to use at both Windows and Linux.
NOTE: In this project, Netbeans has been used to create the common sqlcipher-jdbc.jar file.

1. If the sqllitejdbc.dll (for Windows) was built here, then that DLL will already be at the right place

2. If not done already, copy the libsqlitejdbc.so file to C:\Tools\sqlcipher-jdbc folder.
	ie., copy <your-folder>/tools/sqlcipher-jdbc/src/main/resources/org/sqlite/native/Linux/amd64
	to C:\Tools\sqlcipher-jdbc\src\main\resources\org\sqlite\native\Linux\amd64

3. Open Netbeans and start this project (sqlcipher-jdbc)
	(and let maven download all the required files it needs)
	
4. Comment out the maven-gpg-plugin configuration in pom.xml (if it is still there)
	OR configure it to skip sign+encrypt stage using gpg
	
5. Netbeans : build sqlcipher-jdbc.jar
	This will create C:\Tools\sqlcipher-jdbc\target\classes\org\sqlite\native\Windows\x86\sqlitejdbc.dll
	by copying the file from above resource folder and will create C:\Tools\sqlcipher-jdbc\target\sqlcipher-jdbc.jar

	project in Netbeans -- Properties -> General -> Change ArtifactId and version to create jar with the required name

	ArtifactId = sqlcipher and Version = jdbc to create jar file sqlcipher-jdbc.jar
	
	Clean and build

6. Junit  tests: During the above step, the projects is devised to run 166 tests. and they should all pass.
	Check for any errors (like deprecated etc.) and fix them.
	NOTE: Unfortunately these tests could not be run in Linux as these are junit tests (on Netbeans on Windows in our setup).
	
	OUTPUT: sqlcipher-jdbc.jar in C:\Tools\sqlcipher-jdbc\target folder.

	COPY THIS MANUALLY to your-library-folder for use by other Java projects (like SqlCipherJdbcTest or servlets)
		
	SQLiteJDBCLoader.loadSQLiteNativeLibrary() in this jar loads the appropriate .dll
	or .so file (after linux part is also built) included in the the jar.
	So one common jar serves both windows and linux, as long as the resource folder had libs (.dll and .so) for Windows and Linux

7. ISSUES faced:

	SQLiteException with Unsatisfied LinkError - cannot find _open function
	This issue arised because the first DLL from building sqlcipher was used in creating sqlcipher-jdbc.jar.
	That first DLL does NOT have JNI interfaces defined in trio files (DB.java, NativeDB.java and NativeDb.c).
	Due to that, the outer layer caller never found _open, _close etc. defined as JNI interface functions
	to get to the sqlCipher native library.
	Once the second DLL was created using the above steps the outer layer caller could reach the inner native
	library through the JNI interface functions. This resolved the issue.


Build process : Additional notes
---------------------------------
1. As stated before, Used MSYS2 to compile sqlcipher project on windows
	and Netbeans for compiling the common jar file
2. The project is compiled for Java-17 
3. Used MySql 8.0.x and mysql-connector-j-9.3.0.jar to test with servlets on both windows and linux
