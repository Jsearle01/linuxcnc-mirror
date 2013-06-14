#!/bin/bash

dtbo_err () {
	echo "Error loading device tree overlay file: $DTBO" >&2
	exit 1
}

pin_err () {
	echo "Error exporting pin:$PIN" >&2
	exit 1
}

dir_err () {
	echo "Error setting direction:$DIR on pin:$PIN" >&2
	exit 1
}

SLOTS=/sys/devices/bone_capemgr.*/slots

# Make sure required device tree overlay(s) are loaded
for DTBO in BB-LCNC-BEBOPR cape-bone-iio ; do

	if grep -q $DTBO $SLOTS ; then
		echo $DTBO overlay found
	else
		echo Loading $DTBO overlay
		sudo su -c "echo $DTBO > $SLOTS" || dtbo_err
	fi
done;

if [ ! -r /sys/devices/ocp.*/helper.*/AIN0 ] ; then
	echo Analog input files not found in /sys/devices/ocp.*/helper.* >&2
	exit 1;
fi

if [ ! -r /sys/class/uio/uio0 ] ; then
	echo PRU control files not found in /sys/class/uio/uio0 >&2
	exit 1;
fi

# Export GPIO pins
# This really only needs to be done to enable the low-level clocks for the GPIO
# modules.  There is probably a better way to do this...
while read PIN DIR JUNK ; do
        case "$PIN" in
        ""|\#*)	
		continue ;;
        *)
		[ -r /sys/class/gpio/gpio$PIN ] && continue
                sudo su -c "echo $PIN > /sys/class/gpio/export" || pin_err
		sudo su -c "echo $DIR > /sys/class/gpio/gpio$PIN/direction" || dir_err
                ;;
        esac

done <<- EOF
	38	low	# gpio1.6	P8.3	Enable
	34	high	# gpio1.2	p8.5	Enable_n
	66	high	# gpio2.2	p8.7	Enable_n (ECO location)
	92	out	# gpio2.24	P8.28	Z_Ena
	80	out	# gpio2.16	P8.36	J4.PWM
	77	out	# gpio2.13	P8.40	Y_Ena
	74	out	# gpio2.10	P8.41	X_Ena
EOF