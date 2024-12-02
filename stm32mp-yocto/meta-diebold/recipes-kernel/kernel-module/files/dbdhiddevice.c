/*
 * hid.c -- HID Composite driver
 *
 * Based on multi.c
 *
 * Copyright (C) 2010 Fabien Chouteau <fabien.chouteau@barco.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */



#define VERBOSE_DEBUG

#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/list.h>
#include <linux/module.h>
#include <linux/usb/composite.h>
#include <linux/usb/g_hid.h>

// #include "gadget_chips.h"

#define DRIVER_DESC		"Diebold's TPD HID Gadget Device"
#define DRIVER_VERSION	"2017/06/12"

#include "u_hid.h"

/*-------------------------------------------------------------------------*/
#define TPD_DEFAULT_VENDOR_ID	0x03F4	/* DIEBOLD */
#define TPD_DEFAULT_PRODUC_ID	0x2019	/* IOP     */
/*-------------------------------------------------------------------------*/


static int id_Product = TPD_DEFAULT_PRODUC_ID;
static char *i_Product = DRIVER_DESC;
static char *i_SerialNumber = "Z9999999991";


//static int g_pid_tpd = idProduct;

/* hid descriptor for a keyboard */
static struct hidg_func_descriptor diebold_hid_data = {
	.subclass		= 0, /* No subclass */
	.protocol		= 0, /* No protocol */
	.report_length		= 1024,  /* DYNAMIC: !!!! MUST BE 1024 (size of largest endpoint) !!!!              *
                               * This value will be altered to match the endpoint size at hidg_set_alt,  *
                               * but it is used to allocate buffer space for some variables. It should   *
                               * only be altered if the endpoint size is also altered. In this case, it  *
                               * might be also necessary to alter hidg_set_alt.                          */
	.report_desc_length	= 66,
	.report_desc		= {   /* ** WARNING ** IF this descriptor is modified, the defines       *
                            * of the positions of all the "Report count" used in hidg_set_alt *
                            * should be altered to match the modification                     */
			0x06, 0x10, 0xFF, // Usage vendor page
			0x09, 0x01,       // Usage reserved
			0xA1, 0x01,       // Collection application
			0x09, 0x01,       // Usage reserved
			0xA1, 0x00,       // Collection physical

			0x85, 0x17,       // Report ID 1
			0x09, 0x02,       // HID usage
			0x15, 0x00,       // Logical min
			0x26, 0xFF, 0x00, // Logical max
			0x75, 0x08,       // Report size
			//0x95, 0x3F,       // Report count
         	0x96, 0xFF, 0x03, // Report count - DYNAMIC: This value will be altered to match the report length
			0x82, 0x02, 0x01, // INPUT DATA|VARIABLE|ABSOLUTE

			0x85, 0x17,       // Report ID 1
			0x09, 0x04,       // HID usage
			0x75, 0x08,       // Report size
			//0x95, 0x3F,       // Report count
         	0x96, 0xFF, 0x03, // Report count - DYNAMIC: This value will be altered to match the report length
			0x92, 0x02, 0x01, // OUTPUT DATA|VARIABLE|ABSOLUTE

			0x85, 0x1E,       // Report ID 2
			0x09, 0x05,       // HID usage
//			0x15, 0x00,       // Logical min
//			0x26, 0xFF, 0x00, // Logical max
			0x75, 0x08,       // Report size
			//0x95, 0x3F,       // Report count
         	0x96, 0xFF, 0x03, // Report count - DYNAMIC: This value will be altered to match the report length
			0x82, 0x02, 0x01, // INPUT DATA|VARIABLE|ABSOLUTE

			0x85, 0x1E,       // Report ID 2
			0x09, 0x03,       // HID usage
			0x75, 0x08,       // Report size
			//0x95, 0x3F,       // Report count
         	0x96, 0xFF, 0x03, // Report count - DYNAMIC: This value will be altered to match the report length
			0x92, 0x02, 0x01, // OUTPUT DATA|VARIABLE|ABSOLUTE

			0xC0,

			0xC0
	}
};

