#!/sbin/sh

### update_engine_sideload bootstrap
# Purpose:
#  - 
#

source /tissot_manager/tools.sh

ui_print
ui_print
ui_print "--------------------------------------------------"
ui_print

# Confirm for payload install to new slot
ui_print "[#] Checking target slot..."
if ! shouldDoPayloadInstall; then
	exit 0
fi

# TWRP survival
if [ -f "/tmp/flash_skip_survival" ]; then
	ui_print
	ui_print "[i] Skipping TWRP survival as per user request"
else
	backupTwrp
fi
ui_print
ui_print "[#] Starting update_engine_sideload..."
if isHotBoot; then
	ui_print "    [#] Warning - fastboot hotboot detected. If you"
	ui_print "        encounter issues, please flash TWRP first."
fi
bootSlot=`getBootSlotLetter`
otherSlot=`getOtherSlotLetter`
ui_print "    [i] Boot slot is $bootSlot, "
ui_print "        installing update to slot $otherSlot"
if isTreble; then
	ui_print "    [i] Device is Treble-compatible"
else
	ui_print "    [!] Device is NOT Treble-compatible. You need"
	ui_print "        to repartition first."
	ui_print "        [#] If you are installing a Treble AIO, it"
	ui_print "            will FAIL with error code 7."
	ui_print "        [#] If you are installing a non-Treble ROM,"
	ui_print "            ignore this warning."
fi
ui_print


# Remember the current recovery.log line count
log_line_start=`wc -l < /tmp/recovery.log`
# Run the update_engine_sideload
/sbin/update_engine_sideload_real "$@"
# extract useful info from log file
current_line=1
log_line_end=`wc -l < /tmp/recovery.log`
while read LINE; do
    if [ "$current_line" -ge "$log_line_start" ]; then
        if echo $LINE | grep -Fqe "target_slot: "; then
			# extract target slot
			echo $LINE | sed -e "s|.*target_slot: ||g" | sed -e "s|, url: .*||g" > /tmp/target_slot
		fi
		
		if echo $LINE | grep -Fqe "Aborting processing due to failure"; then
			# write error marker 
			touch /tmp/update_engine_sideload_error
		fi;
	fi
	if [ "$current_line" -ge "$log_line_end" ]; then
		break
	fi
	
	current_line=$((current_line+1))
done < /tmp/recovery.log

ui_print
ui_print "--------------------------------------------------"
ui_print
if [ -f "/tmp/update_engine_sideload_error" ]; then
	rm /tmp/update_engine_sideload_error
	ui_print "[!] ROM install failed. Please try the following:"
	ui_print "    - Check any text above for obvious errors; or"
	ui_print "    - Save Log in TWRP to share with others for help."
else
	# TWRP survival
	if [ -f "/tmp/flash_skip_survival" ]; then
		rm -f "/tmp/flash_skip_survival"
	else
		restoreTwrp $otherSlot
	fi
	ui_print "[i] ROM install done to Slot `cat /tmp/target_slot`."
	rm /tmp/target_slot
	ui_print
	# do dualboot stuff if needed
	dualBootInstallProcess $otherSlot
	ui_print
	if [ -f "/tmp/twrp_survival_success" ]; then
		rm "/tmp/twrp_survival_success"
		ui_print "[i] TWRP was automatically re-installed to the new slot."
		ui_print
		ui_print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		ui_print
		ui_print "[!] Ensure you Reboot Recovery NOW to switch to the"
		ui_print "    new Slot before flashing anything else!"
		ui_print
		ui_print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		ui_print
	else
		ui_print "[i] Be sure to do the following now:"
		ui_print "    - Flash TWRP immediately;"
		ui_print "    - Reboot Recovery to switch to the new slot;"
		ui_print "    - Install any other ZIPs you desire (e.g. Gapps, Magisk, etc);"
	fi
fi
ui_print
ui_print "--------------------------------------------------"
ui_print
exit $?