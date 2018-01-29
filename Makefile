DPKG_ARCH := $(shell dpkg --print-architecture)
BASE := bionic-base-$(DPKG_ARCH).tar.gz

.PHONY: all
all: check
	# nothing

.PHONY: install
install:
	# install base
	if [ -z "$(DESTDIR)" ]; then \
		echo "no DESTDIR set"; \
		exit 1; \
	fi
	if [ ! -f ../$(BASE) ]; then \
		wget -P ../ http://cdimage.ubuntu.com/ubuntu-base/daily/current/$(BASE); \
	fi
	rm -rf $(DESTDIR)
	mkdir -p $(DESTDIR)
	tar -x -f ../$(BASE) -C $(DESTDIR)
	# ensure resolving works inside the chroot
	cat /etc/resolv.conf > $(DESTDIR)/etc/resolv.conf
	# customize
	set -ex; for f in ./hooks/[0-9]*.chroot; do \
		cp -a $$f $(DESTDIR)/tmp && \
		if ! chroot $(DESTDIR) /tmp/$$(basename $$f); then \
                    exit 1; \
                fi && \
		rm -f $(DESTDIR)/tmp/$$(basename $$f); \
	done;
	# only generate manifest file for lp build
	if [ -e /build/base-18 ]; then \
		echo $$f; \
		cp $(DESTDIR)/usr/share/snappy/dpkg.list /build/base-18/base-18-$$(date +%Y%m%d%H%M)_$(DPKG_ARCH).manifest; \
	fi;

.PHONY: check
check:
	# exclude "useless cat" from checks, while useless also
	# some things more readable
	shellcheck -e SC2002 hooks/*


# Display a report of files that are (still) present in /etc
.PHONY: etc-report
etc-report:
	cd stage && find etc/
	echo "Amount of cruft in /etc left: `find stage/etc/ | wc -l`"

.PHONY: update-image
update-image:
	sudo snapcraft clean
	sudo snapcraft
	sudo $(MAKE) -C tests/lib just-update
