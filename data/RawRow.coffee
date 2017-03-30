class cas.RawRow
    fNBells : 0

    constructor: (stroke) ->
        @fHandstroke = stroke
        @fBells = []

    toString: ->
        s = ""
        if @fBells.length is 0
            s = "Empty Row"
        else
            s += @fBells[0].toString()
            for i in [1..@fBells.length]
                s += ", "
                s += @fBells[i].toString()
        return s

    rowAsString: ->
        s = ""
        if @fBells.length is 0
            s = "Empty Row"
        else
            for i in [0...@fBells.length]
                bong = @fBells[i]
                s += cas.BELL_CHARS.charAt(bong.bell - 1)
                # Add a stroke indicator if this bell has a different stroke to the row!
                if (bong.stroke is HANDSTROKE) != @fHandstroke
                    s += if bong.stroke is HANDSTROKE then "h" else "b"

    getBong: (place) -> return @fBells[place - 1]

    getBellAt: (place) -> return @getBong(place).bell

    getLastBong: -> return @fBells[@getRowSize() - 1]

    removeBong: (place) -> return @fBells.splice(place - 1, 1)

    removeLastBong: -> return @fBells.splice(@getRowSize() - 1, 1)

    getStrikeTime: (place) -> return @getBong(place).time

    getFirstStrikeTime: -> return @getStrikeTime(1)

    getLastStrikeTime: -> return @getStrikeTime(@getRowSize())

    findBell: (bell) ->
        place = 1
        while place <= @fBells.length
            if @getBellAt(place) is bell
                return place
            place++
        return -1

    isHandstroke: -> return @fHandstroke

    isMatchingStroke: (bong) ->
        if @isHandstroke()
            return bong.stroke is cas.HANDSTROKE
        else
            return bong.stroke is cas.BACKSTROKE

    setHandstroke: (handstroke) -> @fHandstroke = handstroke

    addBong: (bong) ->
        @fBells.push(bong)
        @fNBells = Math.max(@fNBells, bong.bell)

    addBongAtLead: (bong) ->
        @fBells.unshift(bong)
        @fNBells = Math.max(@fNBells, bong.bell)

    setBells: (bells, first, last) ->
        for i in [first...last]
            @fBells.push(bells[i])

    getNBells: -> return @fNBells

    getRowSize: -> return @fBells.length


    # A row is "close" to rounds if all bells strike in increasing order of size, or if occasional pairs
    # are swapped but are close to each other in time - say up to 90ms apart.
    # Note that this new algorithm works even if bells are missing from the change completely.

    isCloseToRounds: ->
        b1 = @getBellAt(1)
        for i in [2..@getRowSize()]
            b2 = @getBellAt(i)
            if b1 > b2
                # Allow two bells to be swapped if they are close to each other - adjacent bell numbers,
                # and say up to 90ms apart.
                if b1 - b2 > 1 or @getBong(i).time - @getBong(i-1).time > 90
                    return false
            b1 = b2
        return true

    getRowDuration: -> return @getBong(@getRowSize()).time - @getBong(1).time