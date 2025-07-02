# MacVSep
### v0.8.1 - Dongba Beta

A sleek, modern macOS client for the Mvsep music separation API.

![Screenshot of MacVSep](https://i.imgur.com/LelULqw.png) 

---

## ✨ Features

*   **Full Appearance Customization:** Make the app your own! Change the background, pick a new accent color, and force Light/Dark mode.
*   **Live Download Progress:** See real-time progress bars for all your downloads. Never guess if a file is downloading again!
*   **User Feedback & Control:** Get pop-up alerts for download completion/failure and cancel a separation while it's processing.
*   **Official Server-Side History:** View a complete history of all your jobs from the Mvsep server and re-download files.
*   **Favorite Models:** Pin your most-used models to the top of the list for quick access.
*   **Full Model Support:** Access to all of Mvsep's separation models.
*   **Persistent Settings:** Remembers your API key, output folder, and favorite models.
Please note that you will need an API Key that you can retrieve by following the instructions in the settings, and can only be obtained by creating an account on the website!

## 🚀 Download the Alpha

The easiest way to use MacVSep is to download the latest pre-compiled version.

1.  Go to the [**Releases Page**](https://github.com/septcoco/macvsep/releases).
2.  Under the latest release, download the `MacVSep.app.zip` file.
3.  Unzip the file, and you will have `MacVSep.app`. Drag it to your Applications folder.

## 🗺️ Roadmap

Here are some of the features and improvements planned for future versions:

#### Core Functionality
*   [x] **Persistent Output Location:** Remember the last used output folder between app launches.
*   [x] **Favorite Models:** Allow users to mark models as favorites to pin them to the top of the list.
*   [x] **Local History:** Keep a history of past separation jobs, which automatically clears after 72 hours (to match Mvsep's server retention).
*   [x] **Official API History:** Upgrade the History feature to use the official `GET /api/app/separation_history` endpoint. This will provide authoritative server-side history, including `job_exists`, `credits_used`, and `time_left` information.
*   [ ] **Batch Processing:** Allow users to queue up multiple files for separation. (Requires a "Premium Account" setting to handle job limits).
*   [ ] **Expanded Output Formats (via FFmpeg)**
*   [x] **Cancel Button**

#### UI & User Experience
*   [x] **Improved File Input:** Allow users to also click the drop zone to open a file selection dialog.
*   [ ] **Model Leaderboard/Usage Stats:** Display a list of popular or most-used models (potentially based on community data or user's own usage).
*   [ ] **Enhanced UI/UX:** General improvements to the visual design and user flow.
*   [x] **Background Customization:** Add options in Settings to change the app's background gradient.

#### Community & Project
*   [ ] **Community:**
    *   [ ] Create a Discord server for community discussion and support.
*   [x] **Move to Beta:** Once the core features are stable and polished.
*   [ ] **Official `v1.0.0` Release!**

## 🤔 Considered Features

This is a list of features that have been requested but will not be implemented, along with the reasoning.

*   **Real-time percentage progress:** The Mvsep API only reports the status as `waiting`, `processing`, or `done`. It does not provide a percentage value, making this feature impossible for us to implement, unless ZFTurbo implements it, which is highly unlikely.

## 🐞 Feedback & Bugs

This is an early alpha release. If you find any bugs or have suggestions, please [open an issue](https://github.com/septcoco/macvsep/issues) on GitHub!

## 📄 License

This project is licensed under the MIT License.
