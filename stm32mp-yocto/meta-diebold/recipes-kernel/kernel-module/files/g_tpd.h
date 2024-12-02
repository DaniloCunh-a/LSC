#ifndef __G_TPD_H__
#define __G_TPD_H__

#define	GADGET_IOCTL_BASE    'g'

#define	GIIOC_CONNECT			_IO (GADGET_IOCTL_BASE, 0x31)
#define	GIIOC_DISCONNECT		_IO (GADGET_IOCTL_BASE, 0x32)
#define	GIIOC_SETSN				_IOW(GADGET_IOCTL_BASE, 0x33, unsigned long)
#define	GIIOC_SETPN				_IOW(GADGET_IOCTL_BASE, 0x34, unsigned long)
#define	GIIOC_SETID				_IOW(GADGET_IOCTL_BASE, 0x35, unsigned long)
#define	GIIOC_GETSTATUS			_IOR(GADGET_IOCTL_BASE, 0x36, unsigned long)
#define	GIIOC_GETENDPOINTLEN	_IOR(GADGET_IOCTL_BASE, 0x37, unsigned long)

#endif
