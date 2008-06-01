PREFIX=/usr/local
BIN=$(PREFIX)/bin
LIB=$(PREFIX)/lib/perl

BWMODULEDIR=Beyonwiz
HACKMODULEDIR=$(BWMODULEDIR)/Hack

SCRIPTS=bw_patcher.pl bw_rootfs.pl bwhack.pl getksyms.pl \
	gunzip_bflt.pl make_kern_bflt.pl pack_wrp.pl svcdat.pl \
	unpack_wrp.pl wrp_hdrs.pl


BWMODULES=$(BWMODULEDIR)/Kernel.pm


HACKMODULES=$(HACKMODULEDIR)/BwhackSupport.pm $(HACKMODULEDIR)/Telnet.pm \
	$(HACKMODULEDIR)/USBHackSupport.pm $(HACKMODULEDIR)/Utils.pm


MODULES=$(BWMODULES) $(HACKMODULES)

all:

install: all install_lib install_bin

install_lib:
	mkdir -p '$(LIB)/$(BWMODULEDIR)' '$(LIB)/$(HACKMODULEDIR)'
	@echo Installing modules to $(BWMODULES)
	@for s in $(BWMODULES); do \
		cp $$s '$(LIB)/$(BWMODULEDIR)'; \
		chmod a+r '$(LIB)'/$$s; \
	done
	@echo Installing modules to $(HACKMODULEDIR)
	@for s in $(HACKMODULES); do \
		cp $$s '$(LIB)/$(HACKMODULEDIR)'; \
		chmod a+r '$(LIB)'/$$s; \
	done

install_bin:
	mkdir -p '$(LIB)'
	cp $(SCRIPTS) '$(BIN)'
	@for s in $(SCRIPTS); do \
		echo Install $$s in $(BIN); \
		cp $$s '$(BIN)'/$$s; \
		chmod a+rx '$(BIN)'/$$s; \
	done

uninstall: uninstall_bin uninstall_lib

uninstall_bin:
	cd '$(BIN)' && rm -f $(SCRIPTS)
	
uninstall_lib:
	cd '$(LIB)' && rm -f $(MODULES)
	-rmdir '$(LIB)/$(HACKMODULEDIR)' '$(LIB)/$(BWMODULEDIR)'
	
doc::
	./make_doc.sh $(SCRIPTS) $(MODULES)
