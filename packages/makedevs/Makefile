toolchain:
	$(STEP) "Makedevs"
	gcc -O2 -I$(TOOLS_DIR)/include $(PACKAGES_DIR)/makedevs/makedevs.c -o $(TOOLS_DIR)/bin/makedevs -L$(TOOLS_DIR)/lib -Wl,-rpath,$(TOOLS_DIR)/lib
	chmod -v 755 $(TOOLS_DIR)/bin/makedevs
