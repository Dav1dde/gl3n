# https://github.com/bioinfornatics/MakefileForD
export PROJECT_NAME = gl3n
export AUTHOR       = David Herberth
export DESCRIPTION  = OpenGL Maths for D (not glm for D but better).
export VERSION      = 
export LICENSE      = MIT
SOURCES             = gl3n/interpolate.d gl3n/linalg.d gl3n/math.d gl3n/util.d
DDOCFILES	    = cutedoc.ddoc settings.ddoc modules.ddoc

# include some command
include command.make

OBJECTS             = $(patsubst %.d,$(BUILD_PATH)$(PATH_SEP)%.o,    $(SOURCES))
PICOBJECTS          = $(patsubst %.d,$(BUILD_PATH)$(PATH_SEP)%.pic.o,$(SOURCES))
HEADERS             = $(patsubst %.d,$(IMPORT_PATH)$(PATH_SEP)%.di,  $(SOURCES))
DOCUMENTATIONS      = $(patsubst %.d,$(DOC_PATH)$(PATH_SEP)%.html,   $(SOURCES))
DDOCUMENTATIONS     = $(patsubst %.d,$(DDOC_PATH)$(PATH_SEP)%.html,  $(SOURCES))
DDOC_FLAGS          = $(foreach macro,$(DDOCFILES), $(DDOC_MACRO)$(macro))
define make-lib
	$(MKDIR) $(DLIB_PATH)
	$(AR) rcs $(DLIB_PATH)$(PATH_SEP)$@ $^
	$(RANLIB) $(DLIB_PATH)$(PATH_SEP)$@
endef

############# BUILD ############# 
all: static-lib header doc pkgfile
	@echo ------------------ building $^ done

.PHONY : pkgfile
.PHONY : doc
.PHONY : ddoc
.PHONY : clean

static-lib: $(LIBNAME)

shared-lib: $(SONAME)

header: $(HEADERS)

doc: $(DOCUMENTATIONS)

ddoc: $(DDOCUMENTATIONS)
	$(DC) $(DDOC_FLAGS) index.d $(DF)$(DDOC_PATH)$(PATH_SEP)index.html

geany-tag:
	@echo ------------------ creating geany tag
	$(MKDIR) geany_config
	geany -c geany_config -g $(PROJECT_NAME).d.tags $(SOURCES)

pkgfile:
	@echo ------------------ creating pkg-config file
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
	@echo Version: "$(VERSION)"                                         >> $(PKG_CONFIG_FILE)
	@echo Libs: -L$(LIB_DIR) $(LINKERFLAG)-l$(PROJECT_NAME)-$(COMPILER) >> $(PKG_CONFIG_FILE)
	@echo Cflags: -I$(INCLUDE_DIR)                                      >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)


# For build lib need create object files and after run make-lib
$(LIBNAME): $(OBJECTS)
	@echo ------------------ creating static library
	$(make-lib)

# For build shared lib need create shared object files
$(SONAME): $(PICOBJECTS)
	@echo ------------------ creating shared library
	$(MKDIR) $(DLIB_PATH)
	$(CC) -shared $^ -o $(DLIB_PATH)$(PATH_SEP)$@

# create object files
$(BUILD_PATH)$(PATH_SEP)%.o : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(DFLAGS_IMPORT) -c $< $(OUTPUT)$@

# create shared object files
$(BUILD_PATH)$(PATH_SEP)%.pic.o : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(FPIC) $(DFLAGS_IMPORT) -c $< $(OUTPUT)$@

# Generate Header files
$(IMPORT_PATH)$(PATH_SEP)%.di : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(DFLAGS_IMPORT) -c $(NO_OBJ) $< $(HF)$@

# Generate Documentation
$(DOC_PATH)$(PATH_SEP)%.html : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(DFLAGS_IMPORT) -c $(NO_OBJ)  $< $(DF)$@

# Generate ddoc Documentation
$(DDOC_PATH)$(PATH_SEP)%.html : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(DFLAGS_IMPORT) -c $(NO_OBJ) $(DDOC_FLAGS) $< $(DF)$@


############# CLEAN ############# 
clean: clean-objects clean-static-lib clean-doc clean-header clean-pkgfile
	@echo ------------------ cleaning $^ done

clean-objects:
	$(RM) $(OBJECTS)

clean-shared-objects:
	$(RM) $(PICOBJECTS)

clean-static-lib:
	$(RM) $(SONAME)

clean-shared-lib:
	$(RM) $(LIBNAME)

clean-header:
	$(RM) $(HEADERS)

clean-doc:
	$(RM) $(DOCUMENTATIONS)
	$(RM) $(DOC_PATH)

clean-ddoc:
	$(RM) $(DOC_PATH)$(PATH_SEP)index.html
	$(RM) $(DDOC_PATH)

clean-geany-tag:
	$(RM) geany_config $(PROJECT_NAME).d.tags

clean-pkgfile:
	$(RM) $(PKG_CONFIG_FILE)

############# INSTALL #############

install: install-static-lib install-doc install-header install-pkgfile
	@echo ------------------ Installing $^ done

install-static-lib:
	$(MKDIR) $(LIB_DIR)
	$(CP) $(DLIB_PATH)$(PATH_SEP)$(LIBNAME) $(LIB_DIR)

install-shared-lib:
	$(MKDIR) $(LIB_DIR)
	$(CP) $(DLIB_PATH)$(PATH_SEP)$(SONAME) $(LIB_DIR)

install-header:
	$(MKDIR) $(INCLUDE_DIR)
	$(CP) $(IMPORT_PATH) $(INCLUDE_DIR)

install-doc:
	$(MKDIR) $(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)normal_doc$(PATH_SEP)
	$(CP) $(DOC_PATH) $(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)normal_doc$(PATH_SEP)

install-ddoc:
	$(MKDIR) $(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)cute_doc$(PATH_SEP)
	$(CP) $(DDOC_PATH) $(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)cute_doc$(PATH_SEP)
	$(CP) $(DDOC_PATH)$(PATH_SEP)index.html $(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)cute_doc$(PATH_SEP)

install-geany-tag:
	$(CP) $(PROJECT_NAME).d.tags $(DATA_DIR)$(PATH_SEP)geany$(PATH_SEP)tags$(PATH_SEP)

install-pkgfile:
	$(MKDIR) $(PKGCONFIG_DIR)
	$(CP) $(PKG_CONFIG_FILE) $(PKGCONFIG_DIR)