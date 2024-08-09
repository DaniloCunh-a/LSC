#------ Check the distribution we are working on ----------------------------------------
CXX_TARGET = $(shell $(CXX) -v 2>&1 | grep "Target:" | cut -c9-)
CXX_VERSION = $(shell g++ -v 2>&1 | grep "gcc version" | cut -d' ' -f3)
CXX_VERSION_MAJOR := $(shell echo $(CXX_VERSION) | cut -f1 -d.)
CXX_VERSION_MINOR := $(shell echo $(CXX_VERSION) | cut -f2 -d.)
CXX_VERSION_GREATER_THAN_4_9 := $(shell echo \($(CXX_VERSION_MAJOR)\>4\) \|\| \(\($(CXX_VERSION_MAJOR)==4\) \&\& \($(CXX_VERSION_MINOR)\>=9\)\) | bc )
CXX_VERSION_GREATER_THAN_4_2 := $(shell echo \($(CXX_VERSION_MAJOR)\>4\) \|\| \(\($(CXX_VERSION_MAJOR)==4\) \&\& \($(CXX_VERSION_MINOR)\>=2\)\) | bc )

ifeq ($(CXX_TARGET), arm-fslc-linux-gnueabi)
   # we are cross-compiling to a IMX
   IMX6 := 1
   DISTRO_NAME := imx6-crosscompile
   REL_DIR := $(DISTRO_NAME)-release
   DBG_DIR := $(DISTRO_NAME)-debug
else
   # It is a regular linux distribution
   DISTRO_NAME := $(shell \
   if [ -f "/etc/os-release" ]; then \
   grep "^ID=" /etc/os-release | cut -d= -f2 | sed -e 's/^"//' -e 's/"$$//'; \
   else if [ -f "/etc/SuSE-release" ]; then \
   head -n 1 /etc/SuSE-release | cut -d\ -f1; \
   else \
   echo "unknown"; \
   fi; fi | tr '[:upper:]' '[:lower:]')

   ifneq (,$(findstring x86_64,$(CXX_TARGET)))
      PLAT_ARCH := x86_64-
   else
      PLAT_ARCH :=
   endif

   KERNEL_VER := $(shell uname -r)
   REL_DIR := $(DISTRO_NAME)-$(KERNEL_VER)-$(PLAT_ARCH)release
   DBG_DIR := $(DISTRO_NAME)-$(KERNEL_VER)-$(PLAT_ARCH)debug
endif
#----------------------------------------------------------------------------------------


ifeq ($(IMX6),1)
   RPATH = /opt/DieboldNixdorf/lib
else
   RPATH = /opt/DieboldProcomp/lib
endif

comma := ,
RPATH_DIR = $(addprefix -Wl$(comma)-rpath$(comma),$(RPATH))

ifndef STRIP
	STRIP := strip
endif

#------ Generic include directories for headers ------
CONV_INC=$(procomp_dir)/Modulos/Conv/3.Api_Componentes/conv/inc/lnx

INCLUDES_DIR = -I$(CONV_INC)

# If the INC directory has been defined, include it on the INCLUDES_DIR
ifneq ($(INC),)
	INCLUDES_DIR += $(addprefix -I,$(INC))
endif

INCLUDES_DIR := $(subst |, ,$(INCLUDES_DIR))

ifneq ($(SRC),)
	VPATH += $(subst |, ,$(SRC))
endif

ifneq ($(WRK),)
	VPATH += $(subst |, ,$(WRK))
	INCLUDES_DIR += -I$(subst |, ,$(WRK))
endif

#------[ Compiler and Linker flags ]------
ifeq ($(IMX6),1)
   TARGET_CFLAGS   := $(CFLAGS) -DIMX6=1
   TARGET_CXXFLAGS := $(CXXFLAGS) $(CPPFLAGS) -DIMX6=1
   TARGET_LDFLAGS  := $(LDFLAGS)
else
   TARGET_CFLAGS   := $(shell if [ -f "/usr/bin/dpkg-buildflags" ]; then /usr/bin/dpkg-buildflags --get CFLAGS; fi;)
   TARGET_CXXFLAGS := $(shell if [ -f "/usr/bin/dpkg-buildflags" ]; then /usr/bin/dpkg-buildflags --get CXXFLAGS; fi;)
   TARGET_CXXFLAGS += $(shell if [ -f "/usr/bin/dpkg-buildflags" ]; then /usr/bin/dpkg-buildflags --get CPPFLAGS; fi;)
   TARGET_LDFLAGS  := $(shell if [ -f "/usr/bin/dpkg-buildflags" ]; then /usr/bin/dpkg-buildflags --get LDFLAGS; fi;)
