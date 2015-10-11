$(document).ready ->
    class Emu
        constructor: ->
            @cutting = false
            @$currentEl = null
            @defaultStyle =
                width: 1
                height: 1
                left: 0
                top: 0
                background: '#f00'
                position: 'absolute'
                opacity: 0.3
                'z-index': 999999
                transform: ''
            mask = $ '<div/>'
            mask.css @defaultStyle

            @mask = mask
            $(document.body).append(@mask)

        restoreCurrent: ->
            @mask.css @defaultStyle

        chooseCurrent: (el)->
            $currentEl = $(el)
            offset = $currentEl.offset()
            width = $currentEl.width()
            height = $currentEl.height()
            @mask.css
                transform: "translateX(#{offset.top}px) translateY(#{offset.left}px) scaleX(#{width}) scaleY(#{height})"
            @$currentEl = $currentEl

        listener: (e)->
            if @$currentEl isnt e.target
                @restoreCurrent()
                @chooseCurrent(e.target)

        startCut: ->
            $(window).on 'mousemove', @listener.bind(this)

        stopCut: ->
            @restoreCurrent()
            $(window).off 'mousemove', @listener.bind(this)

        toggle: ->
            @cutting = not @cutting
            if @cutting
                @startCut()
            else
                @stopCut()

    emu = new Emu()
    chrome.runtime.onMessage.addListener (msg)->
        emu.toggle()
