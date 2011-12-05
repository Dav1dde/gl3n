# define which operating system is used
ifdef SystemRoot
    OS              = "Windows"
    STATIC_LIB_EXT  = ".lib"
    DYNAMIC_LIB_EXT = ".dll"
    FixPath         = $(subst /,\,$1)
    message         = @(echo $1)
else
    ifeq ($(shell uname), Linux)
        OS              = "Linux"
        STATIC_LIB_EXT  = ".a"
        DYNAMIC_LIB_EXT = ".so"
        FixPath         = $1
        message         = @(echo \033[31m $1 \033[0;0m1)
    else ifeq ($(shell uname), Solaris)
        STATIC_LIB_EXT  = ".a"
        DYNAMIC_LIB_EXT = ".so"
        OS              = "Solaris"
        FixPath         = $1
        message         = @(echo \033[31m $1 \033[0;0m1)
    else ifeq ($(shell uname),Darwin)
        STATIC_LIB_EXT  = ".a"
        DYNAMIC_LIB_EXT = ".so"
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
else ifeq ($(OS),"Linux")
    RM    = rm -f
    CP    = cp -fr
    MKDIR = mkdir -p
else ifeq ($(OS),"Darwin")
    RM    = rm -f
    CP    = cp -fr
    MKDIR = mkdir -p
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
    DFLAGS    = -O2 -fdeprecated
    LINKERFLAG= -Xlinker 
    OUTPUT    = -o
else
    DFLAGS    = -O -d
    LINKERFLAG= -L
    OUTPUT    = -of
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
    LDFLAGS += $(LINKERFLAG)-ldl
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
    DFLAGS  += -m64
    LDFLAGS += -m64
else
    DFLAGS  += -m32
    LDFLAGS += -m32
endif


# Define var PREFIX, LIB_DIR and INCLUDEDIR
ifndef PREFIX
    ifeq ($(OS),"Windows") 
        PREFIX = $(PROGRAMFILES)
    else ifeq ($(OS), "Linux")
        PREFIX = /usr/local
    else ifeq ($(OS), "Darwin")
        PREFIX = /usr/local
    endif
endif
ifndef LIB_DIR
    ifeq ($(OS),"Windows") 
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

ifndef CC
    CC = gcc
endif

DLIB_PATH          = ./lib
IMPORT_PATH        = ./import
DOC_PATH           = ./doc
BUILD_PATH         = ./build

DFLAGS_IMPORT      = -I"gl3n"
DFLAGS_LINK        = $(LDFLAGS)

LIBNAME_GL3N       = lib$(PROJECT_NAME)-$(COMPILER)$(STATIC_LIB_EXT)
SONAME_GL3N        = lib$(PROJECT_NAME)$(DYNAMIC_LIB_EXT)

MAKE               = make
AR                 = ar
ARFLAGS            = rcs
RANLIB             = ranlib

export CC
export OS
export STATIC_LIB_EXT
export DYNAMIC_LIB_EXT
export COMPILER
export FixPath
export DC
export DFLAGS
export LDFLAGS
export MODEL
export FPIC
export LINKERFLAG
export OUTPUT
export PREFIX
export LIB_DIR
export INCLUDE_DIR
export message
export CP
export RM
export MKDIR
export DLIB_PATH
export IMPORT_PATH
export DOC_PATH
export BUILD_PATH
export DFLAGS_IMPORT
export DFLAGS_LINK
export LIBNAME_GL3N
export SONAME_GL3N
export MAKE
export AR
export ARFLAGS
export RANLIB
export ARCH