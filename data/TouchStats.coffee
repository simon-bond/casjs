class cas.TouchStats
    WHOLEPULL = 0
    HANDSTROKE = 1
    BACKSTROKE = 2

    MAXFAULTSPERROW = 4
    FAULTFACTOR = 0.75

    TEXT_STRIKING_RMSE = "Striking RMSE"
    TEXT_DISCRETE_RMSE = "Discrete RMSE"
    TEXT_STRIKING_SD = "Striking SD"
    TEXT_DISCRETE_SD = "Discrete SD"
    TEXT_INTERVAL_MEAN = "Interval mean"
    TEXT_QUICKEST_ROW = "Quickest row"
    TEXT_SLOWEST_ROW = "Slowest row"
    TEXT_ROW_LENGTH_SD = "Row length SD"
    TEXT_FAULTS = "Faults"
    # These ones for individual bell stats
    TEXT_SD = "Std deviation"
    TEXT_RMSE = "RMS Error"
    TEXT_AV_MS_LATE = "Av ms late"

    constructor: (data, nbells) ->
        @fStatsCache = {}
        @fData = data
        # We store the number of rows to capture the value at the moment of construction. All the stats operations
        # are based on rows up to this value, so are guaranteed to be constant even if another thread adds more rows.
        @fNRows = @fData.getNRows()
        @fNBells = nbells

        @getMinDuration(false)
        @getMaxDuration(false)

    getRow: (i) -> return @fData.getRow(i)

    # Don't ask the data for the number of rows - might have increased since we were constructed.
    getNRows: -> return @fNRows

    getNBells: -> return @fNBells

    outputStats: (out, inChangesOnly) ->
        out("Touch stats calculated from " + @getNRows() + " rows")
        out("Faults: " + @getFaults(inChangesOnly) + ", " + @getFaultPercentage(inChangesOnly) + "%")
        out("Metric, whole, hand, back")
        @_outThree(out, TEXT_STRIKING_RMSE, @getStrikingRMSE(inChangesOnly))
        @_outThree(out, TEXT_DISCRETE_RMSE, @getDiscreteStrikingRMSE(inChangesOnly))
        @_outThree(out, TEXT_INTERVAL_MEAN, @getMeanInterbellGap(inChangesOnly))
        @_outThree(out, TEXT_QUICKEST_ROW, @getMinDuration(inChangesOnly))
        @_outThree(out, TEXT_SLOWEST_ROW, @getMaxDuration(inChangesOnly))
        @_outThree(out, TEXT_ROW_LENGTH_SD, @getRowLengthSD(inChangesOnly))
        for i in [1..@getNBells()]
            out("Bell " + i)
            @_outThree(out, TEXT_SD, @getBellSD(i, inChangesOnly))
            @_outThree(out, TEXT_RMSE, @getBellRMSE(i, inChangesOnly))
            @_outThree(out, TEXT_AV_MS_LATE, @getLateness(i, inChangesOnly))
        out()

    _outThree: (out, text, stats) ->
        out(text + ", " + stats.whole + ", " + stats.hand + ", " + stats.back)

    visitRows: (visitor, stroke, inChanges) ->
        if @fNRows is 0
            return
        i = 0
        step = 2
        if stroke is WHOLEPULL
            step = 1
        else if (stroke is HANDSTROKE && not @getRow(0).isHandstroke())
            i++
        else if (stroke is BACKSTROKE && @getRow(0).isHandstroke())
            i++
        while i < @fNRows
            row = @getRow(i)
            if not row?
                console.log("Null Row in visitRows = " + i + " out of " + @fNRows)
            else
                rowWorthVisiting = true
                # Don't visit row if we're only marking changes, and we're not in changes
                if (inChanges && !row.isInChanges())
                    rowWorthVisiting = false
                # Don't visit row if not all bells struck in it
                #if (row.getRowSize()<fNBells)
                #  rowWorthVisiting = false;
                if (rowWorthVisiting)
                    visitor.visit(row)
            i += step

    cachedVisitRows: (visitor, stroke, inChanges, cacheKey) ->
        cacheKey = cacheKey + "/" + stroke + "/" + inChanges
        cacheValue = @fStatsCache[cacheKey]
        unless cacheValue?
            @visitRows(visitor, stroke, inChanges)
            cacheValue = visitor.getResult()
            @fStatsCache[cacheKey] = cacheValue
        cacheValue

    # Stats getters

    getFaults: (inChanges, faultFactor) ->
        faultFactor ?= FAULTFACTOR
        return @cachedVisitRows(new RowTotalVisitor(new RowFaultsRetriever(faultFactor)), WHOLEPULL, inChanges, "Faults")

    getFaultPercentage: (inChanges) ->
        nrows = @cachedVisitRows(new RowTotalVisitor(new RowExistenceRetriever()), WHOLEPULL, inChanges, "NRows")
        max = nrows * MAXFAULTSPERROW
        return (max - @getFaults(inChanges)) / max

    getMinDuration: (inChanges) ->
        ret =
            hand: @_getMinDuration(HANDSTROKE, inChanges)
            back: @_getMinDuration(BACKSTROKE, inChanges)
            whole: @_getMinDuration(WHOLEPULL, inChanges)
        return ret

    _getMinDuration: (stroke, inChanges) ->
        v = null;
        cacheKey = "MinDuration"
        if stroke is WHOLEPULL
            v = new RowMinVisitor(new WholePullDurationRetriever())
            stroke = BACKSTROKE
            cacheKey += "Whole"
        else
            v = new RowMinVisitor(new RowDurationRetriever())

        return @cachedVisitRows(v, stroke, inChanges, cacheKey)

    getMaxDuration: (inChanges) ->
        ret =
            hand: @_getMaxDuration(HANDSTROKE, inChanges)
            back: @_getMaxDuration(BACKSTROKE, inChanges)
            whole: @_getMaxDuration(WHOLEPULL, inChanges)
        return ret

    _getMaxDuration: (stroke, inChanges) ->
        v = null
        cacheKey = "MaxDuration"
        if stroke is WHOLEPULL
            v = new RowMaxVisitor(new WholePullDurationRetriever())
            stroke = BACKSTROKE
            cacheKey += "Whole"
        else
            v = new RowMaxVisitor(new RowDurationRetriever())
        return @cachedVisitRows(v, stroke, inChanges, cacheKey)

    getMeanInterbellGap: (inChanges) ->
        ret =
            hand: @_getMeanInterbellGap(HANDSTROKE, inChanges)
            back: @_getMeanInterbellGap(BACKSTROKE, inChanges)
            whole: @_getMeanInterbellGap(WHOLEPULL, inChanges)
        return ret

    _getMeanInterbellGap: (stroke, inChanges) ->
        return @cachedVisitRows(new RowMeanVisitor(new InterbellGapRetriever()), stroke, inChanges, "MeanInterbellGap")

    getRowLengthSD: (inChanges) ->
        ret =
            hand: @_getRowLengthSD(HANDSTROKE, inChanges)
            back: @_getRowLengthSD(BACKSTROKE, inChanges)
            whole: @_getRowLengthSD(WHOLEPULL, inChanges)
        return ret

    _getRowLengthSD: (stroke, inChanges) ->
        rowLengthMean = @_getMeanRowLength(stroke, inChanges)
        v = new RowMeanVisitor(new RowValueVarianceRetriever(new RowDurationRetriever(), rowLengthMean))
        return Math.sqrt(@cachedVisitRows(v, stroke, inChanges, "RowLengthSD"))

    getMeanRowLength: (inChanges) ->
        ret =
            hand: @_getMeanRowLength(HANDSTROKE, inChanges)
            back: @_getMeanRowLength(BACKSTROKE, inChanges)
            whole: @_getMeanRowLength(WHOLEPULL, inChanges)
        return ret

    _getMeanRowLength: (stroke, inChanges) ->
        return @cachedVisitRows(new RowMeanVisitor(new RowDurationRetriever()), stroke, inChanges, "MeanRowLength");

    getDiscreteStrikingRMSE: (inChanges) ->
        ret =
            hand: @_getDiscreteStrikingRMSE(HANDSTROKE, inChanges)
            back: @_getDiscreteStrikingRMSE(BACKSTROKE, inChanges)
            whole: @_getDiscreteStrikingRMSE(WHOLEPULL, inChanges)
        return ret

    _getDiscreteStrikingRMSE: (stroke, inChanges) ->
        return Math.sqrt(@cachedVisitRows(new RowMeanVisitor(new RowDiscreteVarianceRetriever()), stroke, inChanges, "DiscreteRMSE"))

    getStrikingRMSE: (inChanges) ->
        ret =
            hand: @_getStrikingRMSE(HANDSTROKE, inChanges)
            back: @_getStrikingRMSE(BACKSTROKE, inChanges)
            whole: @_getStrikingRMSE(WHOLEPULL, inChanges)
        return ret

    _getStrikingRMSE: (stroke, inChanges) ->
        return Math.sqrt(@cachedVisitRows(new RowMeanVisitor(new RowStrikingVarianceRetriever()), stroke, inChanges, "StrikingRMSE"))

    getBellSD: (bell, inChanges) ->
        ret =
            hand: @_getBellSD(bell, HANDSTROKE, inChanges)
            back: @_getBellSD(bell, BACKSTROKE, inChanges)
            whole: @_getBellSD(bell, WHOLEPULL, inChanges)
        return ret

    _getBellSD: (bell, stroke, inChanges) ->
        meanLateness = @_getLateness(bell, stroke, inChanges)
        v = new BellMeanVisitor(new BellValueVarianceRetriever(new BellLatenessRetriever(), meanLateness), bell)
        return Math.sqrt(@cachedVisitRows(v, stroke, inChanges, "BellSD"+bell))

    getBellRMSE: (bell, inChanges) ->
        ret =
            hand: @_getBellRMSE(bell, HANDSTROKE, inChanges)
            back: @_getBellRMSE(bell, BACKSTROKE, inChanges)
            whole: @_getBellRMSE(bell, WHOLEPULL, inChanges)
        return ret

    _getBellRMSE: (bell, stroke, inChanges) ->
        v = new BellMeanVisitor(new BellValueVarianceRetriever(new BellLatenessRetriever(), 0), bell)
        return Math.sqrt(@cachedVisitRows(v, stroke, inChanges, "BellRMSE"+bell))

    getLateness: (bell, inChanges) ->
        ret =
            hand: @_getLateness(bell, HANDSTROKE, inChanges)
            back: @_getLateness(bell, BACKSTROKE, inChanges)
            whole: @_getLateness(bell, WHOLEPULL, inChanges)
        return ret

    _getLateness: (bell, stroke, inChanges) ->
        return @cachedVisitRows(new BellMeanVisitor(new BellLatenessRetriever(), bell), stroke, inChanges, "BellLateness"+bell)

    getMeanHandstrokeGap: (inChanges) ->
        return @cachedVisitRows(new RowMeanVisitor(new HandstrokeGapRetriever()), HANDSTROKE, inChanges, "MeanHandstrokeGap")

    getHandstrokeGapSD: (inChanges) ->
        hgMean = @getMeanHandstrokeGap(inChanges)
        v = new RowMeanVisitor(new RowValueVarianceRetriever(new HandstrokeGapRetriever(), hgMean))
        return Math.sqrt(@cachedVisitRows(v, HANDSTROKE, inChanges, "HandstrokeGapSD"))

    getMeanBellHandstrokeGap: (bell, inChanges) ->
        return @cachedVisitRows(new PlacedBellMeanVisitor(new HandstrokeGapRetriever(), bell, 1), HANDSTROKE, inChanges, "MeanBellHandstrokeGap"+bell)

    getBellHandstrokeGapSD: (bell, inChanges) ->
        hgMean = @getMeanBellHandstrokeGap(bell, inChanges)
        v = new PlacedBellMeanVisitor(new RowValueVarianceRetriever(new HandstrokeGapRetriever(), hgMean), bell, 1)
        return Math.sqrt(@cachedVisitRows(v, HANDSTROKE, inChanges, "BellHandstrokeGapSD"+bell))



    class BaseRowVisitor
        d: 0
        getResult: -> return @d

    class RowTotalVisitor extends BaseRowVisitor
        constructor: (r) ->
            @retriever = r;

        visit: (row) ->
            @d += @retriever.getValue(row)

    class RowMeanVisitor extends BaseRowVisitor
        constructor: (r) ->
            @retriever = r
            @c = 0

        visit: (row) ->
          @d += @retriever.getValue(row)
          @c++

        getResult: ->
            if @c > 0
                @d = @d/@c
            return @d;

    class BellMeanVisitor extends BaseRowVisitor
        constructor: (r, b) ->
            @retriever = r
            @bell = b
            @c = 0

        visit: (row) ->
            place = row.findBell(@bell);
            if place > 0
                @d += @retriever.getValue(row, place)
                @c++

        getResult: ->
            if @c > 0
                @d = @d/@c
            return @d

    class PlacedBellMeanVisitor extends BellMeanVisitor
        constructor: (r, b, p) ->
            super(r, b)
            @place = p

        visit: (row) ->
            p = row.findBell(@bell)
            if (p > 0 && p is @place)
                @d += @retriever.getValue(row, @place)
                @c++

    class RowMaxVisitor extends BaseRowVisitor
        constructor: (r) ->
            @retriever = r

        visit: (row) ->
            @d = Math.max(@d, @retriever.getValue(row))

    class RowMinVisitor extends BaseRowVisitor
        constructor: (r) ->
            @retriever = r
            @d = Number.MAX_VALUE

        visit: (row) ->
            @d = Math.min(@d, @retriever.getValue(row))


    # Retrievers

    class RowExistenceRetriever
        getValue: (row) -> return 1

    class RowFaultsRetriever
        constructor: (ff) ->
            # Proportion of inter-bell gap deemed to be a fault
            @faultFactor = ff
            @t = 0

        getValue: (row) ->
            nfaults = 0
            maxGoodGap = @faultFactor * row.getMeanInterbellGap()
            i = 1
            if row.isHandstroke()
                @t = row.getBong(i++).time

            while i <= row.getRowSize()
                d = row.getBong(i++).time
                if Math.abs(d - @t) < maxGoodGap
                    nfaults++
                @t = d

            if nfaults > MAXFAULTSPERROW
                nfaults = MAXFAULTSPERROW
            return nfaults

    class RowValueVarianceRetriever
        constructor: (r, m) ->
            @delegate = r
            @mean = m

        getValue: (row) ->
            x = @delegate.getValue(row) - @mean
            return x*x

    class BellValueVarianceRetriever
       constructor: (r, m) ->
            @delegate = r
            @mean = m

        getValue: (row, place) ->
            x = @delegate.getValue(row, place) - @mean
            return x*x

    class BellLatenessRetriever
        getValue: (row, place) ->
            return row.getLatenessMilliseconds(place)

    class RowStrikingVarianceRetriever
        getValue: (row) ->
            return row.getVariance()

    class RowDiscreteVarianceRetriever
        getValue:(row) ->
            return row.getDiscreteVariance()

    class RowDurationRetriever
        getValue: (row) ->
            return row.getRowDuration()

    # Should only be used on backstrokes
    class WholePullDurationRetriever
        getValue: (row) ->
            return row.getWholePullDuration()

    class InterbellGapRetriever
        getValue: (row) ->
            return row.getMeanInterbellGap()

    # Should only be used on handstrokes
    class HandstrokeGapRetriever
        getValue: (row) ->
            return row.getHandstrokeGapMs()