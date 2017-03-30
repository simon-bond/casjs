class cas.AveragedRow
    # Good and bad standard deviations, milliseconds accuracy */
    GOOD_CUTOFF: 30
    BAD_CUTOFF: 60

    constructor: (row, endTime, handstrokeGap, duration) ->
        @fRow = row
        @fRowEndTime = endTime
        @fHandstrokeGap = handstrokeGap
        @fRowDuration = duration
        @calcStats()


    calcStats: ->
        # Calculate average gap
        n = @getNBells();
        if @isHandstroke() then n += @fHandstrokeGap
        @fAverageGap = @fRowDuration / n

        # Calculate row variance.
        n = @getRowSize()
        d = 0.0
        dd = 0.0
        for i in [0...n]
            t = @getStrikeTime(i + 1) - @getCorrectStrikeTime(i + 1)
            d += t * t
            x = Math.round(Math.abs(t) / @GOOD_CUTOFF)
            t = x * @GOOD_CUTOFF
            dd += t*t

        if n > 0
            d = d / n
            dd = dd / n
        @fRowVariance = d
        @fDiscreteRowVariance = dd

    toString: -> return @fRow.toString()

    getBong: (place) -> return @fRow.getBong(place)

    getBellAt: (place) -> return @fRow.getBellAt(place)

    getStrikeTime: (place) -> return @fRow.getStrikeTime(place)

    findBell: (bell) -> return @fRow.findBell(bell)

    getCorrectStrikeTime: (place) ->
        timePerBell = @fAverageGap;
        correctTime = @fRowEndTime - Math.round(timePerBell * (@getNBells() - place))
        return correctTime;

    getLatenessMilliseconds: (place) -> return @getStrikeTime(place) - @getCorrectStrikeTime(place)

    getPercentageDeviation: -> return @getStandardDeviation() / @fAverageGap

    getStandardDeviation: -> return Math.sqrt(@fRowVariance)

    getVariance: -> return @fRowVariance

    getDiscreteVariance: -> return @fDiscreteRowVariance

    getAveragedGap: -> return @fAverageGap

    getMeanInterbellGap: ->
        d = 0.0
        if @getRowSize() > 1
            d = (@getBong(@getRowSize()).time - @getBong(1).time) / (@getRowSize() - 1)
        return d

    isHandstroke: -> return @fRow.isHandstroke()

    getRowEndTime: -> return @fRowEndTime

    getRowDuration: -> return @fRowDuration

    getWholePullDuration: -> return @fWholePullDuration

    setWholePullDuration: (duration) -> @fWholePullDuration = duration

    getHandstrokeGap: -> return @fHandstrokeGap

    getHandstrokeGapMs: -> return @fHandstrokeGap * @fAverageGap

    getNBells: -> return @fRow.getNBells()

    getRowSize: -> return @fRow.getRowSize()

    isGood: -> return @getStandardDeviation() <= @GOOD_CUTOFF

    isBad: -> return @getStandardDeviation() >= @BAD_CUTOFF

    isInChanges: -> return @fInChanges

    setIsInChanges: (inChanges) -> @fInChanges = inChanges;

    isCloseToRounds: -> return @fRow.isCloseToRounds()

    getInChangesCount: -> return @fInChangesCount

    setInChangesCount: (inChangesCount) -> @fInChangesCount = inChangesCount