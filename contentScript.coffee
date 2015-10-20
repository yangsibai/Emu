$(document).ready ->
    class Emu
        constructor: ->
            @cutting = false
            @selected = []
            @$hoverd = null
            @cssMarked = {}
            @hasMarked = {}

            $icon = $ '<img/>'
                .attr 'src', chrome.extension.getURL 'icons/paperfly.png'

            @sender = $ '<div/>'
                .attr 'class', 'emu-send'
                .append $icon
                .appendTo document.body

        handleMouseMove: (e)->
            if @$hoverd?[0] isnt e.target
                @$hoverd?.removeClass 'emu-hover'
                @$hoverd = $(e.target)
                @$hoverd.addClass 'emu-hover'

        handleKeyDown: (e)->
            if e.keyCode is 27
                @toggle()

        handleSendClick: ->
            for $el in @selected
                $el.removeClass 'emu-selected'

            start = Date.now()
            @markSelected() # mark all selected nodes

            w = window.open ""
            html = @generateHTML()
            w.document.write html.innerHTML

            console.log "total:", Date.now() - start + 'ms, length:', html.innerHTML.length
            @toggle()

        removeSelected: (index)->
            @selected[index].removeClass 'emu-selected'
            @selected.splice index, 1

        addSelected: ($el)->
            $el.addClass 'emu-selected'
            @selected.push $el

        handleClick: (e)->
            index = -1
            for $e, i in @selected
                if $e[0] is e.target
                    index = i
            if index is -1 # should push this element
                $el = $ e.target
                founded = false
                for $e,i in @selected
                    if $.contains($e[0], $el[0]) or $.contains($el[0], $e[0])
                        @removeSelected i
                        @addSelected $el
                        founded = true
                        break
                unless founded
                    @addSelected $el
            else
                @removeSelected index

            if @selected.length > 0
                @sender.show()
            else
                @sender.hide()
            e.preventDefault()

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

            titleNode = document.createElement 'TITLE'
            titleNode.appendChild document.createTextNode document.title
            headNode.appendChild titleNode

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

        markSelected: ()->
            for $el in @selected
                $el[0].isSelected = true
                @mark $el[0], true

        mark: (el, selected)->
            el.hasSelected = selected
            if el.parentNode
                @mark el.parentNode, selected

        unMarkSelected: ->
            for $el in @selected
                $el[0].isSelected = false
                @mark $el[0], false

        hasSelected: (node)->
            return node.hasSelected

        startCut: ->
            $(window).on 'mousemove.emu', @handleMouseMove.bind(this)
            $(window).on 'click.emu', @handleClick.bind(this)
            $(window).on 'keydown.emu', @handleKeyDown.bind(this)
            @sender.on 'click.emu', @handleSendClick.bind(this)

        stopCut: ->
            @unMarkSelected()
            @selected = []
            @sender.hide()
            @cssMarked = {}
            @hasMarked = {}
            $(window).off 'mousemove.emu'
            $(window).off 'click.emu'
            $(window).off 'keydown.emu'
            @sender.off 'click.emu'

        toggle: ->
            @cutting = not @cutting
            if @cutting
                @startCut()
            else
                @stopCut()

        markMatchedCSS: (el)->
            return unless el.nodeType is Node.ELEMENT_NODE
            signature = @getNodeSignature el
            if @hasMarked[signature]
                @hasMarked[signature] = @hasMarked[signature] + 1
            for k, sheet of document.styleSheets
                continue if (not document.styleSheets.hasOwnProperty(k)) or (not sheet.cssRules)
                for k2, rule of sheet.cssRules
                    continue if (not sheet.cssRules.hasOwnProperty(k2)) or (not rule.cssText) or (@cssMarked[k]?[k2])
                    if el.matches? rule.selectorText
                        unless @cssMarked[k]
                            @cssMarked[k] = {}
                        @cssMarked[k][k2] = rule.cssText
                        @hasMarked[signature] = 1

        getNodeSignature: (node)->
            signature = [
                @getNodeHash node
            ]
            while node.parentNode?.nodeType is Node.ELEMENT_NODE
                signature.unshift @getNodeHash node.parentNode
                node = node.parentNode
            return signature.join '>'

        getNodeHash: (node)->
            return node.tagName + ':' + node.className + ':' + node.id

        markAllMatchedCSS: (el)->
            @markMatchedCSS el
            for child in el.childNodes
                @markAllMatchedCSS child

    emu = new Emu()
    chrome.runtime.onMessage.addListener (msg)->
        emu.toggle()
