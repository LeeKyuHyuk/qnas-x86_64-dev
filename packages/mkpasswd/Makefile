toolchain:
	$(STEP) "Mkpasswd"
	gcc -O2 -I$(TOOLS_DIR)/include -L$(TOOLS_DIR)/lib -Wl,-rpath,$(TOOLS_DIR)/lib $(PACKAGES_DIR)/mkpasswd/mkpasswd.c $(PACKAGES_DIR)/mkpasswd/utils.c -o $(TOOLS_DIR)/bin/mkpasswd -lcrypt
	chmod -v 755 $(TOOLS_DIR)/bin/mkpasswd
