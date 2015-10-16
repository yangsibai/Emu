$(document).ready ->
    containCorsCss = ->
        for i of document.styleSheets
            if document.styleSheets.hasOwnProperty(i)
                if document.styleSheets[i].href and (not document.styleSheets[i].cssRules)
                    return true
        return false
    CSSUtilities.define 'async', true
    if containCorsCss()
        CSSUtilities.define "mode", "author"
    else
        CSSUtilities.define "mode", "browser"

    CSSUtilities.init ->
        class Emu
            constructor: ->
                @cutting = false
                @rules = []
                @parents = []
                @selected = []
                @$hoverd = null

                @sender = $ '<div/>'
                    .attr 'class', 'emu-send'
                    .appendTo document.body

            handleMouseMove: (e)->
                if @$hoverd?[0] isnt e.target
                    @$hoverd?.removeClass 'emu-hover'
                    @$hoverd = $(e.target)
                    @$hoverd.addClass 'emu-hover'

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

            getRules: (el)->
                rules = CSSUtilities.getCSSRules el, '*', 'selector,css'
                @rules = @rules.concat(rules)
                for child in el.children
                    @getRules(child)

            generateCss: (rules)->
                ruleDict = {}
                for rule in rules
                    unless rule.css.trim()
                        continue
                    unless rule.selector.trim()
                        continue
                    unless ruleDict[rule.selector]
                        ruleDict[rule.selector] = {}
                    arr = rule.css.split ';'
                    for a in arr
                        a = a.trim()
                        arr2 = a.split ':'
                        if arr2.length is 2
                            ruleDict[rule.selector][arr2[0].trim()] = arr2[1].trim()
                result = []
                for selector,rs of ruleDict
                    str = selector + '{\n'
                    middle = []
                    for k, v of rs
                        middle.push "  " + k + ":" + v
                    str += middle.join ';\n'
                    str += "\n}\n"
                    result.push str
                return result.join '\n'

            getParent: (el)->
                parentNode = el.parentNode
                if parentNode and parentNode.nodeName isnt 'BODY'
                    @parents.push parentNode
                    @getParent parentNode

            open: ()->
                w = window.open ""
                html = @generateHTML()
                w.document.write html.innerHTML

            generateHTML: ->
                htmlNode = document.createElement 'HTML'

                headNode = document.createElement 'HEAD'

                styleNode = document.createElement 'STYLE'
                styleNode.type = 'text/css'
                styleNode.appendChild document.createTextNode @generateCss @rules
                headNode.appendChild styleNode

                htmlNode.appendChild headNode

                bodyNode = document.createElement 'BODY'
                htmlNode.appendChild bodyNode
                parent = bodyNode
                for i in [@parents.length - 1..0] by -1
                    el = @parents[i]
                    node = el.cloneNode false
                    parent.appendChild node
                    parent = node

                parent.appendChild @selected[0].cloneNode true
                return htmlNode

            handleKeyDown: (e)->
                if e.keyCode is 27
                    @toggle()

            handleSendClick: ->
                start = Date.now()
                @getRules @selected[0]
                @getParent @selected[0]
                @open()
                @toggle()
                console.log "total:", Date.now() - start + 'ms'

            startCut: ->
                $(window).on 'mousemove.emu', @handleMouseMove.bind(this)
                $(window).on 'click.emu', @handleClick.bind(this)
                $(window).on 'keydown.emu', @handleKeyDown.bind(this)
                @sender.on 'click.emu', @handleSendClick.bind(this)

            stopCut: ->
                @sender.hide()
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

        emu = new Emu()
        chrome.runtime.onMessage.addListener (msg)->
            emu.toggle()
