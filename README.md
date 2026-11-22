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

- macOS with the News app (News must be available in your region)
- Xcode Command Line Tools, for `swiftc` (`xcode-select --install`)
- Google Chrome or Brave

## Install

```sh
./install.sh
```

This compiles the helper into `~/Library/Application Support/OpenInNews/` and registers it with every installed Chrome and Brave channel (stable, Beta, Dev, Canary, Nightly). A browser channel counts as installed only once it has been launched at least once. If you add a channel later, launch it and run the script again.

Then load the extension:

1. Open `chrome://extensions` or `brave://extensions`.
2. Turn on **Developer mode**.
3. Click **Load unpacked** and choose the `extension/` folder.

The manifest's `key` gives the extension a fixed ID (`kjbmejeekbfdmblfpoflkamecpkhcbeb`). The helper only accepts messages from that ID.

## Use

- Click the toolbar button to open the current page in News.
- Right-click a page and choose **Open in News**, or right-click a link and choose **Open Link in News**.

If the helper can't be reached or reports an error, the toolbar button shows **!**, and its tooltip contains the error.

## Limitations

- News can't tell in advance whether a page exists in Apple News. If it doesn't, News opens on its Today page. Safari behaves the same way.
- Only `http` and `https` URLs are accepted.

## Uninstall

Remove the extension in the browser, then delete the helper and its registrations:

```sh
rm -rf ~/Library/Application\ Support/OpenInNews
rm -f ~/Library/Application\ Support/{Google/Chrome*,BraveSoftware/Brave-Browser*}/NativeMessagingHosts/com.open_in_news.host.json
```

## Development

```sh
swiftc -O host/OpenInNewsHost.swift -o open-in-news-host
test/host.sh ./open-in-news-host
```

`test/host.sh` checks the helper's message framing and input validation without opening News. CI runs it on macOS, and it lints the shell scripts and the extension on Linux.

## License

[MIT](LICENSE)
