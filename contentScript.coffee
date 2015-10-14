$(document).ready ->
    CSSUtilities.define 'async', true
    CSSUtilities.define "mode", "browser"
    CSSUtilities.init ->
        class Emu
            constructor: ->
                @cutting = false
                @currentEl = null
                @currentOutline = ''

            restoreCurrent: ->
                @rules = []
                @parents = []
                if @currentEl
                    if @currentOutline
                        $(@currentEl).css
                            outline: @currentOutline
                    else
                        @currentEl.style.removeProperty 'outline'

            chooseCurrent: (el)->
                @currentEl = el
                $el = $(el)
                @currentOutline = $el.css 'outline'
                if $el.css('outline-style') is 'none'
                    @currentOutline = ''
                $el.css
                    outline: '3px outset #f00'

            listener: (e)->
                if @currentEl isnt e.target
                    @restoreCurrent()
                    @chooseCurrent(e.target)

            handleClick: (e)->
                start = Date.now()
                @restoreCurrent()
                @getRules @currentEl
                @getParent @currentEl
                @open()
                e.preventDefault()
                @stopCut()
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
                    @parents.push
                        nodeName: parentNode.nodeName
                        className: parentNode.className
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
                    node = document.createElement el.nodeName
                    node.className = el.className if el.className
                    parent.appendChild node
                    parent = node

                parent.appendChild @currentEl.cloneNode true
                return htmlNode

            startCut: ->
                $(window).on 'mousemove.emu', @listener.bind(this)
                $(window).on 'click.emu', @handleClick.bind(this)

            stopCut: ->
                @restoreCurrent()
                $(window).off 'mousemove.emu'
                $(window).off 'click.emu'

            toggle: ->
                @cutting = not @cutting
                if @cutting
                    @startCut()
                else
                    @stopCut()

        emu = new Emu()
        chrome.runtime.onMessage.addListener (msg)->
            emu.toggle()
