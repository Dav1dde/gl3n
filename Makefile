# thanks to "bioinfornatics" from the #D channel on freenode for making this Makefile

export PROJECT_NAME = gl3n
# include some command
include command.make

SOURCES            = gl3n/interpolate.d gl3n/linalg.d gl3n/math.d gl3n/util.d
OBJECTS            = $(patsubst %.d,$(BUILD_PATH)/%.o,    $(SOURCES))
PICOBJECTS         = $(patsubst %.d,$(BUILD_PATH)/%.pic.o,$(SOURCES))
HEADERS            = $(patsubst %.d,$(IMPORT_PATH)/%.di,  $(SOURCES))
DOCUMENTATIONS     = $(patsubst %.d,$(DOC_PATH)/%.html,   $(SOURCES))
define make-lib
	$(MKDIR) $(DLIB_PATH)
	$(AR) rcs $(DLIB_PATH)/$@ $^
	$(RANLIB) $(DLIB_PATH)/$@
endef

all: static-libs header doc ddoc

static-libs: $(LIBNAME_GL3N)

shared-libs: $(SONAME_GL3N)

header: $(HEADERS)

doc: $(DOCUMENTATIONS)

ddoc:
	$(DC) cutedoc.ddoc settings.ddoc modules.ddoc index.d $(DF)$(DOC_PATH)/index.html

geany-tag:
	$(MKDIR) geany_config
	geany -c geany_config -g $(PROJECT_NAME).d.tags $(SOURCES)

# For build lib need create object files and after run make-lib
$(LIBNAME_GL3N): $(OBJECTS)
	$(make-lib)

# create object files
$(BUILD_PATH)/%.o : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(DFLAGS_IMPORT) -c $< $(OUTPUT)$@

# Generate Header files
$(IMPORT_PATH)/%.di : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(DFLAGS_IMPORT) -c -o- $< $(HF)$@

# Generate Documentation
$(DOC_PATH)/%.html : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(DFLAGS_IMPORT) -c -o- $< $(DF)$@

# For build shared lib need create shared object files
$(SONAME_GL3N): $(PICOBJECTS)
	$(CC) -shared $^ -o $@

# create shared object files
$(BUILD_PATH)/%.pic.o : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(FPIC) $(DFLAGS_IMPORT) -c $< $(OUTPUT) $@ 

.PHONY: clean

clean:
	$(RM) $(OBJECTS)
	$(RM) $(PICOBJECTS)
	$(RM) $(LIBNAME_GL3N)
	$(RM) $(HEADERS)
	$(RM) $(DOCUMENTATIONS)
	$(RM) $(DOC_PATH)/index.html

install:
	$(MKDIR) $(LIB_DIR)
	$(CP) $(DLIB_PATH)/* $(LIB_DIR)
	$(MKDIR) $(INCLUDE_DIR)
	$(CP) $(IMPORT_PATH)/* $(INCLUDE_DIR)