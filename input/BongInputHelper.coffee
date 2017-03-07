class cas.BongInputHelper

    constructor: (name, input) ->
        @fFilename = name
        @fNBells = -1


    isComment: (line) ->
        if (line.length is 0) or "*#".indexOf(line.charAt(0)) >= 0
            return true
        return false

    getInputSource: -> return "File"

    getInputName: -> return @fFilename

    getNBells: -> return @fNBells

    isOpen: -> return fInputListener!=null && !isClosed()

    isClosed: -> return fClosed

    startLoad: ->
        @processLines()

    processLines: ->
        # reader = new FileReader()
        # _this = this
        # reader.onLoad = (progressEvent) ->
        #     lines = @result.split('\n')
        #     for line in lines
        #         line = line.trim()
        #         unless isComment(line)
        #             processLine(line)
        # reader.readAsText(@fFilename)

        lines = cas.testInput.split('\n')
        for line in lines
            line = line.trim()
            unless @isComment(line)
                @processLine(line)

    readStrokeCharacter: (stroke) ->
        if stroke is 'H'
            return cas.HANDSTROKE
        if stroke is 'B'
            return cas.BACKSTROKE
        console.log("Format error in file - expecting stroke H or B but got: '"+stroke+"'")
        return cas.UNKNOWNSTROKE


    # Parses bell character 1234567890ETABCD into number 1-16, or returns 0 if character not recognised */
    readBellCharacter: (bell) ->
        if bell is 'O' then bell = '0'
        b = cas.BELL_CHARS.indexOf(bell) + 1
        if b <= 0
            console.console.log("Format error in file - bad bell character: "+bell)
        return b
