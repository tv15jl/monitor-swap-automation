# README

This script automates the process of switching your primary monitor with a dummy monitor using MultiMonitorTool. 
This is useful for users of Sunshine (a screen sharing software) who experience issues with sharing their primary monitor.

## CAVEATS

- If you are using Windows 11, you need to set your default terminal to "Windows Console Host". Windows Terminal is currently bugged and does not respect hiding PowerShell scripts.
- Once installing this script, you cannot move this folder as it will break the automation. If you need to move the folder, simply uninstall and install the script again.

## REQUIREMENTS

### For GFE users

- This script no longer supports GFE, but you are able to retrieve a legacy version of this script that does support it: https://github.com/Nonary/MonitorSwapAutomation/releases/tag/legacy

### For Sunshine users
- Version 0.19.1 or higher
- Host must be Windows
- Sunshine must be installed as a service (it does not work with the zip version of Sunshine)
- Sunshine logging level must be set to Debug
- Users must have read permissions to `%WINDIR%/Temp/Sunshine.log` (do not change other permissions, just make sure Users have at least read permissions)

## INSTRUCTIONS

1. Open up MultiMonitorTool and click on `File -> Save Monitors Configuration` and save it in the current folder this script is located in with the name of `primary.cfg`.
2. Repeat the same steps of step 1, except save it with the name of `dummy.cfg`.
3. Open up the `dummy.cfg` file and set every parameter related to your primary monitor's position, refresh rate, etc. to `0`. For example:

        Name=\\.\DISPLAY1
        MonitorID=MONITOR\GSMC0C8\{4d36e96e-e325-11ce-bfc1-08002be10318}\0009
        SerialNumber=LGTV
        BitsPerPixel=0
        Width=0
        Height=0
        DisplayFlags=0
        DisplayFrequency=0
        DisplayOrientation=0
        PositionX=0
        
        Name=\\.\DISPLAY11
        MonitorID=MONITOR\XMD29831\{4d36e96e-e325-11ce-bfc1-08002be10318}\0007
        SerialNumber=DUMMY
        BitsPerPixel=32
        Width=3840
        Height=2160
        DisplayFlags=0
        DisplayFrequency=120
        DisplayOrientation=0
        PositionX=0

    In the example above, every numerical value has been set to 0, which lets the script know that the display should be turned off.
    Also take note in the example, that my dummy display should have values configured to let it know that it should be turned on.

4. Verify that the `dummy.cfg` file has only **one** display that contains values for the `BitsPerPixel`, `Width`, `Height`, and so on. 
4a. For the `primary.cfg file`, it does not matter if there are other displays enabled, but you would want to make sure your dummy is "zeroed out" so you don't end up with an invisible monitor.
5. Basically, primary will "zero out" the dummy plug, and dummy will "zero out" the main display. This will automatically transfer games and windows back to the primary monitor if setup this way.
6. In the `primary.cfg` file, locate your primary `MonitorId` and copy and paste it to the `primaryMonitorId` key in the settings.json file. Make sure to escape the backslashes.
7. In the `dummy.cfg` file, locate your dummy `MonitorId` and copy and paste it to the `dummyMonitorId` key in the settings.json file. Make sure to escape the backslashes.
8. Validate you have escaped the backslashes, below is an example of a valid settings.json file.
    ```
    {
    "startDelay": 2,
    "gracePeriod": 60,
    "configSaveLocation": "%TEMP%",
    "primaryMonitorId": "MONITOR\\GSMC0C8\\{4d36e96e-e325-11ce-bfc1-08002be10318}\\0009",
    "dummyMonitorId": "MONITOR\\XMD009A\\{4d36e96e-e325-11ce-bfc1-08002be10318}\\0010"
    }
    ```

9. Install the script by double clicking the Install.bat file, you may get a smart-screen warning... this is normal.
10. You will be prompted for administrator rights, as modifying Sunshine configuration will require admin rights in the coming future.
11. Verify that the sunshine.conf file is configured properly, if successful the global_prep_cmd should look like this
    global_prep_cmd = [{"do":"powershell.exe -executionpolicy bypass -file \"F:\\sources\\MonitorSwapAutomation\\MonitorSwap-Dummy.ps1\"","elevated":"false","undo":"powershell.exe -executionpolicy bypass -file \"F:\\sources\\MonitorSwapAutomation\\MonitorSwap-Functions.ps1\" True"}]

The paths referenced above will vary on your machine.
## TROUBLESHOOTING

If you encounter issues with the script, you can try the following:

- Check that your primary monitor `MonitorId` matches the value in the `primaryMonitorId` variable in the `settings.json` file.
- Check that your dummy monitor `MonitorId` matches the value in the `dummyMonitorId` variable in the `settings.json` file.
- Check that you have escaped the backslashes in both the primaryMonitorId and dummyMonitorId in the `settings.json` file.
  Valid: MONITOR\\\\GSMC0C8\\\\{4d36e96e-e325-11ce-bfc1-08002be10318}\\\\0009

  Invalid: MONITOR\GSMC0C8\{4d36e96e-e325-11ce-bfc1-08002be10318}\0009
  
- Check that you have set every parameter related to the primary monitor's resolution in the `dummy.cfg` file to `0`.
- Check that you have set every parameter related to the dummy monitor's resolution in the `primary.cfg` file to `0`.
- Check that you have at least one monitor not "zeroed out" in both the primary.cfg and dummy.cfg files.
- Ensure that you have followed the requirements for Sunshine users as listed above.
- Increase the startDelay in the settings file if you're experiencing the script only works intermitently.
- If you are still experiencing issues, try uninstalling and installing it again.
