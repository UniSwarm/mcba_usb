obj-m+=udt1cri_usb.o

FILES = LICENSE Makefile README.md udt1cri.sh udt1cri_usb.c dkms.conf
PACKAGE_VERSION=0.1

KERNEL_UNAME ?= $(shell uname -r)
KERNEL_SRC ?= /lib/modules/$(KERNEL_UNAME)/build/
SRC := $(shell pwd)
DEPMOD := depmod -a

PATH_DKMS=/etc/dkms/keys

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules

clean:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) clean

modules_install: all
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules_install
	$(DEPMOD)	

run:
	modprobe --remove udt1cri_usb || true
	$(MAKE) modules_install
	sudo modprobe udt1cri_usb

run_auto:dkms udev_install

dkms:
	mkdir -p /usr/src/udt1_linux_driver-$(PACKAGE_VERSION)
	cp $(FILES) /usr/src/udt1_linux_driver-$(PACKAGE_VERSION)
	sudo dkms add udt1_linux_driver -v $(PACKAGE_VERSION)
	sudo dkms build udt1_linux_driver -v $(PACKAGE_VERSION)
	sudo dkms install udt1_linux_driver -v $(PACKAGE_VERSION)
	
remove_all:
	sudo dkms remove  udt1_linux_driver/0.1 --all
	rm -rf /usr/src/udt1_linux_driver-$(PACKAGE_VERSION)
	rm -f /lib/udev/rules.d/98-udt1cri_usb.rules

udev_install:
	mkdir -p /usr/src/udt1_linux_driver-$(PACKAGE_VERSION)
	cp $(FILES) /usr/src/udt1_linux_driver-$(PACKAGE_VERSION)
	cp 98-udt1cri_usb.rules /lib/udev/rules.d
	chmod	+x /usr/src/udt1_linux_driver-$(PACKAGE_VERSION)/udt1cri.sh
	udevadm control --reload 

secure_boot:
	mkdir -p $(PATH_DKMS)
	chmod 700 $(PATH_DKMS)
	openssl req -new -x509 -newkey rsa:2048 -keyout $(PATH_DKMS)/MOK.priv -outform DER -out $(PATH_DKMS)/MOK.der -days 36500 -subj "/CN=$(hostname) module signing key/" || exit 1
	mokutil --import $(PATH_DKMS)/MOK.der || exit 1
	
test:
	g++ -lgtest_main -lgtest -lpthread ./tests/mcba_tests.cpp -o ./tests/mcba_tests
	./tests/mcba_tests --gtest_break_on_failure

