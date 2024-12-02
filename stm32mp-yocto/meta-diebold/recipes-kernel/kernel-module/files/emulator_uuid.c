#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/sysfs.h>

extern const char *system_serial;

static struct kobject *my_kobj;

// static u32 HW_OCOTP_TESTER0 = 0xd84b971; // Número hexadecimal 0xd84b971.
// static u32 HW_OCOTP_TESTER1 = 0x67;     // Número hexadecimal 0x67.

static ssize_t HW_OCOTP_TESTER0_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf) {
    // return sprintf(buf, "0x%07X\n", HW_OCOTP_TESTER0);
    return snprintf(buf, 10, "0x%s", system_serial + 2);
}

static ssize_t HW_OCOTP_TESTER1_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf) {
    // return sprintf(buf, "0x%02X\n", HW_OCOTP_TESTER1);
    return snprintf(buf, 5, "0x%s", system_serial + 9);
}

static struct kobj_attribute HW_OCOTP_TESTER0_attribute = __ATTR(HW_OCOTP_TESTER0, 0444, HW_OCOTP_TESTER0_show, NULL);
static struct kobj_attribute HW_OCOTP_TESTER1_attribute = __ATTR(HW_OCOTP_TESTER1, 0444, HW_OCOTP_TESTER1_show, NULL);

static int __init my_driver_init(void) {
    int retval;

    printk(KERN_INFO "Valor de system_serial: %s\n", system_serial);




    my_kobj = kobject_create_and_add("fsl_otp", NULL);
    if (!my_kobj)
        return -ENOMEM;

    retval = sysfs_create_file(my_kobj, &HW_OCOTP_TESTER0_attribute.attr);
    if (retval) {
        kobject_put(my_kobj);
        return retval;
    }

    retval = sysfs_create_file(my_kobj, &HW_OCOTP_TESTER1_attribute.attr);
    if (retval) {
        sysfs_remove_file(my_kobj, &HW_OCOTP_TESTER0_attribute.attr);
        kobject_put(my_kobj);
    }

    return retval;
}

static void __exit my_driver_exit(void) {
    sysfs_remove_file(my_kobj, &HW_OCOTP_TESTER0_attribute.attr);
    sysfs_remove_file(my_kobj, &HW_OCOTP_TESTER1_attribute.attr);
    kobject_put(my_kobj);
}

module_init(my_driver_init);
module_exit(my_driver_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Seu Nome");
