ccflags-y			:= -I$(KERNEL_SRC)/drivers/usb/gadget/
ccflags-y			+= -I$(KERNEL_SRC)/drivers/usb/gadget/function/
ccflags-y			+= -I$(KERNEL_SRC)/drivers/usb/gadget/udc/

obj-m := dbdhiddevice.o f_hid.o emulator_uuid.o

# SRC += "$(PWD)/"

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) modules

modules_install:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) modules_install

clean:
	rm -f *.o *~ core .depend .*.cmd *.ko *.mod.c *.mod
	rm -f Module.markers Module.symvers modules.order
	rm -rf .tmp_versions Modules.symvers
