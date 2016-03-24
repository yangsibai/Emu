chrome.browserAction.onClicked.addListener (tab)->
    chrome.tabs.sendMessage tab.id, 'start'

chrome.runtime.onMessage.addListener (request, sender, sendResponse)->
    ajax.postJSON 'http://emu.sibo.io/page',
        URL: request.URL
        title: request.name
        content: request.content
    , (res)->
        sendResponse(res)
