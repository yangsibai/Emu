illegalRe = /[\/\?<>\\:\*\|":]/g
controlRe = /[\x00-\x1f\x80-\x9f]/g
reservedRe = /^\.+$/
windowsReservedRe = /^(con|prn|aux|nul|com[0-9]|lpt[0-9])(\..*)?$/i

truncate = (str, maxByteSize)->
    buffer = new Buffer(maxByteSize)
    written = buffer.write(str, "utf8")
    return buffer.toString("utf8", 0, written)

sanitizeFileName = (fileName)->
    replacement = '_'
    sanitized = fileName
        .replace illegalRe, replacement
        .replace controlRe, replacement
        .replace reservedRe, replacement
        .replace windowsReservedRe, replacement
    sanitized.substr 0, 255

chrome.browserAction.onClicked.addListener (tab)->
    chrome.tabs.sendMessage tab.id, 'start'

chrome.runtime.onMessage.addListener (request, sender, sendResponse)->
    chrome.downloads.download
        url: 'data:text/html;charset=utf-8,' + encodeURIComponent(request.content)
        filename: 'pages/' + sanitizeFileName(request.name)
    sendResponse()