endif

#-fvisibility=hidden -fvisibility-inlines-hidden
TARGET_CFLAGS   += -g -O2 -Wall -Wextra -pipe -Wshadow -Wwrite-strings -Wredundant-decls -Winit-self \
						 -Wold-style-definition -Wbad-function-cast -Wnested-externs \
						 -Wformat -fPIC -fdata-sections -ffunction-sections -c
TARGET_CXXFLAGS += -g -O2 -Wall -Wextra -pipe -Wshadow -Wwrite-strings -Wredundant-decls -Winit-self \
						 -Wuseless-cast -Wformat -Werror=format-security -fPIC -fdata-sections -ffunction-sections -c
TARGET_LDFLAGS  += -pipe -Wl,--no-undefined -Wl,--gc-sections -Wl,--as-needed

ifeq ($(CXX_VERSION_GREATER_THAN_4_2),1)
   TARGET_CFLAGS   += -Werror=format-security 
endif

ifeq ($(CXX_VERSION_GREATER_THAN_4_9),1)
   TARGET_CFLAGS   += -fstack-protector-strong -fdiagnostics-color=auto
   TARGET_CXXFLAGS += -fstack-protector-strong -fdiagnostics-color=auto
   TARGET_LDFLAGS  += -fdiagnostics-color=auto
endif

ifneq ($(KERNEL_VER),2.6.24.6)
	TARGET_LDFLAGS += -Wl,--no-allow-shlib-undefined -Wl,-Bsymbolic-functions
endif

TARGET_CFLAGS   += $(INCLUDES_DIR)
TARGET_CXXFLAGS += $(INCLUDES_DIR)
TARGET_LDFLAGS  += $(MODULE_LD)
#------[ End of Compiler and Linker flags ]------

ifneq ($(MAKECMDGOALS),)
	ifneq (,$(findstring release,$(MAKECMDGOALS)))
		OUT_DIR := $(REL_DIR)
	else ifneq (,$(findstring debug,$(MAKECMDGOALS)))
		OUT_DIR := $(DBG_DIR)
		TARGET_CFLAGS += -D_DEBUG -g
	endif
endif

#------ Generic include directories for libraries ------
CONV_LIB=$(procomp_dir)/Modulos/Conv/3.Api_Componentes/conv/wrk/lnx/$(OUT_DIR)

LIBS_DIR=-L$(OUT_DIR) -L$(CONV_LIB)

# If the LIB directory has been defined, include it on the LIBS_DIR
# HUGE HACK: there is no way to define a path with spaces, so to avoid that, if a path contain whitespaces, it should be
#            enclosed with "" and all spaces should be replaced by "|". This next line will replace all "|" by whitespace
#            Ex: LIB = "$(procomp_dir)/../Module|System|Development/OptevaXFS/main/src/bin/$(OUT_DIR)"
ifneq ($(LIB),)
	LIBS_DIR += $(addprefix -L,$(LIB))
endif

LIBS_DIR := $(subst |, ,$(LIBS_DIR))

# If OBJS was not defined (the expected), create if based on the SOURCES variable
ifeq ($(OBJS),)
	CSRC	 := $(filter %.c,$(SOURCES))
	CXXSRC := $(filter %.cpp,$(SOURCES))
	OBJS   := $(CSRC:%.c=%.o) $(CXXSRC:%.cpp=%.o)
endif

#--- cppcheck variables ---
CPPCHECK_BIN := cppcheck
CPPCHECK_CONFIG=--enable=all --quiet --suppress=missingIncludeSystem --inline-suppr --library=$(procomp_dir)/cppcheck.cfg
CPPCHECK_DEFINES = -D__linux__ -D_LINUX_ -D__GNUC__ -U_WIN32 -UWIN32
CPPCHECK_FORMAT := --template="   [{file}:{line}]: ({severity}, {id}) {message}"
ifneq ($(COMPILE_TYPE), "bin")
	# disables the unusedFunction warning for libraries
   CPPCHECK_CONFIG += --suppress=unusedFunction
endif

help:
	@echo "ERROR: use a make parameter: check, tidy, install clean, debug or release"

check: $(SOURCES)
	@echo ""
ifeq ($(SOURCES),)
	@echo "   ------------------------------ ERROR ------------------------------"
	@echo "   Makefile is in legacy format. In order to 'make check', the project"
	@echo "   makefile needs to define the SOURCES variable instead of OBJS."
	@echo "   -------------------------------------------------------------------"
