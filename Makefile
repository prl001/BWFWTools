PREFIX=/usr/local
BIN=$(PREFIX)/bin
LIB=$(PREFIX)/lib/perl

MODULEDIR=Beyonwiz

SCRIPTS=bwhack.pl bw_rootfs.pl getksyms.pl gunzip_bflt.pl make_kern_bflt.pl \
	pack_wrp.pl unpack_wrp.pl wrp_hdrs.pl
MODULES=$(MODULEDIR)/Kernel.pm

all:

install: all install_lib install_bin

install_lib:
	mkdir -p '$(LIB)/$(MODULEDIR)'
	cp $(MODULES) '$(LIB)/$(MODULEDIR)'

install_bin:
	mkdir -p '$(LIB)'
	@for s in $(SCRIPTS); do \
		echo Install $$s in $(BIN); \
		sed "/use constant PERLS/s|'\.'|'$(BIN)'|" $$s > '$(BIN)'/$$s; \
		chmod a+x '$(BIN)'/$$s; \
	done

uninstall: uninstall_bin uninstall_lib

uninstall_bin:
	cd '$(BIN)' && rm -f $(SCRIPTS)
	
uninstall_lib:
	cd '$(LIB)' && rm -f $(MODULES)
	-rmdir '$(LIB)/$(MODULEDIR)'
	
doc::
	./make_doc.sh $(SCRIPTS) $(MODULES)
