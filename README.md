# Lighthouse Windows 10+ WSL Setup
https://git.io/JMXGV

## Quick Start

1. Create a desktop shortcut called "Lighthouse WSL Setup" with the following:
```
powershell.exe iex ((New-Object System.Net.WebClient).DownloadString('https://git.io/JM2dE'))
```
Windows Defender sometimes mistakenly reports PowerShell shortcuts as a "threat".  Its not and you can safely allow this shortcut but if you prefer, you can instead run the following command from within PowerShell
```
iex ((New-Object System.Net.WebClient).DownloadString('https://git.io/JM2dE'))
```

2. If using Windows 10, Right Click on the new Shortcut, select *"Run as Administrator"* for Windows 10. 
3. If using Windows 11, just "Open" (double click) the new Shortcut

- Don't forget to reboot after Step 1 (if required)
- For Step 3 (Import) and later, open shortcut normally, not as Admin
- If you want to keep the download file for a fresh re-import later, just skip the cleanup step
- the default user is: *labber*  password: *labber*

Once you have your WSL image running and can connect to your new VM using the desktop icon, you should install X-Server for Windows. This will be needed during React to allow the VM to communicate with your browser.  You can get X-Server here:

https://sourceforge.net/projects/vcxsrv/
