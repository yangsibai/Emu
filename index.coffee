chrome.browserAction.onClicked.addListener (tab)->
    chrome.tabs.sendMessage tab.id, 'start'

chrome.runtime.onMessage.addListener (request, sender, sendResponse)->
    chrome.downloads.download
        url: 'data:text/html;charset=utf-8,' + encodeURIComponent(request.content)
        filename: request.name
    sendResponse()
