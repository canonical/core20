DPKG_ARCH := $(shell dpkg --print-architecture)

.PHONY: all
all: check
	# nothing

.PHONY: install
install:
	debootstrap --variant=minbase bionic $(DESTDIR)
	set -ex; for f in ./hooks/[0-9]*; do \
		cp -a $$f $(DESTDIR)/tmp; \
		chroot $(DESTDIR) /tmp/$$(basename $$f); \
		rm -f $(DESTDIR)/tmp/$$(basename $$f); \
	done;
	# only generate manifest file for lp build
	if [ -e /build/base-18 ]; then \
		echo $$f; \
		cp $(DESTDIR)/usr/share/snappy/dpkg.list /build/base-18/base-18-$$(date +%Y%m%d%H%M)_$(DPKG_ARCH).manifest; \
	fi;

.PHONY: check
check:
	id
	# exclude "useless cat" from checks, while useless also
	# some things more readable
	shellcheck -e SC2002 hooks/*