static struct platform_device my_hid = {
	.name			= "hidg",
	.id			= 0,
	.num_resources		= 0,
	.resource		= 0,
	.dev.platform_data	= &diebold_hid_data,
};


struct hidg_func_node {
	struct usb_function_instance *fi;
	struct usb_function *f;
	struct list_head node;
	struct hidg_func_descriptor *func;
};

static LIST_HEAD(hidg_func_list);

/*-------------------------------------------------------------------------*/
USB_GADGET_COMPOSITE_OPTIONS();

static struct usb_device_descriptor tpd_device_desc = {
	.bLength =		sizeof tpd_device_desc,
	.bDescriptorType =	USB_DT_DEVICE,

	.bcdUSB =		cpu_to_le16(0x0200), // Inidica a versão do usb usada USB 2.0 

	/* .bDeviceClass =		USB_CLASS_COMM, */
	/* .bDeviceSubClass =	0, */
	/* .bDeviceProtocol =	0, */
	.bDeviceClass =		0x00,
	.bDeviceSubClass =	0,
	.bDeviceProtocol =	0,
	/* .bMaxPacketSize0 = f(hardware) */

	/* Vendor and product id can be overridden by module parameters.  */
	.idVendor =			cpu_to_le16(TPD_DEFAULT_VENDOR_ID),  
	.idProduct =		cpu_to_le16(TPD_DEFAULT_PRODUC_ID), 
	/* .bcdDevice = f(hardware) */
	/* .iManufacturer = DYNAMIC */
	/* .iProduct = DYNAMIC */
	/* NO SERIAL NUMBER */
	.bNumConfigurations =	1,
};

static const struct usb_descriptor_header *otg_desc[2];

/* string IDs are assigned dynamically */
static struct usb_string tpd_strings_dev[] = {
	[USB_GADGET_MANUFACTURER_IDX].s = "Diebold Nixdorf Inc.", 
	[USB_GADGET_PRODUCT_IDX].s = DRIVER_DESC,
	[USB_GADGET_SERIAL_IDX].s = "X9999999999", 
	{  } /* end of list */
};

static struct usb_gadget_strings stringtab_dev = {
	.language	= 0x0409,	/* en-us */
	.strings	= tpd_strings_dev,
};

static struct usb_gadget_strings *dev_strings[] = {
	&stringtab_dev,
	NULL,
};

module_param(id_Product, int, 0);
MODULE_PARM_DESC(id_Product, "USB Product ID");

module_param(i_Product, charp, 0);
MODULE_PARM_DESC(i_Product, "USB Product string");

module_param(i_SerialNumber, charp, 0);
MODULE_PARM_DESC(i_SerialNumber, "Serial Number string");

/****************************** Configurations ******************************/

static int do_config(struct usb_configuration *c)
{
	struct hidg_func_node *e, *n;
	int status = 0;

	if (gadget_is_otg(c->cdev->gadget)) {
		c->descriptors = otg_desc;
		c->bmAttributes |= USB_CONFIG_ATT_WAKEUP;
	}

	list_for_each_entry(e, &hidg_func_list, node) {
		e->f = usb_get_function(e->fi);
		if (IS_ERR(e->f))
			goto put;
		status = usb_add_function(c, e->f);
		if (status < 0) {
			usb_put_function(e->f);
			goto put;
		}
	}

	return 0;
put:
	list_for_each_entry(n, &hidg_func_list, node) {
		if (n == e)
			break;
		usb_remove_function(c, n->f);
		usb_put_function(n->f);
	}
	return status;
}

static struct usb_configuration config_driver = {
	.label			= "HID Gadget",
	.bConfigurationValue	= 1,
	/* .iConfiguration = DYNAMIC */
	.bmAttributes		= USB_CONFIG_ATT_SELFPOWER,
};

