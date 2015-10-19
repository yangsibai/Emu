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

                @toggle()
                console.log "total:", Date.now() - start + 'ms, length:', html.innerHTML.length

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

            getParent: (el, parents)->
                parentNode = el.parentNode
                if parentNode and parentNode.nodeName isnt 'BODY'
                    parents.push parentNode
                    @getParent parentNode, parents

            generateHTML: ->
                htmlNode = document.createElement 'HTML'

                headNode = document.createElement 'HEAD'

                styleNode = document.createElement 'STYLE'
                styleNode.type = 'text/css'
#                styleNode.appendChild document.createTextNode @generateCss rules
                headNode.appendChild styleNode

                htmlNode.appendChild headNode
                bodyNode = document.body.cloneNode false
                cssRules = [
                    @css document.body.parentNode
                    @css document.body
                ]
                @appendSelected document.body, bodyNode, cssRules
                styleNode.appendChild document.createTextNode cssRules.join '\n'
                htmlNode.appendChild bodyNode
                return htmlNode

            appendSelected: (parent, appendTo, rules)->
                for node in parent.childNodes
                    if node.hasSelected
                        if node.isSelected
                            rules.push @allCss node
                            appendTo.appendChild node.cloneNode true
                        else
                            rules.push @css node
                            clonedNode = node.cloneNode false
                            appendTo.appendChild clonedNode
                            @appendSelected node, clonedNode, rules

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

            css: (el)->
                rules = []
                for sheet in document.styleSheets
                    cssRules = sheet.cssRules
                    if cssRules
                        for rule in cssRules
                            if el.matches? rule.selectorText
                                rules.push rule.cssText
                return rules.join('\n')

            _allCss: (el, rules)->
                css = @css el
                rules.push css if css
                for child in el.childNodes
                    @_allCss child, rules

            allCss: (el)->
                rules = []
                @_allCss el, rules
                return rules.join '\n'

        emu = new Emu()
        chrome.runtime.onMessage.addListener (msg)->
            emu.toggle()
