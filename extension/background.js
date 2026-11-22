const HOST = "com.open_in_news.host";
const WEB_PAGES = ["http://*/*", "https://*/*"];

async function openInNews(url, tabId) {
  let error;
  try {
    const response = await chrome.runtime.sendNativeMessage(HOST, { url });
    if (!response?.ok) error = response?.error ?? "unknown error";
  } catch (e) {
    error = e.message;
  }
  if (tabId === undefined) return;
  // The tab may have closed meanwhile.
  chrome.action.setBadgeText({ tabId, text: error ? "!" : "" }).catch(() => {});
  chrome.action.setTitle({ tabId, title: error ? `Open in News failed: ${error}` : "Open in News" }).catch(() => {});
}

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({ id: "page", title: "Open in News", contexts: ["page"], documentUrlPatterns: WEB_PAGES });
  chrome.contextMenus.create({ id: "link", title: "Open Link in News", contexts: ["link"], targetUrlPatterns: WEB_PAGES });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  openInNews(info.menuItemId === "link" ? info.linkUrl : info.pageUrl, tab?.id);
});

chrome.action.onClicked.addListener((tab) => {
  if (tab.url && /^https?:/.test(tab.url)) openInNews(tab.url, tab.id);
});