else
	@echo "   ----------------------------------- Checking source agains CppCheck ---------------------------------"
	@$(CPPCHECK_BIN) $(CPPCHECK_CONFIG) $(CPPCHECK_DEFINES) $(CPPCHECK_FORMAT) $(INCLUDES_DIR) $^
	@echo "   ---------------------------------------- CppCheck completed -----------------------------------------"
endif
	@echo ""

#--- clang-tidy variables ---
CLANG_TIDY_CHECKS=misc-*,modernize-*,performance-*cppcoreguidelines-pro-type-cstyle-cast,google-readability-casting,readability-else-after-return,readability-inconsistent-declaration-parameter-name

tidy: $(SOURCES)
	@echo ""
ifeq ($(SOURCES),)
	@echo "   ------------------------------ ERROR ------------------------------"
	@echo "   Makefile is in legacy format. In order to 'make tidy', the project"
	@echo "   makefile needs to define the SOURCES variable instead of OBJS."
	@echo "   -------------------------------------------------------------------"
else
	@echo "   ----------------------------------- Checking source agains clang-tidy ---------------------------------"
	$(MAKE) clean
	bear $(MAKE) release
	clang-tidy -p ./ -vv -checks="$(CLANG_TIDY_CHECKS)" $^
	@echo "   ---------------------------------------- clang-tidy completed -----------------------------------------"
endif
	@echo ""

coffee:
	@echo "                        (";
	@echo "                          )     (";
	@echo "                   ___...(-------)-....___";
	@echo "               .-\"\"       )    (          \"\"-.";
	@echo "         .-'\`\`'|-._             )         _.-|";
	@echo "        /  .--.|   \`\"\"---...........---\"\"\`   |";
	@echo "       /  /    |                             |";
	@echo "       |  |    |                             |";
	@echo "        \  \   |                             |";
	@echo "         \`\ \`\ |                             |";
	@echo "           \`\ \`|                             |";
	@echo "           _/ /;                             ;";
	@echo "          (__/  \                           /";
	@echo "       _..---\"\"\` \                         /\`\"\"---.._";
	@echo "    .-'           \                       /          '-.";
	@echo "   :               \`-.__             __.-'              :";
	@echo "   :                  ) \"\"---...---\"\" (                 :";
	@echo "    '._               \`\"--...___...--\"\`              _.'";
	@echo "      \\\"\"--..__                              __..--\"\"/";
	@echo "       '._     \"\"\"----.....______.....----\"\"\"     _.'";
	@echo "          \`\"\"--..,,_____            _____,,..--\"\"\`";
	@echo "                        \`\"\"\"----\"\"\"\`";

strip:
	@echo "     |||||    "
	@echo "    ||. .||   "
	@echo "   |||\=/|||   I'm stripping $(REL_DIR)/$(TARGET) for you my master!"
	@echo "   |.-- --.|  "
	@echo "   /(.) (.)\  "
	@echo "   \ ) . ( /  "
	@echo "   '(  v  )\`"
	@echo "     \ | /    "
	@echo "     ( | )    "
	@echo "     '- -\`  "
	-@$(STRIP) -s $(REL_DIR)/$(TARGET)
# These target are used to do some extra stuff when building. You need to overwrite it on the makefile
install_extra: install

install: $(OUT_DIR)/$(TARGET)
#	@cd $(OUT_DIR); ln -sfv $(TARGET) $(BASENAME)
	@cd $(OUT_DIR); cp -v $(TARGET) $(BASENAME)
ifneq ($(INSTALL_DIR),)
	@echo "---[ Installing ]---"
	@cp -pv $< $(INSTALL_DIR)
ifeq ($(COMPILE_TYPE), "shared_lib")
ifneq ($(IMX6),1)
	@cd $(INSTALL_DIR); $(STRIP) --strip-unneeded $(TARGET)
endif
	@cd $(INSTALL_DIR); ln -sfv $(TARGET) $(BASENAME)
#	@cd $(INSTALL_DIR); cp -v $(TARGET) $(BASENAME)
else ifeq ($(COMPILE_TYPE), "bin")
ifneq ($(IMX6),1)
	@cd $(INSTALL_DIR); $(STRIP) -s $(TARGET)
endif
	@cd $(INSTALL_DIR); ln -sfv $(TARGET) $(BASENAME)
