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
                @currentEl = null
                @rules = []
                @parents = []
                @selected = []

                @sender = $ '<div/>'
                    .attr 'class', 'emu-send'
                    .appendTo document.body

            restoreCurrent: ->
                @rules = []
                @parents = []
                @$currentEl?.removeClass 'emu-hover'
                @sender.hide()

            chooseCurrent: (el)->
                @currentEl = el
                $el = $(el)
                $el.addClass 'emu-hover'
                @$currentEl = $el

            handleMouseMove: (e)->
                if @currentEl isnt e.target
                    @restoreCurrent()
                    @chooseCurrent(e.target)

            handleClick: (e)->
                index = @selected.indexOf e.target
                if index is -1
                    @selected.push e.target
                    $(e.target).addClass 'emu-selected'
                else
                    $(e.target).removeClass 'emu-selected'
                    @selected.splice index, 1
                e.preventDefault()
                @sender.show()
                return
                start = Date.now()
                @restoreCurrent()
                @getRules @currentEl
                @getParent @currentEl
                @open()
                @toggle()
                console.log "total:", Date.now() - start + 'ms'

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

                parent.appendChild @currentEl.cloneNode true
                return htmlNode

            handleKeyDown: (e)->
                if e.keyCode is 27
                    @toggle()

            handleSendClick: ->
                console.log @selected

            startCut: ->
                $(window).on 'mousemove.emu', @handleMouseMove.bind(this)
                $(window).on 'click.emu', @handleClick.bind(this)
                $(window).on 'keydown.emu', @handleKeyDown.bind(this)
                @sender.on 'click.emu', @handleSendClick.bind(this)

            stopCut: ->
                @restoreCurrent()
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
