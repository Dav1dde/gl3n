# https://github.com/bioinfornatics/MakefileForD
export PROJECT_NAME     = gl3n
export AUTHOR           = David Herberth
export DESCRIPTION      = OpenGL Maths for D (not glm for D but better).
export REPO_SRC_DIR     =
export LOGO_SRC         =
export MAJOR_VERSION    = 1
export MINOR_VERSION    = 0
export PATCH_VERSION    = 0
export PROJECT_VERSION  = $(MAJOR_VERSION).$(MINOR_VERSION).$(PATCH_VERSION)
export LICENSE          = MIT
export ROOT_SOURCE_DIR  = gl3n
DDOCFILES               = modules.ddoc settings.ddoc bootDoc$(PATH_SEP)bootdoc.ddoc

# include some command
include command.make

SOURCES             = $(getSource)
OBJECTS             = $(patsubst %.d,$(BUILD_PATH)$(PATH_SEP)%.o,    $(SOURCES))
PICOBJECTS          = $(patsubst %.d,$(BUILD_PATH)$(PATH_SEP)%.pic.o,$(SOURCES))
HEADERS             = $(patsubst %.d,$(IMPORT_PATH)$(PATH_SEP)%.di,  $(SOURCES))
DOCUMENTATIONS      = $(patsubst %.d,$(DOC_PATH)$(PATH_SEP)%.html,   $(SOURCES))
DDOCUMENTATIONS     = $(patsubst %.d,$(DDOC_PATH)$(PATH_SEP)%.html,  $(SOURCES))
DDOC_FLAGS          = $(foreach macro,$(DDOCFILES), $(DDOC_MACRO)$(macro))
space :=
space +=

stripBugfix = $(subst $(space),.,$(strip $(wordlist 1, 2, $(subst ., ,$(1)))))

define make-lib
	$(MKDIR) $(DLIB_PATH)
	$(AR) rcs $(DLIB_PATH)$(PATH_SEP)$@ $^
	$(RANLIB) $(DLIB_PATH)$(PATH_SEP)$@
endef

############# BUILD #############
all: static-lib header doc pkgfile-static
	@echo ------------------ Building $^ done
all-shared: shared-lib header doc pkgfile-shared
	@echo ------------------ Building $^ done

.PHONY : pkgfile
.PHONY : doc
.PHONY : ddoc
.PHONY : clean

static-lib: $(STATIC_LIBNAME)

shared-lib: $(SHARED_LIBNAME)

header: $(HEADERS)

doc: $(DOCUMENTATIONS)
	@echo ------------------ Building Doc done

ddoc: settings.ddoc $(DDOCUMENTATIONS)
	$(DC) $(DDOC_FLAGS) index.d $(DF)$(DDOC_PATH)$(PATH_SEP)index.html
	@echo ------------------ Building DDoc done

geany-tag:
	@echo ------------------ Building geany tag
	$(MKDIR) geany_config
	geany -c geany_config -g $(PROJECT_NAME).d.tags $(SOURCES)

pkgfile-shared:
	@echo ------------------ Building pkg-config file
	@echo "# Package Information for pkg-config"                        >  $(PKG_CONFIG_FILE)
	@echo "# Author: $(AUTHOR)"                                         >> $(PKG_CONFIG_FILE)
	@echo "# Created: `date`"                                           >> $(PKG_CONFIG_FILE)
	@echo "# Licence: $(LICENSE)"                                       >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)
	@echo prefix=$(PREFIX)                                              >> $(PKG_CONFIG_FILE)
	@echo exec_prefix=$(PREFIX)                                         >> $(PKG_CONFIG_FILE)
	@echo libdir=$(LIB_DIR)                                             >> $(PKG_CONFIG_FILE)
	@echo includedir=$(INCLUDE_DIR)                                     >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)
	@echo Name: "$(PROJECT_NAME)"                                       >> $(PKG_CONFIG_FILE)
	@echo Description: "$(DESCRIPTION)"                                 >> $(PKG_CONFIG_FILE)
	@echo Version: "$(PROJECT_VERSION)"                                 >> $(PKG_CONFIG_FILE)
	@echo Libs: $(LINKERFLAG)-l$(PROJECT_NAME)-$(COMPILER)              >> $(PKG_CONFIG_FILE)
	@echo Cflags: -I$(INCLUDE_DIR)$(PATH_SEP)$(PROJECT_NAME) $(LDCFLAGS)>> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)

