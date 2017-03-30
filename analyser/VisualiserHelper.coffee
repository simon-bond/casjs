class cas.VisualiserHelper

    constructor: (name, info) ->
        @fName = name
        @fInfo = info
        @clearData()

    clearData: ->
        @fRows = new cas.AveragedRowData()
        @fNRowsProcessed = 0

    setAnalysisListener: (listener) ->
        @fListener = listener

    getNBells: ->
        return @fNBells

    newRowsAvailable: (rowSource) ->
        @fNBells = rowSource.getNBells()
        while @fNRowsProcessed < rowSource.getNRows()
            @newRow(rowSource.getRow(@fNRowsProcessed++))

    notifyLastRowRung: ->
        @fListener.analysisComplete()

    getAveragedTouchData: ->
        return new cas.TouchStats(@fRows, @fRows.getNBells())

    addAveragedRow: (row, endTime, handstrokeGap, duration) ->
        @fRows.addRow(row, endTime, handstrokeGap, duration)
        @fListener.newAveragedRowAvailable()

    getName: -> return @fName

    getInfo: ->
        if (@fInfo == null || @fInfo.trim().length() == 0)
            return @fName
        return @fInfo

    getNRows: -> return @fRows.getNRows()

    getRow: (i) -> return @fRows.getRow(i)