/****************************** Gadget Bind ******************************/

static int hid_bind(struct usb_composite_dev *cdev)
{
	struct usb_gadget *gadget = cdev->gadget;
	struct list_head *tmp;
	struct hidg_func_node *n, *m;
	struct f_hid_opts *hid_opts;
	int status, funcs = 0;
    //int *IDPRO = &cdev->driver->dev->idProduct; //Comentei pq não faz nada

	list_for_each(tmp, &hidg_func_list)
		funcs++;

	if (!funcs)
    {
		return -ENODEV;
    }

	list_for_each_entry(n, &hidg_func_list, node)
    {
		n->fi = usb_get_function_instance("hid");
		if (IS_ERR(n->fi))
      	{
			status = PTR_ERR(n->fi);
         	printk("%s: usb_get_function_instance ERROR status=%d\n", __func__, status ); //Colocado para Debug
			goto put;
		}
		hid_opts = container_of(n->fi, struct f_hid_opts, func_inst);
		hid_opts->subclass = n->func->subclass;
		hid_opts->protocol = n->func->protocol;
		hid_opts->report_length = n->func->report_length;
		hid_opts->report_desc_length = n->func->report_desc_length;
		hid_opts->report_desc = n->func->report_desc;
	}


	/* Allocate string descriptor numbers ... note that string
	 * contents can be overridden by the composite_dev glue.
	 */

	status = usb_string_ids_tab(cdev, tpd_strings_dev);
	if (status < 0)
    {
		printk("%s: usb_string_ids_tab ERROR status=%d\n", __func__, status ); //Colocado para Debug
		goto put;
    }

	tpd_device_desc.iManufacturer = tpd_strings_dev[USB_GADGET_MANUFACTURER_IDX].id;
	tpd_device_desc.iProduct = tpd_strings_dev[USB_GADGET_PRODUCT_IDX].id;
	tpd_device_desc.iSerialNumber = tpd_strings_dev[USB_GADGET_SERIAL_IDX].id;

	if (gadget_is_otg(gadget) && !otg_desc[0])
    {
		struct usb_descriptor_header *usb_desc;
      
		printk("%s: gadget_is_otg && otg_desc[0]=%p\n", __func__, otg_desc[0] ); //Colocado para Debug

		usb_desc = usb_otg_descriptor_alloc(gadget);
		if (!usb_desc)
        {
			printk("%s: usb_otg_descriptor_alloc ERROR status=%d\n", __func__, status ); //Colocado para Debug
			status = -ENOMEM; //Adicionei pq no original existe essa atribuicao
			goto put;
        }
		usb_otg_descriptor_init(gadget, usb_desc);
		otg_desc[0] = usb_desc;
		otg_desc[1] = NULL;
	}

	/* register our configuration */
	status = usb_add_config(cdev, &config_driver, do_config);
	if (status < 0)
    {
		printk("%s: usb_add_config ERROR status=%d\n", __func__, status ); //Colocado para Debug
		goto free_otg_desc;
    }

	usb_composite_overwrite_options(cdev, &coverwrite);
	dev_info(&gadget->dev, DRIVER_DESC ", version: " DRIVER_VERSION "\n");
  
	return 0;

free_otg_desc:
	kfree(otg_desc[0]);
	otg_desc[0] = NULL;
put:
	list_for_each_entry(m, &hidg_func_list, node)
	{
		if (m == n)
			break;
		usb_put_function_instance(m->fi);
	}
   
	printk("%s: END status=%d\n", __func__, status ); //Colocado para debug
	return status;
}

static int hid_unbind(struct usb_composite_dev *cdev)
{
	struct hidg_func_node *n;
   
//   printk("%s: BEGIN\n", __func__ );

	list_for_each_entry(n, &hidg_func_list, node) {
		usb_put_function(n->f);
		usb_put_function_instance(n->fi);
	}

	kfree(otg_desc[0]);
	otg_desc[0] = NULL;
   
//	printk("%s: END\n", __func__ );

	return 0;
}