pkgfile-static:
	@echo ------------------ Building pkg-config file
	@echo "# Package Information for pkg-config"                        >  $(PKG_CONFIG_FILE)
	@echo "# Author: $(AUTHOR)"                                         >> $(PKG_CONFIG_FILE)
	@echo "# Created: `date`"                                           >> $(PKG_CONFIG_FILE)
	@echo "# Licence: $(LICENSE)"                                       >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)
	@echo prefix=$(PREFIX)                                              >> $(PKG_CONFIG_FILE)
	@echo exec_prefix=$(PREFIX)                                         >> $(PKG_CONFIG_FILE)
	@echo libdir=$(LIB_DIR)                                             >> $(PKG_CONFIG_FILE)
	@echo includedir=$(INCLUDE_DIR)                                     >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)
	@echo Name: "$(PROJECT_NAME)"                                       >> $(PKG_CONFIG_FILE)
	@echo Description: "$(DESCRIPTION)"                                 >> $(PKG_CONFIG_FILE)
	@echo Version: "$(PROJECT_VERSION)"                                 >> $(PKG_CONFIG_FILE)
	@echo Libs: $(LIB_DIR)$(PATH_SEP)$(STATIC_LIBNAME)                  >> $(PKG_CONFIG_FILE)
	@echo Cflags: -I$(INCLUDE_DIR)$(PATH_SEP)$(PROJECT_NAME) $(LDCFLAGS)>> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)

settings.ddoc:
	@echo "PROJECTNAME  = $(PROJECT_NAME)"                              >  settings.ddoc
	@echo "LINKPREFIX   = $(LINKERFLAG)"                                >> settings.ddoc
	@echo "REPOSRCDIR   = $(REPO_SRC_DIR)"                              >> settings.ddoc
	@echo "ROOT         = $(ROOT_SOURCE_DIR)"                           >> settings.ddoc
	@echo "LOGOSRC      = $(LOGO_SRC)"                                  >> settings.ddoc
	@echo "LOGOALT      = $(PROJECT_NAME)"                              >> settings.ddoc

# For build lib need create object files and after run make-lib
$(STATIC_LIBNAME): $(OBJECTS)
	@echo ------------------ Building static library
	$(make-lib)

# For build shared lib need create shared object files
$(SHARED_LIBNAME): $(PICOBJECTS)
	@echo ------------------ Building shared library
	$(MKDIR) $(DLIB_PATH)
	$(DC) -shared $(SONAME_FLAG) $@.$(MAJOR_VERSION) $(OUTPUT)$(DLIB_PATH)$(PATH_SEP)$@.$(PROJECT_VERSION) $^
#$(CC) -l$(PHOBOS) -l$(DRUNTIME) -shared -Wl,-soname,$@.$(MAJOR_VERSION) -o $(DLIB_PATH)$(PATH_SEP)$@.$(PROJECT_VERSION) $^

.PHONY: output_directories
output_directories:
	mkdir -p $(dir $(OBJECTS))

# create object files
$(BUILD_PATH)$(PATH_SEP)%.o : %.d output_directories
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

# create shared object files
$(BUILD_PATH)$(PATH_SEP)%.pic.o : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(FPIC) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

# Generate Header files
$(IMPORT_PATH)$(PATH_SEP)%.di : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $(NO_OBJ) $< $(HF)$@

# Generate Documentation
$(DOC_PATH)$(PATH_SEP)%.html : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $(NO_OBJ)  $< $(DF)$@

# Generate ddoc Documentation
$(DDOC_PATH)$(PATH_SEP)%.html : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $(NO_OBJ) $(DDOC_FLAGS) $< $(DF)$@

############# CLEAN #############
clean: clean-objects clean-static-lib clean-doc clean-header clean-pkgfile
	@echo ------------------ Cleaning $^ done

clean-shared: clean-shared-objects clean-shared-lib
	@echo ------------------ Cleaning $^ done

clean-objects:
	$(RM) $(OBJECTS)
	@echo ------------------ Cleaning objects done

clean-shared-objects:
	$(RM) $(PICOBJECTS)
	@echo ------------------ Cleaning shared-object done

