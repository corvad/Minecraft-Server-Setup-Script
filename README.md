# Minecraft Setup and Managing Script Suite

Check the Releases tab for the latest release to download.
https://github.com/corvad/Minecraft-Server-Setup-Script/releases/

Make sure you have installed Java 17 and curl.

Right now this script only supports Oracle Linux beacuse of how it configures the firewall. I plan to add more broad support in a later version.

Run:
./install.sh

That's it. The install will guide you the rest of the way.

Then to manage run the manage_server file in your main minecraft server directory (where the server.jar is) like so:
./manage_server

Makeself Command:
makeself --notemp . install.sh "Next Generation Minecraft Installer" ./install_server

Change Backup Retention Days:
Edit both the backup_server and backup_s_server located in the scripts directory by changing the days="" variable. The default is 14 days. In a future version the will be revised to work with the manage_server script and the install script.
