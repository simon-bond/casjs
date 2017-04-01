# An error corrector which ignores sensor echoes.
# A sensor echo is defined as a second strike note from the same bell within a short interval.

class cas.SensorEchoCorrecter
    fBongs: new Array(cas.MAXNBELLS)

    constructor: (quickestStrikeTime) ->
        quickestStrikeTime ?= cas.QUICKEST_STRIKE_TIME
        @fQuickestStrikeTime = quickestStrikeTime

    receiveBong: (bong) ->
        prevBong = @fBongs[bong.bell-1]
        if (!prevBong? || bong.time-prevBong.time >= @fQuickestStrikeTime)
            @fBongs[bong.bell-1] = bong
            @fNextStage.receiveBong(bong)

    notifyInputComplete: ->
        @fNextStage.notifyInputComplete()

    setNextStage: (nextStage) ->
        @fNextStage = nextStage