[![Download ZIP](https://img.shields.io/github/v/release/FAKE1too/DeepFaceLab-Launcher?label=Download%20Launcher)](https://github.com/FAKE1too/DeepFaceLab-Launcher/releases/latest)
# DeepFaceLab-Launcher
 professional locked-shell launcher and cleanup utility for DeepFaceLab
AUTHOR      : @FAKE1too
CREATED     : 2024
LICENSE     : MIT
PURPOSE     : System-integrated DeepFaceLab launcher with cleanup/reset
----------------------------------------------------------------------------
🔧 TECHNICAL OVERVIEW:
- Auto-elevated shell to run DeepFaceLab cleanly
- Isolated Python, CUDA, TEMP, and workspace environment
- Kills leftover GPU/CPU processes on exit
- Unlocks locked _e\t folders from internal shell use
- Offers full interactive cleanup wizard:
  - workspace logs / temp
  - system caches / update leftovers
  - pagefile reset (optional)
  - system restore point (optional)
- Logs cleanup summary to Desktop
- Forces reboot after session for a clean restart
