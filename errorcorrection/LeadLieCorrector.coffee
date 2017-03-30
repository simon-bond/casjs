class cas.LeadLieCorrector
    LOG_OUTPUT = false

    fNBells: 0
    fRowsProcessed: 0

    constructor: ->
        @fLastKnownGoodPositions = new Array(cas.MAXNBELLS)

    receiveBong: (bong) ->
        # For the very first row we accept, there should be space in fCurrentRow (but no bells in fNextRow)
        if @fRowsProcessed is 0
            if not @fCurrentRow?
                @fCurrentRow = new cas.RawRow(bong.stroke is cas.HANDSTROKE)
                @fNextRow = new cas.RawRow(bong.stroke isnt cas.HANDSTROKE)

            place1 = @fCurrentRow.findBell(bong.bell)
            if (!@fCurrentRow.isMatchingStroke(bong))
                @fNextRow.addBong(bong)
                @fRowsProcessed++
            else if place1 < 0
                @fCurrentRow.addBong(bong)
            else
                console.log("WARNING: bell "+bong.bell+" sounded twice in row "+@fRowsProcessed+1+"; ignoring second strike.")
            return

        @fNBells = Math.max(@fNBells, @fCurrentRow.getNBells())
        # If we are the same stroke as before, continue to fill up fNextRow
        if (@fNextRow.isMatchingStroke(bong))
            place2 = @fNextRow.findBell(bong.bell)
            if place2 < 0
                @fNextRow.addBong(bong)
            else
                # Hmm, we must have come across a bell which has been shunted up by some earlier lie/lead swaps.
                # No choice but to swap its stroke and start a new row for it.
                @finishRow()
                @fNextRow.addBong(bong.swapStroke())
            return

        # Otherwise, both rows are full; now is the time to decide if any shuffling needs to go on between the end of
        # fCurrentRow and the start of fNextRow.
        if @fRowsProcessed < 2
            # For the first whole pull, we have no information about previous positions of bells, but we can try and look
            # at the first handstroke gap, and we can see if the bells look like they ought to be in rounds.
            # But first, we make a simple check to see if any bells can be moved off the end of the first row onto the
            # start of the second row, without losing anything off the end of the second; in this case, it's likely that
            # we have started "listening" halfway through a row. Note this generally won't be able to sort the whole
            # problem, since at least one of the misplaced bells is likely to be hanging on the end of the second row,
            # blocking our ability to move it off the end of the first.
            while @fCurrentRow.getRowSize()>1
                firstRowLie = @fCurrentRow.getLastBong()
                if @fNextRow.findBell(firstRowLie.bell) >= 0
                    # Nope, can't fit bell onto the second row - exit loop
                    break;
                # Yes! Bell fits on start of next row. Swap stroke and put it there.
                @fCurrentRow.removeLastBong()
                @fNextRow.addBongAtLead(firstRowLie.swapStroke())

            # See if the first row is the end plus the start of rounds - would be a clue that we have started halfway
            # through a rounds row.
            split = @getCyclicSplit(@fCurrentRow)
            if split > 0
                # If the second row is the same, it's a cert
                if split is @getCyclicSplit(@fNextRow)
                    # However, final check to make sure none of the bells we are about to move off the end of the
                    # second row match the new incoming bong - can't add them both to the third row!
                    for i in [split...@fNextRow.getRowSize()] by 1
                        if (@fNextRow.getBellAt(i+1) is bong.bell)
                            # Bad - abandon efforts
                            @finishRow();
                            @fNextRow.addBong(bong)
                            return

                    # Move the bells up.
                    extra = new cas.RawRow(!@fNextRow.isHandstroke())
                    for i in [split...@fNextRow.getRowSize()] by 1
                        extra.addBongAtLead(@fNextRow.removeLastBong().swapStroke())
                        @fNextRow.addBongAtLead(@fCurrentRow.removeLastBong().swapStroke())

                    @finishRow()
                    @fNextRow = extra
                    # Still have to deal with the latest incoming bong!
                    @fNextRow.addBong(bong)
                    return

        else

            # Once we're up and running, we try and use previous information about the bells at lead and lie to
            # determine what to do with them. For instance, if a bell appears at the end of a row, whereas previously
            # it was at the start, this is a clue that it needs shunting to the start of the next change.
            if @fCurrentRow.getRowSize() is @fCurrentRow.getNBells()
                firstRowLie = @fCurrentRow.getLastBong()
                if (bong.bell isnt firstRowLie.bell and @fLastKnownGoodPositions[firstRowLie.bell-1] < @fNBells/3)
                    placeInNext = @fNextRow.findBell(firstRowLie.bell)
                    if (placeInNext is @fNextRow.getRowSize())
                        # Bong can be moved, but we have to shunt the same bell off the end of the next row, too.
                        @fCurrentRow.removeLastBong()
                        nextRowLie = @fNextRow.removeLastBong()
                        @fNextRow.addBongAtLead(firstRowLie.swapStroke())
                        @finishRow()
                        @fNextRow.addBong(nextRowLie.swapStroke())
                        @fNextRow.addBong(bong)
                        return

                    if placeInNext < 0
                        # Bong can be moved, and it's easy since it doesn't exist in the next row.
                        @fCurrentRow.removeLastBong()
                        @fNextRow.addBongAtLead(firstRowLie.swapStroke())
                        @finishRow();
                        @fNextRow.addBong(bong);
                        return

                # Nope - carry on.

        @finishRow()
        @fNextRow.addBong(bong)

    getCyclicSplit: (row) ->
        rotatedRow = new cas.RawRow(row.isHandstroke())
        # SB: naughty...
        bells = row.fBells;
        i = 0
        b1 = bells[i]
        split = 1
        while bells[i+1]?
            b2 = bells[i+1]
            i++
            if (b1.bell - b2.bell >= @fNBells-2)
                break
            b1 = b2
            split++


        if (split < row.getRowSize())
            for i in [split...row.getRowSize()] by 1
                rotatedRow.addBong(row.getBong(i+1))
            for i in [0...split] by 1
                rotatedRow.addBong(row.getBong(i+1))
            if (rotatedRow.isCloseToRounds())
                return split

        return -1

    finishRow: ->
        if (LOG_OUTPUT)
            console.log("LeadLieCorrector: "+fCurrentRow.rowAsString());
        for bong in @fCurrentRow
            @fNextStage.receiveBong(bong)
            @fLastKnownGoodPositions[bong.bell-1] = @fCurrentRow.findBell(bong.bell)

        @fCurrentRow = @fNextRow;
        @fNextRow = new cas.RawRow(!@fCurrentRow.isHandstroke())
        @fRowsProcessed++

    notifyInputComplete: ->
        @finishRow()
        @finishRow()
        @fNextStage.notifyInputComplete()

    setNextStage: (nextStage) ->
        @fNextStage = nextStage