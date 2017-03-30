class cas.AveragedRowData
    LOG_DEVIATIONS = false
    IN_CHANGES_SENSITIVITY = 1

    constructor: ->
        @fRows = []
        @fNBells = 0

    getRow: (i) -> return @fRows[i]

    getNRows: -> return @fRows.length;

    getNBells: -> return @fNBells

    # Add an averaged row with the given row end time, handstroke gap and row duration.
    # Note that if the given row duration does not match the distance between the row end time
    # and the previous row's end time, then a discontinuity in the display may occur.
    # For the very first row, a duration value of at least the length of the row should be passed.

    addRow: (row, endTime, handstrokeGap, duration) ->
        unless handstroke?
            handstrokeGap = 1.0

        unless duration?
            # work out row duration - just the gap between one row end and the next.
            lastRow = @fRows.length - 1
            duration = 0
            if lastRow >= 0
                duration = endTime - @getRow(lastRow).getRowEndTime()

            else if row.getRowSize() > 1
                # Special case for first row - the end of the "last" row is really the start
                # of this row, but we have to guess when that was. Remember the first row
                # is a handstroke so the previous row end is two bell gaps before the treble.
                duration = row.getStrikeTime(row.getRowSize()) - row.getStrikeTime(1)
                duration = duration + Math.round((1.0 + handstrokeGap) * duration / (row.getRowSize() - 1))

            else
                # Problem case if only one bell struck in first row!
                # Adopt one second.
                duration = 1000;


        avRow = new cas.AveragedRow(row, endTime, handstrokeGap, duration)
        @fRows.push(avRow)
        @fNBells = Math.max(@fNBells, avRow.getNBells())

        n = @fRows.length

        # At every backstroke, calculate whole pull durations, store in both hand & back rows.
        unless avRow.isHandstroke()
            duration = avRow.getRowDuration()
            if n > 1
                handstrokeRow = @getRow(n-2)
                duration += handstrokeRow.getRowDuration()
                handstrokeRow.setWholePullDuration(duration)
            avRow.setWholePullDuration(duration)

        # Set flag to indicate whether this row is "in changes" or not.
        # Initially, just set "in changes" if the row doesn't appear to be rounds.
        # A row is in rounds if all bells strike in pitch-descending order; two-bell swaps are allowed if timing is close.
        currentInChanges = !avRow.isCloseToRounds()
        avRow.setIsInChanges(currentInChanges)

        # Now refine this naive decision based on what previous changes have been
        if n > 1
            prevRow = @getRow(n-2)
            if currentInChanges is prevRow.isInChanges()
                # We're the same as the previous row - increment the "run" counter
                count = prevRow.getInChangesCount() + 1
                avRow.setInChangesCount(count)
                # If the run counter gets high enough, we are now certain what state we are in.
                # Now we need to look at the previous segment - if it was only a short run, we ignore it, resetting
                # the "inchanges" flags back to the current, long run.
                if count >= IN_CHANGES_SENSITIVITY
                    end = n - count - 2
                    @resetInChanges(currentInChanges, end)
            else
                # We're different to the previous row
                avRow.setInChangesCount(0)

        if (LOG_DEVIATIONS)

            s = "Row "
            s += @fRows.length
            s += ":"
            for i in [1..avRow.getRowSize()]
                s += (" ")
                s += avRow.getStrikeTime(i) - avRow.getCorrectStrikeTime(i)

            console.log(s);

    resetInChanges: (currentInChanges, end) ->
        if end > 0
            endOfPreviousSegment = @getRow(end)
            prevCount = endOfPreviousSegment.getInChangesCount()
            if prevCount < IN_CHANGES_SENSITIVITY
                endOfPreviousSegment.setIsInChanges(currentInChanges)
                for i in [1..prevCount]
                    @getRow(end-i).setIsInChanges(currentInChanges)
                # Recursively sort out any even earlier small segments
                @resetInChanges(currentInChanges, end-prevCount-1)

            else if (currentInChanges)
                # Always mark the last row of rounds as "inchanges", to make it part of the touch.
                endOfPreviousSegment.setIsInChanges(true);