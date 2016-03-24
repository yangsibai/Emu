utils =
    objToString: Object.prototype.toString

    isCSSStyleRule: (rule)->
        @objToString.call rule is '[object CSSStyleRule]'

    isCSSMediaRule: (rule)->
        @objToString.call rule is '[object CSSMediaRule]'

CLASS_NAME_SELECTED = 'emu-selected'
CLASS_NAME_HOVER = 'emu-hover'
CLASS_NAME_HAS_SELECTED = 'emu-has-selected'

class Emu
    constructor: ->
        @cutting = false
        @selected = null
        @$hoverd = null
        @cssMarked = {}
        @hasMarked = {}
        @ready = false
        @isSending = false

        $icon = $ '<img/>'
        .attr 'src', chrome.extension.getURL 'icons/paperfly.png'
        @icon = $icon

        $range = $ '<input type="range" min="1" max="10" value="1" />'
        @range = $range
        $control = $ '<div/>'
        .attr 'class', 'emu-control'
        .append $range

        @sender = $ '<div/>'
        .attr 'class', 'emu-send'
        .append $icon
        .append $control
        .appendTo document.body

        @result = $ '<div/>'
        .attr 'class', 'emu-result'

    shouldIgnore: (el)->
        return @sender[0] is el or @sender.has(el).length isnt 0

    handleMouseMove: (e)->
        e.stopPropagation()
        e.preventDefault()
        if @shouldIgnore(e.target)
            return
        if @$hoverd?[0] isnt e.target
            @$hoverd?.removeClass CLASS_NAME_HOVER
            @$hoverd = $(e.target)
            @$hoverd.addClass CLASS_NAME_HOVER

    handleMouseClick: (e)->
        e.stopPropagation()
        e.preventDefault()
        if @shouldIgnore(e.target)
            return

        @removeSelectedClassname()
        $el = $ e.target
        $el.addClass CLASS_NAME_SELECTED
        @selected and @selected.removeClass CLASS_NAME_SELECTED
        @selected = $el
        depth = @getNodeDepth e.target
        @range.attr('max', depth).val(1)
        @sender.show()
        e.preventDefault()

    handleKeyDown: (e)->
        @stopCut() if e.keyCode is 27

    handleSendClick: (e)->
        if @isSending
            return
        @isSending = true
        @selected = $(".#{CLASS_NAME_SELECTED}")
        @sender.addClass CLASS_NAME_HAS_SELECTED
        @removeSelectedClassname()
        setTimeout =>
            start = Date.now()
            @selected[0].isSelected = true # mark all selected nodes
            @mark @selected[0], true

            html = @generateHTML()
            @download (document.title or location.href or 'document'), html.innerHTML

            console.log "total:", Date.now() - start + 'ms, length:', html.innerHTML.length
            @stopCut()
        , 1
        e.stopPropagation()

    handleRangeChange: (e)->
        depth = e.target.value
        targetElement = @selected[0]
        if depth > 1
            for i in [1..depth - 1]
                targetElement = targetElement.parentNode
        $(".#{CLASS_NAME_SELECTED}").removeClass CLASS_NAME_SELECTED
        $(targetElement).addClass CLASS_NAME_SELECTED

    removeSelectedClassname: ->
        @selected?.removeClass CLASS_NAME_SELECTED

    generateCss: ->
        results = []
        sortedKeys = Object.keys(@cssMarked).sort()
        for k in sortedKeys
            sortedKeys2 = Object.keys(@cssMarked[k]).sort()
            for k2 in sortedKeys2
                results.push @cssMarked[k][k2]
        return results.join '\n'

    getParent: (el, parents)->
        parentNode = el.parentNode
        if parentNode and parentNode.nodeName isnt 'BODY'
            parents.push parentNode
            @getParent parentNode, parents

    generateHTML: ->
        htmlNode = document.createElement 'HTML'

        headNode = document.createElement 'HEAD'

        for node in document.head.childNodes
            if node.tagName in ['META', 'TITLE']
                headNode.appendChild node.cloneNode true

        baseNode = document.createElement 'BASE'
        baseNode.setAttribute 'href', location.href
        headNode.appendChild baseNode

        htmlNode.appendChild headNode
        bodyNode = @shallowClone document.body
        @markMatchedCSS document.body.parentNode
        @markMatchedCSS document.body
        @appendSelected document.body, bodyNode
        styleNode = document.createElement 'STYLE'
        styleNode.type = 'text/css'
        styleNode.appendChild document.createTextNode @generateCss()
        headNode.appendChild styleNode
        htmlNode.appendChild bodyNode
        return htmlNode

    shallowClone: (node)->
        newNode = document.createElement node.tagName
        newNode.className = node.className if node.className
        newNode.id = node.id if node.id
        style = node.getAttribute 'style'
        if style
            newNode.setAttribute 'style', style
        return newNode

    appendSelected: (parent, appendTo)->
        for node in parent.childNodes
            continue unless node.hasSelected
            if node.isSelected
                @markAllMatchedCSS node
                appendTo.appendChild node.cloneNode true
            else
                @markMatchedCSS node
                clonedNode = @shallowClone node
                appendTo.appendChild clonedNode
                @appendSelected node, clonedNode

    mark: (el, selected)->
        el.hasSelected = selected
        if el.parentNode
            @mark el.parentNode, selected

    hasSelected: (node)->
        return node.hasSelected

    handleRangeClick: (e)->
        e.stopPropagation()

    startCut: ->
        @cutting = true
        $(window).on 'mousemove.emu', @handleMouseMove.bind(this)
        $(window).on 'click.emu', @handleMouseClick.bind(this)
        $(window).on 'keydown.emu', @handleKeyDown.bind(this)
        @icon.on 'click.emu', @handleSendClick.bind(this)
        @range.on 'input', @handleRangeChange.bind(this)
        @range.on 'click.emu', @handleRangeClick.bind(this)

    stopCut: ->
        @cutting = false
        @removeSelectedClassname()
        if @selected
            @selected.removeClass CLASS_NAME_SELECTED
            @selected[0].isSelected = false
            @mark @selected[0], false
            @selected = null

        @$hoverd and @$hoverd.removeClass CLASS_NAME_HOVER

        @sender.hide()
        @cssMarked = {}
        @hasMarked = {}
        $(window).off 'mousemove.emu'
        $(window).off 'click.emu'
        $(window).off 'keydown.emu'
        @sender.off 'click.emu'
        @range.off 'click.emu'

    toggle: -> if @cutting then @stopCut() else @startCut()

    markMatchedCSS: (el)->
        return unless el.nodeType is Node.ELEMENT_NODE
        signature = @getNodeSignature el
        if @hasMarked[signature]
            @hasMarked[signature] = @hasMarked[signature] + 1
        for k, sheet of document.styleSheets
            continue if (not document.styleSheets.hasOwnProperty(k)) or (not sheet.cssRules)
            for k2, rule of sheet.cssRules
                continue if (not sheet.cssRules.hasOwnProperty(k2)) or (not rule.cssText) or (@cssMarked[k]?[k2])
                try
                    if el.matches? rule.selectorText
                        unless @cssMarked[k]
                            @cssMarked[k] = {}
                        @cssMarked[k][k2] = rule.cssText
                        @hasMarked[signature] = 1
                catch e
                    console.error e

    getNodeSignature: (node)->
        signature = [
            @getNodeHash node
        ]
        while node.parentNode?.nodeType is Node.ELEMENT_NODE
            signature.unshift @getNodeHash node.parentNode
            node = node.parentNode
        return signature.join '>'

    getNodeDepth: (node)->
        depth = 1
        while node.parentNode?.nodeType is Node.ELEMENT_NODE and node.parentNode isnt document.documentElement
            depth = depth + 1
            node = node.parentNode
        return depth

    getNodeHash: (node)->
        return node.tagName + ':' + node.className + ':' + node.id

    markAllMatchedCSS: (el)->
        @markMatchedCSS el
        for child in el.childNodes
            @markAllMatchedCSS child

    loadCSS: (url, cb)->
        xhr = new XMLHttpRequest()
        xhr.open 'GET', url
        xhr.onload = ->
            xhr.onload = xhr.onerror = null
            if xhr.status < 200 || xhr.status >= 300
                console.log 'failed', url
                cb new Error "load #{url} failed, code: #{xhr.status}"
            else
                styleNode = document.createElement 'STYLE'
                styleNode.appendChild document.createTextNode xhr.responseText
                document.head.appendChild styleNode
                cb null

        xhr.onerror = (err)->
            xhr.onload = xhr.onerror = null
            cb err

        xhr.send()

    init: (cb)->
        return cb null if @ready
        count = 0
        self = this
        for sheet in document.styleSheets
            if sheet.href and (not sheet.cssRules)
                count += 1
                @loadCSS sheet.href, (err)->
                    count -= 1
                    if count is 0
                        self.ready = true
                        cb null
        if count is 0
            self.ready = true
            cb null

    download: (name, content)->
        chrome.runtime.sendMessage
            URL: window.location.href
            name: name
            content: content
        , (res)=>
            @isSending = false
            if res.code is 0
                url = "http://emu.sibo.io/page/#{res.payload}"
                @result.html "Has saved to <a target='_blank' href='#{url}'>#{url}</a>"
                .appendTo document.body
                setTimeout =>
                    @result.fadeOut().remove()
                , 10 * 1000
            else
                alert res.error

emu = new Emu()
emu.init ->

chrome.runtime.onMessage.addListener (msg)->
    emu.toggle()
