{
	services = {
		open-vm-tools = {
			enable = true;
			enableX11 = true;       # If you're using a graphical environment
			enableWayland = true;   # If applicable
			enableSound = true;     # To support audio
			enableMount = true;     # To enable shared folder mounts
		};
	};
}