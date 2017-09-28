class cas.UIWindow

    constructor: ->
        @fBellStats = document.getElementById('bellStats')
        @fInChangesOnly = true
        @fSelectedBell = 0

        @fDisplay = new cas.StrikingDisplay()

    loadRows: (data) ->
        @fData = data
        @updateStats()
        @fDisplay.loadRows(@fData)

    updateStats: ->
        @updateBellStats()
        @updateTouchStats()

    updateBellStats: ->
        if not @fBellStats? then return

        s = @getBellStats()
        @fBellStats.innerHTML = s

    updateTouchStats: ->
        if not @fTouchStats? then return

        s = @getTouchStats()
        @fTouchStats.innerHTML = s

    visualisationComplete: ->

    getTouchStats: ->
        nfaults = 0
        faultPercentage = 0
        if @fData?
            strikingRMSE = @fData.getStrikingRMSE(@fInChangesOnly)
            discreteRMSE = @fData.getDiscreteStrikingRMSE(@fInChangesOnly)
            rowLengthSD = @fData.getRowLengthSD(@fInChangesOnly)
            maxDuration = @fData.getMaxDuration(@fInChangesOnly)
            minDuration = @fData.getMinDuration(@fInChangesOnly)
            avGap = @fData.getMeanInterbellGap(@fInChangesOnly)
            nfaults = @fData.getFaults(@fInChangesOnly)
            faultPercentage = @fData.getFaultPercentage(@fInChangesOnly)

        s = ""
        s += "<html><table>"
        s += "<tr><td><b></b></td><td>Whole</td><td>Hand</td><td>Back</td></tr>"
        @rowHtml(s, cas.TouchStats.TEXT_STRIKING_RMSE, strikingRMSE)
        @rowHtml(s, cas.TouchStats.TEXT_DISCRETE_RMSE, discreteRMSE)
        @rowHtml(s, cas.TouchStats.TEXT_INTERVAL_MEAN, avGap)
        @rowHtml(s, cas.TouchStats.TEXT_QUICKEST_ROW, minDuration)
        @rowHtml(s, cas.TouchStats.TEXT_SLOWEST_ROW, maxDuration)
        @rowHtml(s, cas.TouchStats.TEXT_ROW_LENGTH_SD, rowLengthSD)
        s += "<tr><td>"
        s += cas.TouchStats.TEXT_FAULTS
        s += "</td><td>"
        s += nfaults
        s += "</td><td>"
        s += @toPercentage(faultPercentage)
        s += "</td><td></td></tr>"
        s += "</table></html>"
        return s

    getBellStats: ->
        if @fData? && @fSelectedBell > 0
            bellSD = @fData.getBellSD(@fSelectedBell, @fInChangesOnly)
            bellRMSE = @fData.getBellRMSE(@fSelectedBell, @fInChangesOnly)
            bellLate = @fData.getLateness(@fSelectedBell, @fInChangesOnly)

        s = "<html><table>"
        s += "<tr><td><b>Selected:</b></td><td>"
        if @fSelectedBell > 0
            s += fSelectedBell
        else
            s += "none"
        s += "</td><td></td><td></td></tr>"
        s += "<tr><td><b></b></td><td>Whole</td><td>Hand</td><td>Back</td></tr>"
        @rowHtml(s, cas.TouchStats.TEXT_RMSE, bellRMSE)
        @rowHtml(s, cas.TouchStats.TEXT_SD, bellSD)
        @rowHtml(s, cas.TouchStats.TEXT_AV_MS_LATE, bellLate)
        s += "</table></html>"
        return s


    rowHtml: (s, rowTitle, stats) ->
        s += "<tr><td>"
        s += rowTitle
        s += "</td><td>"
        s += toMilliseconds(stats.whole)
        s += "</td><td>"
        s += toMilliseconds(stats.hand)
        s += "</td><td>"
        s += toMilliseconds(stats.back)
        s += "</td></tr>"