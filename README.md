# MacVSep
### v0.2.0 - Persistence Alpha

A sleek, modern macOS client for the Mvsep music separation API.

![Screenshot of MacVSep](https://i.imgur.com/7ioH5Ya.jpeg) 

---

## ✨ Features

*   **Modern UI:** A clean, translucent interface built with the latest SwiftUI standards for macOS.
*   **Drag & Drop:** Easily drop your audio files (`mp3`, `wav`, `flac`, `m4a`) into the app.
*   **Full Model Support:** Access to all of Mvsep's separation models, including those with additional specific options.
*   **Real-time Progress:** Watch the status of your separation update from "Uploading" to "Waiting" (meaning you are in queue) to "Processing" to "Done".
*   **Direct Downloads:** Download your separated files directly to a folder of your choosing.

Please note that you will need an API Key that you can retrieve by following the instructions in the settings, and can only be obtained by creating an account on the website!

## 🚀 Download the Alpha

The easiest way to use MacVSep is to download the latest pre-compiled version.

1.  Go to the [**Releases Page**](https://github.com/septcoco/macvsep/releases).
2.  Under the latest release, `v0.1.0 - Crystalline Alpha`, download the `MacVSep.app.zip` file.
3.  Unzip the file, and you will have `MacVSep.app`. Drag it to your Applications folder.

## 🗺️ Roadmap

Here are some of the features and improvements planned for future versions:

*   [ ] **UI for Text-Based Models:** Implement a text input field for models like `Stable Audio Open Gen` that require a text prompt.
*   [ ] **Improved User Feedback:**
    *   [ ] Display errors and alerts in a more user-friendly pop-up window.
*   [ ] **Cancel Button:** Add the ability to cancel the status-checking process for a job.
*   [x] **Persistent Output Location:** Remember the last used output folder between app launches.
*   [ ] **Batch Processing:** Allow users to queue up multiple files for separation. (requires Mvsep Premium)
*   [ ] **Community:**
   *   [ ] Create a Discord server for community discussion and support.
*   [ ] **Move to Beta:** Once the core features are stable and polished.
*   [ ] **Official `v1.0.0` Release!**

## 🤔 Considered Features

This is a list of features that have been requested but will not be implemented, along with the reasoning.

*   **Real-time percentage progress:** The Mvsep API only reports the status as `waiting`, `processing`, or `done`. It does not provide a percentage value, making this feature impossible for us to implement, unless ZFTurbo implements it, which is highly unlikely.

## 🐞 Feedback & Bugs

This is an early alpha release. If you find any bugs or have suggestions, please [open an issue](https://github.com/septcoco/macvsep/issues) on GitHub!

## 📄 License

This project is licensed under the MIT License.
