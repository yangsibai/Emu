$(document).ready ->
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

        startCut: ->
            $(window).on 'mousemove.emu', @listener.bind(this)

        stopCut: ->
            @restoreCurrent()
            $(window).off 'mousemove.emu'

        toggle: ->
            @cutting = not @cutting
            if @cutting
                @startCut()
            else
                @stopCut()

    emu = new Emu()
    chrome.runtime.onMessage.addListener (msg)->
        emu.toggle()
