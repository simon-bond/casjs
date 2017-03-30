class cas.RodBaseVisualiser extends cas.VisualiserHelper

    constructor: (name, info) ->
        super(name, info)
        @fNWholePulls = 3
        @fRodRows = new Array(@fNWholePulls*2)


    clearData: ->
        super
        @fFillPoint = 0
        @fEmptyPoint = 0
        @fCurrentInterBellGap = 0.0

    newRow: (row) ->
        @fRodRows[@fFillPoint++] = row
        if @fFillPoint is @fRodRows.length
            # Have got enough rows to make a full set of whole pulls - calculate.
            avWholePullLength = (@calcWholePullMidpoint(@fRodRows.length - 2) - @calcWholePullMidpoint(0)) / (@fRodRows.length / 2 - 1)
            @fCurrentInterBellGap = avWholePullLength / (@getCurrentHandstrokeGap() + 2 * @getNBells())
            while @fEmptyPoint <= (@fRodRows.length / 4) * 2
                @addWholePullRows(@fCurrentInterBellGap)
                @fEmptyPoint+= 2

            @fEmptyPoint -= 2
            for n in [0...@fRodRows.length-2]
                @fRodRows[n] = @fRodRows[n+2]
            @fFillPoint -= 2;

    notifyLastRowRung: ->
        while @fEmptyPoint < @fFillPoint
            @addWholePullRows(@fCurrentInterBellGap)
            @fEmptyPoint+= 2
        super

    addWholePullRows: (interbellGap) ->
        nbells = @getNBells()
        # End of handstroke is midpoint of strike times of all bells in the whole pull minus half a gap.
        rowEndTime = Math.round(@calcWholePullMidpoint(@fEmptyPoint) - 0.5 * interbellGap)
        duration = Math.round(interbellGap * @fRodRows[@fEmptyPoint].getNBells())
        if @fRodRows[@fEmptyPoint].isHandstroke()
            duration+= @getCurrentHandstrokeGap() * interbellGap
        @addAveragedRow(@fRodRows[@fEmptyPoint], rowEndTime, @getCurrentHandstrokeGap(), duration)
        # End of backstroke is end of handstroke plus nbells times interbell gap.
        rowEndTime += nbells * interbellGap
        duration = Math.round(interbellGap*@fRodRows[@fEmptyPoint+1].getNBells())
        if @fRodRows[@fEmptyPoint+1].isHandstroke()
            duration += @getCurrentHandstrokeGap() * interbellGap
        @addAveragedRow(@fRodRows[@fEmptyPoint+1], rowEndTime, @getCurrentHandstrokeGap(), duration)

    calcWholePullMidpoint: (row) ->
        c = 0
        ms = 0
        for i in [0...@fRodRows[row].getRowSize()]
            ms += @fRodRows[row].getBong(i+1).time
            c++

        for i in [0...@fRodRows[row+1].getRowSize()]
            ms+= @fRodRows[row+1].getBong(i+1).time
            c++

        return (ms/c)