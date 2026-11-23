# Open in News

<img src="extension/icons/icon128.png" width="64" align="right" alt="">

Safari's share menu on macOS has an **Open in News** action that opens the current article in Apple News. Chrome and Brave don't offer it. This extension adds it as a toolbar button and as right-click menu items for the current page or a link.

## How it works

"Open in News" isn't a Safari feature. It's a standard macOS share extension that ships inside News.app (`com.apple.news.openinnews`). It sends the web URL to Apple's News service, which looks up the matching News article and opens it in News.app.

A browser extension can't call macOS APIs, so this project has two parts:

- **`extension/`** is a Manifest V3 extension for Chrome and Brave. It sends the URL to a local helper using [native messaging](https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging).
- **`host/OpenInNewsHost.swift`** is that helper. It runs News.app's own share extension through `NSSharingService`, the same code path Safari uses.

Simply swapping the URL scheme to `applenews://` doesn't work: News.app opens on its Today page instead of the article.

## Requirements

- macOS 12 or later with the News app (News must be available in your region)
- Google Chrome or Brave

## Install

1. **Install the helper.** Download `OpenInNews-<version>.pkg` from the [latest release](https://github.com/nuzayets/open-news/releases/latest) and open it. The package is signed and notarized by Apple. It installs the helper into `/Library/Application Support/OpenInNews/` and registers it for Google Chrome (every channel), Brave and Chromium.
2. **Install the extension** from the [Chrome Web Store](https://chromewebstore.google.com/detail/open-in-news/kjbmejeekbfdmblfpoflkamecpkhcbeb). It works in both Chrome and Brave. To run it from source instead, open `chrome://extensions` or `brave://extensions`, turn on **Developer mode**, click **Load unpacked**, and choose the `extension/` folder.

If you previously ran `install.sh`, remove its per-user registrations first (see [Uninstall](#uninstall)). Browsers prefer them over the package's system-wide ones.

The extension has a fixed ID (`kjbmejeekbfdmblfpoflkamecpkhcbeb`), both unpacked and from the Web Store. The helper only accepts messages from that ID.

### Build from source instead

With Xcode Command Line Tools installed (`xcode-select --install`), run:

```sh
./install.sh
```

This compiles the helper into `~/Library/Application Support/OpenInNews/` and registers it for your user with every Chrome and Brave channel that has been launched at least once. If you add a channel later, launch it and run the script again.

## Use

- Click the toolbar button to open the current page in News.
- Right-click a page and choose **Open in News**, or right-click a link and choose **Open Link in News**.

If the helper can't be reached or reports an error, the toolbar button shows **!**, and its tooltip contains the error.

## Limitations

- News can't tell in advance whether a page exists in Apple News. If it doesn't, News opens on its Today page. Safari behaves the same way.
- Only `http` and `https` URLs are accepted.

## Uninstall

Remove the extension in the browser, then delete the helper and its registrations.

If you installed the package:

```sh
sudo rm -rf "/Library/Application Support/OpenInNews"
sudo rm -f /Library/Google/Chrome/NativeMessagingHosts/com.open_in_news.host.json \
  "/Library/Application Support/Chromium/NativeMessagingHosts/com.open_in_news.host.json"
sudo pkgutil --forget com.open_in_news.host
```

If you used `install.sh`:

```sh
rm -rf ~/Library/Application\ Support/OpenInNews
rm -f ~/Library/Application\ Support/{Google/Chrome*,BraveSoftware/Brave-Browser*}/NativeMessagingHosts/com.open_in_news.host.json
```

## Development

```sh
scripts/package.sh 1.0.0   # unsigned package and Web Store zip in dist/
test/host.sh "dist/root/Library/Application Support/OpenInNews/open-in-news-host"
```

`test/host.sh` checks the helper's message framing and input validation without opening News. CI runs it on macOS, and it lints the shell scripts and the extension on Linux.

## License

[MIT](LICENSE)
