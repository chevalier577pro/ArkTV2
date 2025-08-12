# ArkTV - IPTV for ArkOS
![](https://github.com/AeolusUX/ArkTV/blob/main/ArkTV.png)

ArkTV is a lightweight, terminal-based IPTV player for Linux devices, built with bash and powered by [mpv](https://mpv.io/). It offers an intuitive menu for browsing and streaming internet TV channels, with joystick support for retro handhelds and embedded devices.

## Features
- Channel selection via `dialog` menu
- Fullscreen streaming with `mpv`
- Joystick/gamepad support via `gptokeyb`
- Auto-installs dependencies (`mpv`, `dialog`, `jq`, `curl`)
- Fetches channel lists from a JSON file hosted on GitHub

## Installation
1. Download or copy the `ArkTV.sh` script.
2. Place it in your device's **tools** or **ports** folder.
3. Run the script to install dependencies and start ArkTV.

## Modifying the Channel List
ArkTV uses a JSON file hosted on GitHub to define channels. To customize it:

1. **Fork the Repository**:
   - Visit the [ArkTV GitHub repository](https://github.com/AeolusUX/ArkTV).
   - Click "Fork" to create your own copy.
   - Clone your forked repository or edit directly on GitHub.

2. **Edit the JSON File**:
   - Locate `channels.json` in your forked repository.
   - Open in a text editor (e.g., VS Code) or GitHub’s online editor.
   - **Add a Channel**:
     ```json
     [
         ...,
         {"name": "New Channel", "url": "https://example.com/stream.m3u8"}
     ]
     ```
   - **Remove a Channel**: Delete the object (e.g., `{"name": "A2Z SD", "url": "..."}`) and adjust commas.
   - **Update a Channel**: Modify `name` or `url` (e.g., `{"name": "HBO HD", "url": "new-url"}`).


3. **Update ArkTV Configuration**:
   - Open `ArkTV.sh` in your forked repository.
   - Edit **line 18** to point to your JSON file URL (e.g., `https://raw.githubusercontent.com/YourUsername/ArkTV/main/channels.json`).

4. **Validate and Save**:
   - Validate JSON using [JSONLint](https://jsonlint.com/).
   - Ensure no trailing commas or missing brackets.
   - Commit and push changes to your forked repository.

5. **Test**:
   - Run ArkTV to verify the updated channel list.
   - Backup the original JSON file before editing.

**Note**: Ensure URLs are valid to avoid streaming issues. Use a JSON editor or script for bulk changes.

## License
ArkTV is licensed under the MIT License.  
This project uses [mpv](https://mpv.io/), licensed under GPLv2 or later (or LGPLv2.1 or later if built with `-Dgpl=false`). See [mpv's license details](https://mpv.io/) for more information.
