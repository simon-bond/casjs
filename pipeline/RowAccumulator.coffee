class cas.RowAccumulator

    fNBells: 0;

    constructor: (pipeline) ->
        @fPipeline = pipeline
        @fData = []
        @fCurrentRow = new cas.RawRow(true)
        @fNextRow = new cas.RawRow(false)

    # Assume error correction has sorted out most problems with input - Bongs in time-sorted order,
    # no sensor echoes, handstroke/backstroke flags correct, or marked as unknown.
    # Still have to deal with missing blows, and bells sounding their first stroke of the next row
    # before the current row is complete.

    receiveBong: (bong) ->
        # fNextRow will be empty when the very first row is received; fill up fCurrentRow first
        if @fNextRow.getRowSize() is 0
            if @fCurrentRow.isMatchingStroke(bong)
                if @fCurrentRow.findBell(bong.bell) > 0
                    console.warn("WARNING: bell #{bong.bell} sounded twice in row 1; ignoring second strike.")
                else
                    @fCurrentRow.addBong(bong)
                return

        # See if we fit in fNextRow
        if @fNextRow.isMatchingStroke(bong)
            if @fNextRow.findBell(bong.bell) > 0
                console.warn("WARNING: bell #{bong.bell} sounded twice in row #{@fData.length+2}; ignoring second strike.")
            else
                @fNextRow.addBong(bong)
            return

        # Nope - finish the row and add to the next
        @finishRow();
        @fNextRow.addBong(bong)

    finishRow: ->
        @fNBells = Math.max(@fNBells, @fCurrentRow.getNBells())
        @fData.push(@fCurrentRow)
        @fCurrentRow = @fNextRow;
        @fNextRow = new cas.RawRow(!@fCurrentRow.isHandstroke())
        @fPipeline.rowsAvailable(@fData.length)

    isSameStrokeBongs: (b1, b2) ->
        if (b1.stroke is cas.UNKNOWNSTROKE or b2.stroke is cas.UNKNOWNSTROKE)
            return true
        return b1.stroke is b2.stroke

    isSameStrokeBongRow: (bong, row) ->
        if bong.stroke is cas.UNKNOWNSTROKE
            return true
        if bong.stroke is cas.HANDSTROKE
            return row.isHandstroke()
        return not row.isHandstroke()

    notifyInputComplete: ->
        @fData.push(@fCurrentRow)
        # Don't add final row if it's a handstroke - stats and rendering can only cope with whole pulls!
        unless @fNextRow.isHandstroke()
            @fData.push(@fNextRow);
        @fPipeline.rowsAvailable(@fData.length)
        @fPipeline.notifyLastRowRung()

    getNBells: -> return @fNBells

    size: -> return @fData.length

    getRow: (i) -> @fData[i]