#!/bin/bash


# -----------------------------------------------------------------------------
#
#           Name:  macos-dock-reset-and-add-items.sh
#    Description:  To set a defined dock state via Munki.
#                  Helpful when testing dock manipulations.
#          Notes:  Script is designed to run by Munki or as root
#   Prerequisite:  dockutil
#         Author:  Jens Malessa
#        Created:  2021-02-15
#  Last Modified:  2021-02-15
#        Version:
#        Credits:  https://github.com/kcrawford/dockutil
#                  https://www.jamf.com/jamf-nation/discussions/24584/need-help-forcing-script-to-run-commands-under-current-logged-on-user#responseChild148637
#
# -----------------------------------------------------------------------------



# -- Variables ------------------------------------------------------------------

# App paths for the custom dock items
dock_items_app_path=(
/System/Applications/Utilities/Terminal.app
/System/Applications/TextEdit.app
/Applications/Managed\ Software\ Center.app
)

# get logged in user and UID
loggedInUser=$(stat -f%Su /dev/console)
echo loggedInUser: "$loggedInUser"

loggedInUID=$(id -u "$loggedInUser")
echo loggedInUID: "$loggedInUID"



# -- Reset Dock and Launchpad to default ----------------------------------------

# test if a real user is logged in
if [[ "$loggedInUser" != "root" ]] || [[ "$loggedInUID" -ne 0 ]]; then
	echo "$loggedInUser" is real user

	# rest Launchpad to default
	/usr/bin/su -l "$loggedInUser" -c "defaults write com.apple.dock ResetLaunchPad -bool true"
	killall Dock
	echo "Finished Launchpad reset for user $loggedInUser"

	# rest Dock to default
	/usr/bin/su -l "$loggedInUser" -c "defaults delete com.apple.dock"
	killall Dock
	echo "Finished Dock reset for user $loggedInUser"

else
    echo "No user logged in. Can't run as user, so exiting"
	exit 0
fi



# -- Test if Dock is ready for dockutil -----------------------------------------

# is dock.plist created?
# echo $(test ! -e /Users/$loggedInUser/Library/Preferences/com.apple.dock.plist) $?
while [ ! -e /Users/"$loggedInUser"/Library/Preferences/com.apple.dock.plist ]
do
	sleep 1
  echo dock.plist not there
done

# is mod_count key present?
while [ -z "$mod_count" ]
do
	sleep 1
  mod_count=$(/usr/bin/su -l "$loggedInUser" -c "defaults read com.apple.dock mod-count")
done

# is mod_count greater 2?
# 2 means the Dock is ready and more changes can come.
echo Wait to add Dock items - ready when mod_count=2
while [ "$mod_count" -lt 2 ]
do
	sleep 1
	mod_count=$(/usr/bin/su -l "$loggedInUser" -c "defaults read com.apple.dock mod-count")
  echo mod_count="$mod_count"
done



# -- add Dock items with dockutil -----------------------------------------------

for app_path in "${dock_items_app_path[@]}"
do
  # add dock item to users dock
	/usr/local/bin/dockutil -v --add "$app_path" --no-restart /Users/"$loggedInUser"/Library/Preferences/com.apple.dock.plist
done

killall Dock
echo "Dock items added for user $loggedInUser"

exit 0
