chrome.browserAction.onClicked.addListener (tab)->
    console.log 'start'
    chrome.tabs.sendMessage tab.id, 'start'