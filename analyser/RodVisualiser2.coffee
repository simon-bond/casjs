class cas.RodVisualiser2 extends cas.RodBaseVisualiser

    NAME: "RodModel2"
    INFO: "The RodModel2 visualiser calculates the desired length of a whole pull, minus handstroke gap, by averaging the difference between the midpoint of the bells striking in the next whole pull and that of the previous whole pull. Handstroke gap is the average gap for the ringing so far."
    fLastRow: null
    fTotalHandstrokeGap: 0.0
    fTotalInterbellGap: 0.0
    fCurrentHandstrokeGap: 0.0

    constructor: ->
        super(@NAME, @INFO)

    clearData: ->
        super
        fLastRow = null
        fTotalHandstrokeGap = 0.0
        fTotalInterbellGap = 0.0
        fCurrentHandstrokeGap = 0.0

    getCurrentHandstrokeGap: ->
        return @fCurrentHandstrokeGap

    newRow: (row) ->
        if row.getRowSize() > 1
            @fTotalInterbellGap += (row.getBong(row.getRowSize()).time - row.getBong(1).time) / (row.getRowSize()-1)
        if row.isHandstroke() and @fLastRow?
            @fTotalHandstrokeGap += row.getStrikeTime(1) - @fLastRow.getStrikeTime(@fLastRow.getRowSize())
            @fCurrentHandstrokeGap = @fTotalHandstrokeGap / @fTotalInterbellGap

        @fLastRow = row;
        super
