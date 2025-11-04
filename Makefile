# use JDK to build native libraries

include Makefile.common

RESOURCE_DIR = src/main/resources

.phony: all package win32 win64 mac32 mac64 linux32 linux64 native deploy

all: package

deploy: 
	mvn deploy 

MVN:=mvn
SRC:=src/main/java
NATIVE_SRC:=$(SRC)/org/sqlite/core
SQLITE_OUT:=$(TARGET)/$(sqlite)-$(OS_NAME)-$(OS_ARCH)
#SQLITE_ARCHIVE:=$(TARGET)/$(sqlite)-amal.zip
#SQLITE_UNPACKED:=$(TARGET)/sqlite-unpack.log
#SQLITE_AMAL_DIR:=$(TARGET)/$(SQLITE_AMAL_PREFIX)

# CHANGE THIS as per target OS
ifeq ($(OS_NAME),Windows)
	SQLCIPHER_DIR:=/c/Tools/sqlcipher
else
	# assume it is Linux
	SQLCIPHER_DIR:=/home/ezadmin/tools/sqlcipher
endif

SQLCIPHER_BLD_DIR:=$(SQLCIPHER_DIR)

# Note that that SQLITE_OMIT_LOAD_EXTENSION cannot be disabled on Macs due
# to a bug in the SQLITE automake config. To make matters worse, SQLITE
# doesn't even include the function to test whether extensions can be 
# loaded unless SQLITE_OMIT_LOAD_EXTENSION = 0. Rather than try to patch
# SQLITE, we just include that flag here to be explicit, AND so that compiling
# the JNI code will function correctly and not try to test if extensions 
# are available.
SQLITE_FLAGS:=\
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
	-DSQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown

# CHANGE THIS as per target OS
ifeq ($(OS_NAME),Windows)
	CFLAGS:= -I$(SQLITE_OUT) -I$(SQLITE_AMAL_DIR) $(CFLAGS) $(SQLITE_FLAGS) \
		-I/c/Tools/OpenSSL-Win64/include $(SQLCIPHER_DIR)/libcrypto-3-x64.dll \
		-L$(SQLCIPHER_DIR) -static-libgcc
else # assume it is Linux
	CFLAGS:= -I$(SQLITE_OUT) -I$(SQLITE_AMAL_DIR) $(CFLAGS) $(SQLITE_FLAGS) \
		-I/usr/lib/jvm/default-java/include -fPIC
endif

$(SQLITE_ARCHIVE):
	@mkdir -p $(@D)
	curl -o$@ http://www.sqlite.org/2013/$(SQLITE_AMAL_PREFIX).zip

$(SQLITE_UNPACKED): $(SQLITE_ARCHIVE)
	unzip -qo $< -d $(TARGET)
	touch $@
	    
$(SQLITE_OUT)/org/sqlite/%.class: src/main/java/org/sqlite/%.java
	@mkdir -p $(@D)
	$(JAVAC) -source 17 -target 17 -sourcepath $(SRC) -d $(SQLITE_OUT) $<

jni-header: $(NATIVE_SRC)/NativeDB.h

$(SQLITE_OUT)/NativeDB.h: $(SQLITE_OUT)/org/sqlite/core/NativeDB.class
	$(JAVAH) $(NATIVE_SRC) -d $(SQLITE_OUT) -classpath $(SQLITE_OUT) $(NATIVE_SRC)/NativeDB.java
	mv $(NATIVE_SRC)/org_sqlite_core_NativeDB.h $(NATIVE_SRC)/NativeDB.h

# Apple uses different include path conventions.
ifeq ($(OS_NAME),Mac)
	cp $@ $@.tmp
	perl -p -e "s/#include \<jni\.h\>/#include \<JavaVM\/jni.h\>/" $@.tmp > $@
	rm $@.tmp
endif

test:
	mvn test

clean: clean-native clean-java clean-tests

$(SQLITE_OUT)/sqlite3.o:
	@mkdir -p $(@D)
	cp $(SQLCIPHER_BLD_DIR)/sqlite3.o $(SQLITE_OUT)/sqlite3.o
	cp $(SQLCIPHER_BLD_DIR)/sqlite3.h $(SQLITE_OUT)/sqlite3.h
	@echo "Copied sqlite3.o and sqlite3.h from sqlcipher/build to the target dir"
	read -p "Press enter to continue" DUMMY_INPUT

$(SQLITE_OUT)/$(LIBNAME): $(SQLITE_OUT)/sqlite3.o $(SRC)/org/sqlite/core/NativeDB.c $(SQLITE_OUT)/NativeDB.h
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $(SQLITE_OUT)/NativeDB.o $(NATIVE_SRC)/NativeDB.c 
	read -p "NativeDB.c is complied. Press enter to continue" DUMMY_INPUT
	$(CC) $(CFLAGS) -o $@ $(SQLITE_OUT)/sqlite3.o $(SQLITE_OUT)/NativeDB.o $(LINKFLAGS)
	read -p "sqlitejdbc.dll is created in temp folder. Press enter to continue" DUMMY_INPUT

	$(STRIP) $@

NATIVE_DIR=src/main/resources/org/sqlite/native/$(OS_NAME)/$(OS_ARCH)
NATIVE_TARGET_DIR:=$(TARGET)/classes/org/sqlite/native/$(OS_NAME)/$(OS_ARCH)
NATIVE_DLL:=$(NATIVE_DIR)/$(LIBNAME)

native: $(SQLITE_OUT)/sqlite3.o $(NATIVE_DLL)

$(NATIVE_DLL): $(SQLITE_OUT)/$(LIBNAME)
	@mkdir -p $(@D)
	cp $< $@
	@mkdir -p $(NATIVE_TARGET_DIR)
	cp $< $(NATIVE_TARGET_DIR)/$(LIBNAME)
	@echo "sqlitejdbc.dll is created in the required folder hierarchy"
	read -p "Press enter to continue" DUMMY_INPUT

win32: 
	$(MAKE) native OS_NAME=Windows OS_ARCH=x86

win64: 
	$(MAKE) native OS_NAME=Windows OS_ARCH=amd64

linux32:
	$(MAKE) native OS_NAME=Linux OS_ARCH=i386

linux64:
	$(MAKE) native OS_NAME=Linux OS_ARCH=amd64

sparcv9:
	$(MAKE) native OS_NAME=SunOS OS_ARCH=sparcv9

mac32:
	$(MAKE) native OS_NAME=Mac OS_ARCH=i386

mac64:
	$(MAKE) native OS_NAME=Mac OS_ARCH=x86_64


package: $(NATIVE64_DLL) native
	rm -rf target/dependency-maven-plugin-markers
	$(MVN) package

clean-native:
	rm -rf $(TARGET)/$(sqlite)-$(OS_NAME)*

clean-java:
	rm -rf $(TARGET)/*classes
	rm -rf $(TARGET)/sqlite-jdbc-*jar

clean-tests:
	rm -rf $(TARGET)/{surefire*,testdb.jar*}
