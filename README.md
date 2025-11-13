I have multiple Macs configured with fixed IP address ethernet networks that connect directly to fixed-IP LAN devices. Several apps on these Macs communicate with those devices.

On the first launch of an app, macOS prompts for Local Network permission. After I allow it, the app can connect to the local network device.

After a reboot, the same app can no longer connect to the devices.

If I open System Settings → Privacy & Security → Local Network and toggle the app’s permission off, then on, the connection immediately works again.

Expected behavior:

Once Local Network permission is granted, the app should be able to reconnect after a reboot without requiring any manual toggling.
  
Additional observations:

I can ping the target device’s IP even when the app’s connection is blocked.
  
Testing Asset:

I’ve included a minimal test app that reproduces the issue, along with a short screen capture demonstrating the behavior, as well as the code signing of the app. This is in the documentation folder.

