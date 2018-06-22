 
# An error corrector which attempts to ensure bells in the same row are contiguous in the input stream,
# if necessary by taking bells out of strict time order. This could be desirable if, for instance, a bell has
# struck so late that it has overlapped with the next change. Where the ringing is very good, and no overlap
# between rows is occurring, this error corrector should have no effect on the stream of bongs.
# <p>
# We assume that the input bong stream is in strict time-sorted order, and that gross hardware failures such
# as bong echoes have been removed. However, since it is never possible to manufacture bongs for strike notes
# missed by the sensors, we have to cope with these. We do not rely on the presence of any hand/back information,
# so expect later error correctors to be added to the pipeline to supply this. If reliable hand/back flags were
# available, it might be possible to product a cleverer version of RowOverlapCorrector.
#
# Note that the RowOverlapCorrector does a lot of the work once performed by the RowAccumulator. Effectively
# the job has been split up into a number of separate phases, implemented as ErrorCorrectors. The job of
# bringing bongs together in contiguous rows is now the first step, and is followed by two phases which allocate
# the rows into alternating handstroke/backstroke pairs: the StrokeCorrector, which assigns strokes based on the
# direct output of the RowOverlapCorrector, and the LeadLieCorrector, which mops up any remaining problems where
# bells have, for example, been treated as striking at the end of one row, whereas they were really at the start
# of the next.

class cas.RowOverlapCorrector
    # How many places out of the strict time order a bell is allowed to be moved in order to stay in the "right" row */
    MAX_OVERLAP = 1
    LOG_OUTPUT = false

    fNBells : 0;

    constructor: ->
        @fCurrentRow = new cas.RawRow(true)
        @fNextRow = new cas.RawRow(false)

    receiveBong: (bong) ->
        place1 = @fCurrentRow.findBell(bong.bell)
        place2 = @fNextRow.findBell(bong.bell)
        @fNBells = Math.max(@fNBells, @fCurrentRow.getNBells())

        # The first thing we do is check for the apparently nonsensical case that the bell has already been put into the
        # next row, but isn't in the current row. This can occur if we have had two delayed strikes, and have already put
        # the first one into the next row, because we've decided a sensor strike has been lost. However, if another
        # sensor strike does come along reasonably quickly, we can change our mind, and put the first strike back into
        # the current row.
        if place1 < 0 and place2 > 0
            bongInNextRow = @fNextRow.getBong(place2)
            # Does the bong we put into the next row really belong in the current?
            # Check its timestamp to see whether it was the leading bell in the next row - if so, move it to the last
            # bell of the current row instead.
            if bongInNextRow.time is @fNextRow.getFirstStrikeTime()
                @fNextRow.removeBong(place2)
                @fCurrentRow.addBong(bongInNextRow)
                @fNextRow.addBong(bong)
                return
            
            # If we decide not to swap the bongs, we have no choice but to start a new row; we absolutely can't
            # put two strike notes from the same bell in the wrong order!

        # If neither the current or next row contains the new bell, we should consider adding it to the current row.
        else if place1 < 0
            # But it's possible the bell actually belongs in the next row - for example if an uncorrected sensor error
            # has simply missed the bell from the current row. This is quite likely if, for example, we have already
            # started filling the next row with bells: if that's true, then adding the new bell to the old row will
            # place it out of strict time order. However, we can't discount this strategy completely, since it could
            # be the bell is just striking very late, in the old row but overlapping the new. Distinguishing these two
            # cases lies at the heart of our problem!
            # The solution we adopt here is to move the bell into the current row if there are not more than
            # MAX_OVERLAP bells in the next row. This ensures we can cope with overlaps up to this constant value.
            # If for instance MAX_OVERLAP=2, then we are allowed to place a bell a at the end of a row, even though
            # there are two bells, bc, at the start of the next row which have actually rung earlier.
            if @fNextRow.getRowSize() <= MAX_OVERLAP
                @fCurrentRow.addBong(bong)
                return

        # If we haven't been able to add this bell to the current row, try adding it to the next row instead.
        if place2 < 0
            @fNextRow.addBong(bong)
            return

        # If both current and next are full, start a new row.
        @finishRow()
        @fNextRow.addBong(bong)

    finishRow: ->
        if LOG_OUTPUT
            console.log("RowOverlapCorrector: "+fCurrentRow)
        for bong in @fCurrentRow.fBells
            @fNextStage.receiveBong(bong)
        @fCurrentRow = @fNextRow
        @fNextRow = new cas.RawRow(!@fCurrentRow.isHandstroke())

    notifyInputComplete: ->
        @finishRow()
        @finishRow()
        @fNextStage.notifyInputComplete()

    setNextStage: (nextStage) ->
        @fNextStage = nextStage