# MacVSep
### v0.5.4 - First Beta

A sleek, modern macOS client for the Mvsep music separation API.

![Screenshot of MacVSep](https://i.imgur.com/LelULqw.png) 

---

## ✨ Features

*   **Modern UI:** A clean, translucent interface built with the latest SwiftUI standards for macOS.
*   **Flexible File Input:** Drag & Drop your audio file OR simply click the drop zone to select a file.
*   **Favorite Models:** Pin your most-used models to the top of the list for quick access!
*   **Full Model Support:** Access to all of MVSep's separation models, including those with additional specific options.
*   **Real-time Progress:** Watch the status of your separation update from "Uploading" to "Waiting" (meaning you are in queue) to "Processing" to "Done".
*   **Interactive Local History:** A persistent, locally stored history of all your separation jobs. Re-download completed jobs directly from the history panel.
*   **Direct Downloads:** Download your separated files directly to a folder of your choosing.
*   **Persistent Output Location:** Remembers the last used output folder between app launches.

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
*   [x] **History:** Keep a history of past separation jobs, which automatically clears after 72 hours (to match Mvsep's server retention).
*   [ ] **Batch Processing:** Allow users to queue up multiple files for separation. (Requires a "Premium Account" setting to handle job limits).
*   [ ] **UI for Text-Based Models:** Implement a text input field for models like `Stable Audio Open Gen`.

#### UI & User Experience
*   [x] **Improved File Input:** Allow users to also click the drop zone to open a file selection dialog.
*   [ ] **Background Customization:** Add options in Settings to change the app's background gradient.

#### Community & Project
*   [ ] **Community:**
    *   [ ] Create a Discord server for community discussion and support.
*   [x] **Move to Beta:** Once the core features are stable and polished.
*   [ ] **Official `v1.0.0` Release!**

## 🤔 Considered Features

This is a list of features that have been requested but will not be implemented, along with the reasoning.

*   **Real-time percentage progress:** The Mvsep API only reports the status as `waiting`, `processing`, or `done`. It does not provide a percentage value, making this feature impossible for us to implement, unless ZFTurbo implements it, which is highly unlikely.
*   **Cancel Button:** Add the ability to cancel the status-checking process for a job. -> not possible unless proven wrong.

## 🐞 Feedback & Bugs

This is an early alpha release. If you find any bugs or have suggestions, please [open an issue](https://github.com/septcoco/macvsep/issues) on GitHub!

## 📄 License

This project is licensed under the MIT License.
