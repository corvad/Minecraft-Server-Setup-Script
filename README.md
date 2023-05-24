# Minecraft Setup and Managing Script Suite

A scripts suite that makes it easy to get a Minecraft server up within minutes. And manage without headaches, including backups.

Supported OS:
- Ubuntu Server
- Oracle Linux

Check the Releases tab for the latest release to download specific to the OS you are running.
https://github.com/corvad/Minecraft-Server-Setup-Script/releases/

## Make sure you have installed Java 17, curl, and tmux. These are requirements, and as such are not optional. If on Ubuntu ufw must also be installed.

Right now this script only supports Oracle Linux beacuse of how it configures the firewall. I plan to add more broad support in a later version.

## Run:
## ./install_ubuntu.sh or ./install_oracle.sh

That's it. The install will guide you the rest of the way.

Then to manage run the manage_server file in your main minecraft server directory (where the server.jar is) like so:
./manage_server

# Makeself Command:
## Ubuntu Server: makeself --notemp . install_ubuntu.sh "Next Generation Minecraft Installer (Ubuntu Server)" ./install_server
## Oracle Linux: makeself --notemp . install_oracle.sh "Next Generation Minecraft Installer (Oracle Linux)" ./install_server

To build for the different versions the build command changes but also the command in both the manage_server and first_time scripts must be updated accordingly between ubuntu_port_config and oracle_port_config. I have provided both versions on the releases page.

Change Backup Retention Days:
Edit both the backup_server and backup_s_server located in the scripts directory by changing the days="" variable. The default is 14 days. In a future version the will be revised to work with the manage_server script and the install script.


DISCLAIMER: I do not own or even pretend to misuse the Minecraft or other related trademarks. Those are the trademarks of Microsoft and Mojang and with this I will not interfere.
