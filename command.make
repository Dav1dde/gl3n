ifdef SystemRoot
    OS              = "Windows"
    STATIC_LIB_EXT  = .lib
    DYNAMIC_LIB_EXT = .dll
    PATH_SEP        =\
    FixPath         = $(subst /,\,$1)
    message         = @(echo $1)
    SHELL           = cmd.exe
else
    SHELL           = sh
    PATH_SEP        =/
    ifeq ($(shell uname), Linux)
        OS              = "Linux"
        STATIC_LIB_EXT  = .a
        DYNAMIC_LIB_EXT = .so
        FixPath         = $1
        message         = @(echo \033[31m $1 \033[0;0m1)
    else ifeq ($(shell uname), Solaris)
        STATIC_LIB_EXT  = .a
        DYNAMIC_LIB_EXT = .so
        OS              = "Solaris"
        FixPath         = $1
        message         = @(echo \033[31m $1 \033[0;0m1)
    else ifeq ($(shell uname),Darwin)
        STATIC_LIB_EXT  = .a
        DYNAMIC_LIB_EXT = .so
        OS              = "Darwin"
        FixPath         = $1
        message         = @(echo \033[31m $1 \033[0;0m1)
    endif
endif

# Define command for copy, remove and create file/dir
ifeq ($(OS),"Windows")
    RM    = del /Q
    CP    = copy /Y
    MKDIR = mkdir
    MV    = move
else ifeq ($(OS),"Linux")
    RM    = rm -fr
    CP    = cp -fr
    MKDIR = mkdir -p
    MV    = mv
else ifeq ($(OS),"Darwin")
    RM    = rm -fr
    CP    = cp -fr
    MKDIR = mkdir -p
    MV    = mv
endif

# If compiler is not define try to find it
ifndef DC
    ifneq ($(strip $(shell which dmd 2>/dev/null)),)
        DC=dmd
    else ifneq ($(strip $(shell which ldc 2>/dev/null)),)
        DC=ldc
    else ifneq ($(strip $(shell which ldc2 2>/dev/null)),)
        DC=ldc2
    else
        DC=gdc
    endif
endif

# Define flag for gdc other
ifeq ($(DC),gdc)
    DCFLAGS    = -O2 -fdeprecated
    LINKERFLAG= -Xlinker
    OUTPUT    = -o
    HF        = -fintfc-file=
    DF        = -fdoc-file=
    NO_OBJ    = -fsyntax-only
    DDOC_MACRO= -fdoc-inc=
else
    DCFLAGS    = -O -d
    LINKERFLAG= -L
    OUTPUT    = -of
    HF        = -Hf
    DF        = -Df
    NO_OBJ    = -o-
    DDOC_MACRO=
endif

#define a suufix lib who inform is build with which compiler
ifeq ($(DC),gdc)
    COMPILER=gdc
else ifeq ($(DC),gdmd)
    COMPILER=gdc
else ifeq ($(DC),ldc)
    COMPILER=ldc
else ifeq ($(DC),ldc2)
    COMPILER=ldc
else ifeq ($(DC),ldmd)
    COMPILER=ldc
else ifeq ($(DC),dmd)
    COMPILER=dmd
else ifeq ($(DC),dmd2)
    COMPILER=dmd
endif

# Define relocation model for ldc or other
ifneq (,$(findstring ldc,$(DC)))
    FPIC = -relocation-model=pic
else
    FPIC = -fPIC
endif

# Add -ldl flag for linux
ifeq ($(OS),"Linux")
    LDCFLAGS += $(LINKERFLAG)-ldl
endif

# If model are not gieven take the same as current system
ARCH = $(shell arch || uname -m)
ifndef MODEL
    ifeq ($(ARCH), x86_64)
        MODEL = 64
    else
        MODEL = 32
    endif
endif

ifeq ($(MODEL), 64)
    DCFLAGS  += -m64
    LDCFLAGS += -m64
else
    DCFLAGS  += -m32
    LDCFLAGS += -m32
endif

ifndef DESTDIR
    DESTDIR =
endif
    
# Define var PREFIX, BIN_DIR, LIB_DIR, INCLUDE_DIR, DATA_DIR
ifndef PREFIX
    ifeq ($(OS),"Windows")
        PREFIX = $(PROGRAMFILES)
    else ifeq ($(OS), "Linux")
        PREFIX = /usr/local
    else ifeq ($(OS), "Darwin")
        PREFIX = /usr/local
    endif
endif

ifndef BIN_DIR
    ifeq ($(OS), "Windows")
        BIN_DIR = $(PROGRAMFILES)\$(PROJECT_NAME)\bin
    else ifeq ($(OS), "Linux")
        BIN_DIR = $(PREFIX)/bin
    else ifeq ($(OS), "Darwin")
        BIN_DIR = $(PREFIX)/bin
    endif
endif
ifndef LIB_DIR
    ifeq ($(OS), "Windows")
        LIB_DIR = $(PREFIX)\$(PROJECT_NAME)\lib
    else ifeq ($(OS), "Linux")
        LIB_DIR = $(PREFIX)/lib
    else ifeq ($(OS), "Darwin")
        LIB_DIR = $(PREFIX)/lib
    endif
endif

ifndef INCLUDE_DIR
    ifeq ($(OS), "Windows")
        INCLUDE_DIR = $(PROGRAMFILES)\$(PROJECT_NAME)\import
    else ifeq ($(OS), "Linux")
        INCLUDE_DIR = $(PREFIX)/include/d/$(PROJECT_NAME)
    else ifeq ($(OS), "Darwin")
        INCLUDE_DIR = $(PREFIX)/include/d/$(PROJECT_NAME)
    endif
endif

ifndef DATA_DIR
    ifeq ($(OS), "Windows")
        DATA_DIR = $(PROGRAMFILES)\$(PROJECT_NAME)\data
    else ifeq ($(OS), "Linux")
        DATA_DIR = $(PREFIX)/share
    else ifeq ($(OS), "Darwin")
        DATA_DIR = $(PREFIX)/share
    endif
endif

ifndef PKGCONFIG_DIR
    ifeq ($(OS), "Windows")
        PKGCONFIG_DIR = $(PROGRAMFILES)\$(PROJECT_NAME)\data
    else ifeq ($(OS), "Linux")
        PKGCONFIG_DIR = $(DATA_DIR)/pkgconfig
    else ifeq ($(OS), "Darwin")
        PKGCONFIG_DIR = $(DATA_DIR)/pkgconfig
    endif
endif

ifndef CC
    CC = gcc
endif

DLIB_PATH          = ./lib
IMPORT_PATH        = ./import
DOC_PATH           = ./doc
DDOC_PATH          = ./ddoc
BUILD_PATH         = ./build

DCFLAGS_IMPORT      = -I"gl3n/"
DCFLAGS_LINK        = $(LDCFLAGS)

LIBNAME       = lib$(PROJECT_NAME)-$(COMPILER)$(STATIC_LIB_EXT)
SONAME        = lib$(PROJECT_NAME)-$(COMPILER)$(DYNAMIC_LIB_EXT)

PKG_CONFIG_FILE    = $(PROJECT_NAME).pc

MAKE               = make
AR                 = ar
ARFLAGS            = rcs
RANLIB             = ranlib

export AR
export ARCH
export ARFLAGS
export BIN_DIR
export BUILD_PATH
export CC
export COMPILER
export CP
export DATA_DIR
export DC
export DF
export DCFLAGS
export DCFLAGS_IMPORT
export DCFLAGS_LINK
export DESTDIR
export DLIB_PATH
export DOC_PATH
export DDOC_PATH
export DYNAMIC_LIB_EXT
export FixPath
export HF
export INCLUDE_DIR
export IMPORT_PATH
export LDCFLAGS
export FPIC
export LIBNAME
export LIB_DIR
export LINKERFLAG
export message
export MAKE
export MKDIR
export MODEL
export MV
export OUTPUT
export OS
export PATH_SEP
export PKG_CONFIG_FILE
export PREFIX
export RANLIB
export RM
export STATIC_LIB_EXT
export SONAME