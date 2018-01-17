DPKG_ARCH := $(shell dpkg --print-architecture)

.PHONY: all
all: check
	# nothing

.PHONY: install
install: DESTDIR?=$(error you must set DESTDIR)
install:
	debootstrap --variant=minbase bionic $(DESTDIR)
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
