DPKG_ARCH := $(shell dpkg --print-architecture)
SUDO := sudo

all: check
	$(SUDO) debootstrap --variant=minbase bionic ./build
	for f in ./hooks/[0-9]*; do \
		cp -a $$f ./build/tmp; \
		$(SUDO) chroot ./build /tmp/$$(basename $$f); \
		rm -f ./build/tmp/$$(basename $$f); \
	done;

clean:
	$(SUDO) rm -rf ./build

install:
	chmod 1777 ./build/tmp
	cp -ar ./build $(DESTDIR)
	# only generate manifest file for lp build
	if [ -e /build/base-16 ]; then \
		$(SUDO) chroot ./build dpkg -l > /build/core/base-18-$$(date +%Y%m%d%H%M)_$(DPKG_ARCH).manifest; \
	fi;

check:
	# exlucde "useless cat" from checks, while useless also
	# some things more readable
	shellcheck -e SC2002 hooks/*

