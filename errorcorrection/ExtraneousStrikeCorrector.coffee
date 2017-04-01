
 # Does a similar job to the SensorEchoCorrector, i.e. attempts to weed out extra strikes. However it does
 # this in a more sophisticated way, checking for bells which appear to have rung twice in a row, and weeding
 # out the strike note which seems further away from the average row gap.
 # It is worth using the SensorEchoCorrector first to get rid of eachoes, then the ExtraneousStrikeCorrector to mop up
 # any gross mid-change extra strikes.
 
class cas.ExtraneousStrikeCorrector
    fNBells: 0

    constructor: ->
        @fCurrentRow = new cas.RawRow(true)
        @fNextRow = new cas.RawRow(false)

    receiveBong: (bong) ->
        place1 = @fCurrentRow.findBell(bong.bell)
        place2 = @fNextRow.findBell(bong.bell)
        # Fill first row
        if (@fNextRow.getRowSize() is 0 and place1 < 0)
            @fCurrentRow.addBong(bong)
            return

        # Fill subsequent rows
        if place2 < 0
            @fNextRow.addBong(bong)
            return

        @fNBells = Math.max(@fNBells, @fCurrentRow.getRowSize())
        # No room in next row - consider whether this is because we have had two strikes for this bell
        nBellsInBothRows = 0
        totalSep = 0
        mySep1 = 0
        mySep2 = 0
        for b2 in @fNextRow.fBells
            p1 = @fCurrentRow.findBell(b2.bell)
            if p1 > 0
                b1 = @fCurrentRow.getBong(p1)
                if b2.bell is bong.bell
                    mySep1 = b2.time - b1.time
                    mySep2 = bong.time - b2.time
                else
                    totalSep += b2.time - b1.time
                    nBellsInBothRows++
                    
        # In order to drop a strike, we have to reassure ourselves that, of the three strikes we are looking at,
        # at least one of the inter-strike gaps is less than half the normal interval, and in addition that the
        # total interval including all three strikes is also substantially more than a normal interval.
        avSep = 0   
        if nBellsInBothRows > 0
            avSep = totalSep / nBellsInBothRows
        myTotalSep = mySep1 + mySep2
        if myTotalSep > 0 and myTotalSep < avSep * 1.2
            if mySep1 < mySep
                # Drop middle strike
                @fNextRow.removeBong(@fNextRow.findBell(bong.bell))
                @fNextRow.addBong(bong)
                return
            else if mySep2 < avSep / 2
                # Drop this strike
                return

        # Start new row after all
        @finishRow()
        @fNextRow.addBong(bong)

    finishRow: ->
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