#	@cd $(INSTALL_DIR); cp -v $(TARGET) $(BASENAME)
endif
else
ifneq ($(IMX6),1)
ifeq ($(COMPILE_TYPE), "shared_lib")
	@echo "Striping $(OUT_DIR)/$(TARGET)"
	@$(STRIP) --strip-unneeded $(OUT_DIR)/$(TARGET)
else
	@echo "Striping $(OUT_DIR)/$(TARGET)"
	@$(STRIP) -s $(OUT_DIR)/$(TARGET)
endif
endif
endif

set_dirs_lnx:
ifneq ($(OUT_DIR),)
	-@mkdir -p $(OUT_DIR)
endif

debug: install install_extra

release: install install_extra

clean:
ifneq ($(COMPILE_TYPE), "just_install")
	@echo "---[ Cleaning ]---"
	-@ rm -rf compile_commands.json
	@echo "Cleaning '$(DBG_DIR)' directory..."
	-@ rm -rf $(DBG_DIR)
	@echo "Cleaning '$(REL_DIR)' directory..."
	-@ rm -rf $(REL_DIR)
endif

.PHONY: install clean release debug check tidy

# pull in dependency info for *existing* .o files
ifneq ($(MAKECMDGOALS),)
ifeq (,$(filter $(MAKECMDGOALS),clean check tidy coffe))
-include $(OBJS:%.o=$(OUT_DIR)/%.d)
endif
endif

#
# Generic build rules
#
ifneq ($(OUT_DIR),)

.SECONDARY: $(OBJS:%.o=$(OUT_DIR)/%.d)
# Define the dependency between the object files (*.o and *.d) and the creation of the directories
$(OBJS:%=$(OUT_DIR)/%) $(OBJS:%.o=$(OUT_DIR)/%.d): | set_dirs_lnx

# Final target build rule
$(OUT_DIR)/$(TARGET): $(OBJS:%=$(OUT_DIR)/%)
	@echo "---[ Linking ]---"
ifeq ($(COMPILE_TYPE), "shared_lib")
	@echo "   (CXX) $@"
	@$(CXX) -shared -o $@ $^ $(TARGET_LDFLAGS) -Wl,--version-script,version -Wl,--defsym,"VERSAO_$(VERSAO)"=0 $(RPATH_DIR) $(LIBS_DIR) $(LIBS)
else ifeq ($(COMPILE_TYPE), "static_lib")
	@echo "   (AR) $@"
	@$(AR) rcs $@ $^
else ifeq ($(COMPILE_TYPE), "bin")
	@echo "   (CXX) $@"
	@$(CXX) -o $@ $^ $(TARGET_LDFLAGS) -Wl,--defsym,"VERSAO_$(VERSAO)"=0 $(RPATH_DIR) $(LIBS_DIR) $(LIBS)
endif

# Generic build rule for .c to .o
$(OUT_DIR)/%.o: %.c $(OUT_DIR)/%.d
	@echo "   (CC)  $< -> $@"
	@$(CC) $(TARGET_CFLAGS) $(MODULE_DEFS) $< -o $@

# Generic build rule for .cpp to .o
$(OUT_DIR)/%.o: %.cpp $(OUT_DIR)/%.d
	@echo "   (CXX) $< -> $@"
	@$(CXX) $(TARGET_CXXFLAGS) $(MODULE_DEFS) $< -o $@

# Generic build rule for .vrs to .o
$(OUT_DIR)/%.o: %.vrs $(OUT_DIR)/%.d
	@echo "   (CXX) $< -> $@"
	@$(CXX) $(TARGET_CXXFLAGS) $(MODULE_DEFS) -x c++ $< -o $@

# Generic build rule for .c to .d
$(OUT_DIR)/%.d: %.c
	@echo "   (CC)  $< -> $@"
	@$(CC) -MM -MT '$@ $(@:%.d=%.o)' $(TARGET_CFLAGS) $(MODULE_DEFS) $< -o $@

# Generic build rule for .cpp to .d
$(OUT_DIR)/%.d: %.cpp
	@echo "   (CXX) $< -> $@"
	@$(CXX) -MM -MT '$@ $(@:%.d=%.o)' $(TARGET_CXXFLAGS) $(MODULE_DEFS) $< -o $@

# Generic build rule for .vrs to .d
$(OUT_DIR)/%.d: %.vrs
	@echo "   (CXX) $< -> $@"
	@$(CXX) -x c++ -MM -MT '$@ $(@:%.d=%.o)' $(TARGET_CXXFLAGS) $(MODULE_DEFS) $< -o $@
endif
