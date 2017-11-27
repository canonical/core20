DPKG_ARCH := $(shell dpkg --print-architecture)
SUDO := sudo

all: check
	# nothing

install:
	$(SUDO) debootstrap --variant=minbase bionic $(DESTDIR)
	for f in ./hooks/[0-9]*; do \
		cp -a $$f ./build/tmp; \
		$(SUDO) chroot ./build /tmp/$$(basename $$f); \
		rm -f ./build/tmp/$$(basename $$f); \
	done;
	# only generate manifest file for lp build
	if [ -e /build/base-18 ]; then \
		$(SUDO) chroot ./build dpkg -l > /build/core/base-18-$$(date +%Y%m%d%H%M)_$(DPKG_ARCH).manifest; \
	fi;
check:
	id
	# exlucde "useless cat" from checks, while useless also
	# some things more readable
	shellcheck -e SC2002 hooks/*

