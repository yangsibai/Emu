$(document).ready ->
    CSSUtilities.define 'async', true
    CSSUtilities.define "mode", "browser"
    CSSUtilities.init ->
        class Emu
            constructor: ->
                @cutting = false
                @currentEl = null
                @defaultStyle =
                    width: 1
                    height: 1
                    left: 0
                    top: 0
                    background: '#f00'
                    position: 'absolute'
                    opacity: 0.1
                    'z-index': 999999
                    'pointer-events': 'none'
                mask = $ '<div/>'
                mask.css @defaultStyle

                @mask = mask
                $(document.body).append(@mask)

            restoreCurrent: ->
                @currentEl = null
                @mask.css @defaultStyle

            chooseCurrent: (el)->
                @currentEl = el
                $el = $(el)
                offset = $el.offset()
                width = $el.width()
                height = $el.height()
                @mask.css
                    top: offset.top
                    left: offset.left
                    width: width
                    height: height

            listener: (e)->
                if @currentEl isnt e.target
                    @restoreCurrent()
                    @chooseCurrent(e.target)

            handleClick: (e)->
                start = Date.now()
#                rules = CSSUtilities.getCSSRules @currentEl, "*", "selector,css"
                @rules = []
                @getRules @currentEl
                @printRules @rules
                console.log "total:", Date.now() - start + 'ms'

                @parents = []
                @getParent @currentEl
                console.log @parents
                e.preventDefault()

            getRules: (el)->
                rules = CSSUtilities.getCSSRules el, '*', 'selector,css'
                @rules = @rules.concat(rules)
                for child in el.children
                    @getRules(child)

            printRules: (rules)->
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
                console.log result.join '\n'

            getParent: (el)->
                parentNode = el.parentNode
                if parentNode and parentNode.nodeName isnt 'BODY'
                    @parents.push
                        nodeName: parentNode.nodeName
                        className: parentNode.className
                    @getParent parentNode

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