static int hidg_plat_driver_probe(struct platform_device *pdev)
{
	struct hidg_func_descriptor *func = dev_get_platdata(&pdev->dev);
	struct hidg_func_node *entry;

	if (!func) {
		dev_err(&pdev->dev, "Platform data missing\n");
		return -ENODEV;
	}

	entry = kzalloc(sizeof(*entry), GFP_KERNEL);
	if (!entry)
		return -ENOMEM;

	entry->func = func;
	list_add_tail(&entry->node, &hidg_func_list);

	return 0;
}

static int hidg_plat_driver_remove(struct platform_device *pdev)
{
	struct hidg_func_node *e, *n;

	list_for_each_entry_safe(e, n, &hidg_func_list, node) {
		list_del(&e->node);
		kfree(e);
	}

	return 0;
}


/****************************** Some noise ******************************/


static struct usb_composite_driver hidg_driver = {
	.name		= "g_dbdhiddevice",
	.dev		= &tpd_device_desc,
	.strings	= dev_strings,
	.max_speed	= USB_SPEED_HIGH,
	.bind		= hid_bind,
	.unbind		= hid_unbind,
};

static struct platform_driver hidg_plat_driver = {
	.remove		= hidg_plat_driver_remove,
	.driver		= {
		.name	= "hidg",
	},
};


MODULE_DESCRIPTION(DRIVER_DESC);
MODULE_AUTHOR("Fabien Chouteau, Peter Korsgaard");
MODULE_LICENSE("GPL");

static int __init hidg_init(void)
{
	int status, len;
   
//	printk("%s: BEGIN\n", __func__ );
	// printk("*********************************************************************************\n");
	// printk("Valor de entrada: PID=%d sPID=%s sSN=%s\n", id_Product, i_Product, i_SerialNumber);
	// printk("*********************************************************************************\n");

	if (id_Product == 0)
		tpd_device_desc.idProduct =	cpu_to_le16(TPD_DEFAULT_PRODUC_ID); //Substitui o valor TPD_DEFAULT_PRODUC_ID -> 
	else
		tpd_device_desc.idProduct =	cpu_to_le16(id_Product);

	len = strlen(i_Product);
	if ((len <= 32) && (len > 0))
		tpd_strings_dev[USB_GADGET_PRODUCT_IDX].s = i_Product;


	len = strlen(i_SerialNumber);
	if ((len <= 11) && (len > 0))
		tpd_strings_dev[USB_GADGET_SERIAL_IDX].s = i_SerialNumber;

	//Mostrando se os vlaores foram atualizados
	// printk("Valor de tpd_strings_dev: [USB_GADGET_PRODUCT_IDX].s=%s [USB_GADGET_SERIAL_IDX].s=%s\n", tpd_strings_dev[USB_GADGET_PRODUCT_IDX].s, tpd_strings_dev[USB_GADGET_SERIAL_IDX].s);

	// status = hidg_plat_driver_probe( &my_hid );
	/* HID gad*/

	status = platform_device_register(&my_hid);
	if (status < 0)
		return status;

	status = platform_driver_probe(&hidg_plat_driver,
				hidg_plat_driver_probe);

	if(status < 0)
	{
		printk("%s: hidg_plat_driver_probe error %d\n", __func__, status );
		return status;
	}

	status = usb_composite_probe(&hidg_driver);
	if (status < 0)
	{
		printk("%s: usb_composite_probe error %d\n", __func__, status );
	}

//	printk("%s: END error %d\n", __func__, status );

	return status;
}
module_init(hidg_init);

static void __exit hidg_cleanup(void)
{
	usb_composite_unregister(&hidg_driver);
	// hidg_plat_driver_remove(&hidg_plat_driver);
	platform_driver_unregister(&hidg_plat_driver);
}
module_exit(hidg_cleanup);
