# MacVSep
### v1.0.0 - Acacia

A sleek, modern macOS client for the Mvsep music separation API.

![Screenshot of MacVSep](https://i.imgur.com/LelULqw.png) 

---

## ✨ Features

*   **Always Up-to-Date Models:** The model list comes straight from Mvsep, so new models show up without an app update. Search them, browse them by category and pin your favorites.
*   **Premium Support:** See your credits, turn Premium usage on or off, and get an estimate of how many credits a separation will use. Premium-only models and formats are marked with a lock.
*   **All Output Formats:** mp3, wav (16 and 32 bit), flac (16 and 24 bit) and m4a.
*   **Live Status:** Upload progress, your position in the queue with an estimated wait, and progress on long files that Mvsep splits into parts.
*   **Real Cancel:** Cancelling stops the job on the server too, and refunds your credits if it hasn't started yet.
*   **Organized Downloads:** Download every stem in one click, and optionally save each separation in its own folder.
*   **Remembers Your Settings:** Your output folder, and the options and format you last used with each model.
*   **Official Server-Side History:** View all your jobs from the Mvsep server and re-download their files.
*   **Automatic Updates:** MacVSep can check for, download and install new versions by itself.
*   **Full Appearance Customization:** Pick one of 13 background gradients and any accent color, and force Light/Dark mode.

Please note that you will need an API Key that you can retrieve by following the instructions in the settings, and can only be obtained by creating an account on the website! Your key is stored in your Mac's Keychain.

## 🚀 Download

1.  Go to the [**Releases Page**](https://github.com/septcoco/macvsep/releases).
2.  Under the latest release, download the `MacVSep.app.zip` file.
3.  Unzip the file, and you will have `MacVSep.app`. Drag it to your Applications folder.
4.  The app isn't notarized by Apple, so macOS will block it the first time. Open **System Settings → Privacy & Security**, scroll down and click **Open Anyway**. You only need to do this once: later versions install themselves through the built-in updater.

## 🗺️ Roadmap

Here are some of the features and improvements planned for future versions:

#### Core Functionality
*   [x] **Persistent Output Location:** Remember the last used output folder between app launches.
*   [x] **Favorite Models:** Allow users to mark models as favorites to pin them to the top of the list.
*   [x] **Local History:** Keep a history of past separation jobs, which automatically clears after 72 hours (to match Mvsep's server retention).
*   [x] **Official API History:** Upgrade the History feature to use the official `GET /api/app/separation_history` endpoint. This will provide authoritative server-side history, including `job_exists`, `credits_used`, and `time_left` information.
*   [ ] **Batch Processing:** Allow users to queue up multiple files for separation. Free accounts run one job at a time, Premium accounts can run several in parallel.
*   [x] **Cancel Button**
*   [x] **Live Model List:** Load the models from the Mvsep API instead of shipping a fixed list.
*   [x] **Premium Support:** Credits, Premium toggle, premium formats and cost estimates.
*   [x] **Automatic Updates**
*   [x] **Organized Downloads:** One-click "Download All" and an optional folder per separation ([#2](https://github.com/septcoco/macvsep/issues/2)).
*   [x] **Per-Model Settings:** Remember the options and format used with each model ([#2](https://github.com/septcoco/macvsep/issues/2)).
*   [ ] **Separate From a Link:** Send a direct, MEGA, Google Drive or Dropbox link instead of uploading a file.
*   [ ] **Presets:** Run your saved Mvsep presets.

#### UI & User Experience
*   [x] **Improved File Input:** Allow users to also click the drop zone to open a file selection dialog.
*   [x] **Model Search:** Search the model list and browse it by category.
*   [ ] **Model Leaderboard/Usage Stats:** Display a list of popular or most-used models (potentially based on community data or user's own usage).
*   [x] **Enhanced UI/UX:** General improvements to the visual design and user flow.
*   [x] **Background Customization:** Add options in Settings to change the app's background gradient.

#### Community & Project
*   [ ] **Community:**
    *   [ ] Create a Discord server for community discussion and support.
*   [x] **Move to Beta:** Once the core features are stable and polished.
*   [x] **Official `v1.0.0` Release!**

## 🤔 Considered Features

This is a list of features that have been requested but will not be implemented, along with the reasoning.

*   **Real-time percentage progress:** The Mvsep API doesn't report a percentage while a model is running. MacVSep shows everything the API does give: upload progress, your place in the queue with an estimated wait, and how many parts of a long file are done.

## 🐞 Feedback & Bugs

If you find any bugs or have suggestions, please [open an issue](https://github.com/septcoco/macvsep/issues) on GitHub!

## 🌱 Version Names

Every version of MacVSep is named after a plant. MacVSep splits songs into stems, after all.

## 📄 License

This project is licensed under the MIT License.
