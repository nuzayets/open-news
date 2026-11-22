# Releasing

Pushing a tag of the form `v` followed by one to four dot-separated numbers, such as `v1.0.0`, runs `.github/workflows/release.yml`. It builds a universal (Apple Silicon and Intel) helper, signs it, packages it into a signed `.pkg`, notarizes and staples the package, and publishes a GitHub release with:

- `OpenInNews-<version>.pkg`: the helper and its browser registrations
- `open-in-news-extension-<version>.zip`: the extension for the Chrome Web Store, without the manifest's `key` field, which the Store rejects

```sh
git tag v1.0.0 && git push origin v1.0.0
```

## Repository secrets

| Secret | Contents |
|---|---|
| `MACOS_CERTIFICATES_P12` | Base64 of one `.p12` containing both the **Developer ID Application** and **Developer ID Installer** certificates with their private keys |
| `MACOS_CERTIFICATES_PASSWORD` | Password of that `.p12` |
| `NOTARY_API_KEY` | Contents of an App Store Connect API key (`AuthKey_XXXX.p8`) with the Developer role |
| `NOTARY_API_KEY_ID` | That key's ID |
| `NOTARY_API_ISSUER_ID` | The issuer ID shown above the key list in App Store Connect |

To create them:

1. In [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list), create a **Developer ID Installer** certificate if you don't have one, and install it in your keychain.
2. In Keychain Access, select both Developer ID certificates under **My Certificates**, then choose **File > Export Items…** and save them as one `.p12` with a password.
3. In [App Store Connect > Users and Access > Integrations](https://appstoreconnect.apple.com/access/integrations/api), create a team key with the Developer role and download the `.p8`.
4. Store the secrets:

   ```sh
   base64 -i certificates.p12 | gh secret set MACOS_CERTIFICATES_P12
   gh secret set MACOS_CERTIFICATES_PASSWORD
   gh secret set NOTARY_API_KEY < AuthKey_XXXX.p8
   gh secret set NOTARY_API_KEY_ID
   gh secret set NOTARY_API_ISSUER_ID
   ```

## Chrome Web Store

The extension ID `kjbmejeekbfdmblfpoflkamecpkhcbeb` comes from the public key in `extension/manifest.json`. The matching private key is kept outside the repository. The packaged helper only accepts messages from this ID, so the Store listing must keep it.

**First upload:** add the private key to the release zip as `key.pem`. The Store derives the extension ID from it. The key must be unencrypted PKCS#8 (`BEGIN PRIVATE KEY`); the Store rejects PKCS#1 (`BEGIN RSA PRIVATE KEY`), which `openssl pkcs8 -topk8 -nocrypt` converts:

```sh
cp open-in-news-extension-1.0.0.zip first-upload.zip
cp /path/to/extension-key.pem key.pem && zip first-upload.zip key.pem && rm key.pem
```

Upload `first-upload.zip` in the [developer dashboard](https://chrome.google.com/webstore/devconsole) and confirm that the item ID matches. Then delete `first-upload.zip`, because it contains the private key. Later updates upload the release zip as it is.

Permission justifications for the listing:

- `nativeMessaging`: sends the selected URL to the locally installed helper, which hands it to the Apple News app.
- `activeTab`: reads the current tab's URL when the toolbar button is clicked.
- `contextMenus`: adds "Open in News" and "Open Link in News" to the right-click menu.

The extension collects no data. URLs go only to the local helper and from there to Apple News, which looks them up with Apple's service.