clean-static-lib:
	$(RM) $(DLIB_PATH)$(PATH_SEP)$(STATIC_LIBNAME)
	@echo ------------------ Cleaning static-lib done

clean-shared-lib:
	$(RM)  $(DLIB_PATH)$(PATH_SEP)$(SHARED_LIBNAME).$(PROJECT_VERSION)
	@echo ------------------ Cleaning shared-lib done

clean-header:
	$(RM) $(HEADERS)
	@echo ------------------ Cleaning header done

clean-doc:
	$(RM) $(DOCUMENTATIONS)
	$(RM) $(DOC_PATH)
	@echo ------------------ Cleaning doc done

clean-ddoc:
	$(RM) $(DDOC_PATH)$(PATH_SEP)index.html
	$(RM) $(DDOCUMENTATIONS)
	$(RM) $(DDOC_PATH)$(PATH_SEP)$(PROJECT_NAME)
	$(RM) $(DDOC_PATH)
	@echo ------------------ Cleaning ddoc done

clean-geany-tag:
	$(RM) geany_config $(PROJECT_NAME).d.tags
	@echo ------------------ Cleaning geany tag done

clean-pkgfile:
	$(RM) $(PKG_CONFIG_FILE)
	@echo ------------------ Cleaning pkgfile done

############# INSTALL #############

install: install-static-lib install-doc install-header install-pkgfile
	@echo ------------------ Installing $^ done

install-shared: install-shared-lib install-doc install-header install-pkgfile
	@echo ------------------ Installing $^ done

install-static-lib:
	$(MKDIR) $(DESTDIR)$(LIB_DIR)
	$(CP) $(DLIB_PATH)$(PATH_SEP)$(STATIC_LIBNAME) $(DESTDIR)$(LIB_DIR)
	@echo ------------------ Installing static-lib done

install-shared-lib:
	$(MKDIR) $(DESTDIR)$(LIB_DIR)
	$(CP) $(DLIB_PATH)$(PATH_SEP)$(SHARED_LIBNAME).$(PROJECT_VERSION) $(DESTDIR)$(LIB_DIR)
	cd $(DESTDIR)$(LIB_DIR)$(PATH_SEP) && $(LN) $(SHARED_LIBNAME).$(PROJECT_VERSION) $(SHARED_LIBNAME).$(MAJOR_VERSION)
	cd $(DESTDIR)$(LIB_DIR)$(PATH_SEP) && $(LN) $(SHARED_LIBNAME).$(MAJOR_VERSION) $(SHARED_LIBNAME)
	@echo ------------------ Installing shared-lib done

install-header:
	$(MKDIR) $(DESTDIR)$(INCLUDE_DIR)
	$(CP) $(IMPORT_PATH)$(PATH_SEP)$(PROJECT_NAME) $(DESTDIR)$(INCLUDE_DIR)
	@echo ------------------ Installing header done

install-doc:
	$(MKDIR) $(DESTDIR)$(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)normal_doc$(PATH_SEP)
	$(CP) $(DOC_PATH)$(PATH_SEP)* $(DESTDIR)$(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)normal_doc$(PATH_SEP)
	@echo ------------------ Installing doc done

install-ddoc:
	$(MKDIR) $(DESTDIR)$(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)cute_doc$(PATH_SEP)
	$(CP) $(DDOC_PATH)$(PATH_SEP)* $(DESTDIR)$(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)cute_doc$(PATH_SEP)
	@echo ------------------ Installing ddoc done

install-geany-tag:
	$(MKDIR) $(DESTDIR)$(DATA_DIR)$(PATH_SEP)geany$(PATH_SEP)tags$(PATH_SEP)
	$(CP) $(PROJECT_NAME).d.tags $(DESTDIR)$(DATA_DIR)$(PATH_SEP)geany$(PATH_SEP)tags$(PATH_SEP)
	@echo ------------------ Installing geany tag done

install-pkgfile:
	$(MKDIR) $(DESTDIR)$(PKGCONFIG_DIR)
	$(CP) $(PKG_CONFIG_FILE) $(DESTDIR)$(PKGCONFIG_DIR)$(PATH_SEP)$(PROJECT_NAME).pc
	@echo ------------------ Installing pkgfile done
