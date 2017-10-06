class cas.StrikingDisplay

    SPEED_WIDTH: 200

    CORRECT_LINE_COLOUR: "rgb(0,150,255)"
    GRID_COLOUR: "rgb(150,150,150)"
    LIGHTGRAY: "rgb(211, 211, 211)"
    BACKGROUND_HAND: "rgb(242,242,242)"
    BACKGROUND_BACK: "rgb(230,230,230)"
    BACKGROUND_HANDBAD: "rgb(245,220,220)"
    BACKGROUND_BACKBAD: "rgb(230,207,207)"
    BACKGROUND_HANDGOOD: "rgb(230,245,230)"
    BACKGROUND_BACKGOOD: "rgb(216,230,216)"

    constructor: ->
        @fRowsLoaded = false
        @fInChangesOnly = true
        @fAdvancedView = true

        @fWidthPerBell = 100
        @fHeightPerRow = 20
        @fTitleFontHeight = 12
        @fSmallFontHeight = 12
        @fCharWidth = 3

        @fThisActualX = []
        @fThisCorrectX = []
        @fLastPlace = []
        @fLastActualX = []
        @fLastCorrectX = []

        @fRowLeft = 0
        @fRowRight = 0
        fInterbellGap = 0

        @fInChanges = false
        @fHighlightedBell = 0

        @canvas = document.getElementById('gridCanvas')
        @context = @canvas.getContext('2d')

    loadRows: (data) ->
        if data.getNBells() is 0 then return null
        @fWidthPerBell = Math.round(400/data.getNBells())
        @fData = data
        @fRowsLoaded = true
        if @measureUp()
            @paintCanvas()

    measureUp: ->

        if !@fRowsLoaded then return false

        minDuration = @fData.getMinDuration(false)
        maxDuration = @fData.getMaxDuration(false)
        @fAvBackDuration = (minDuration.back+maxDuration.back)/2
        @fMinDur = Math.min(minDuration.hand, minDuration.back)
        @fMaxMinusMinDur = Math.max(1, Math.max(maxDuration.hand, maxDuration.back) - @fMinDur)

        @fPixelsPerMs = (@fWidthPerBell*@fData.getNBells())/@fAvBackDuration

        # Would really like to use the title font height in the calculation of fY0, since it must reserve space for the title.
        # However, fTitleFontHeight can only be determined once we get a Graphics object and hence a FontRenderContext.
        # These are only available in paintComponent(), not in other methods which might like to call measureUp(), e.g.
        # printing or repaint rectangle invalidation. The safest thing to do is to assume a fixed space for the title,
        # so it is set here to 20 pixels. If you make the title font bigger, this might not be enough!
        @fY0 = 20 + @fHeightPerRow
        @fRowRight = @fWidthPerBell*2 + @fWidthPerBell*@fData.getNBells()
        return true

    paintCanvas: ->
        @context.clearRect(0, 0, @canvas.width, @canvas.height);
        # if (isOpaque())
        # {
        #     g.setColor(getBackground());
        #     g.fillRect(0, 0, getWidth(), getHeight());
        # }

        # fClip = g.getClipBounds();
        # if (!measureUp())
        #     return;

        # fG2D = (Graphics2D)g;
        # Rectangle2D charSize = fNormalBellFont.getStringBounds("0", fG2D.getFontRenderContext());
        # fCharWidth = round(charSize.getWidth()/2);
        # Rectangle2D titleCharSize = fTitleFont.getStringBounds("0", fG2D.getFontRenderContext());
        # fTitleFontHeight = round(titleCharSize.getHeight());
        # Rectangle2D smallCharSize = fSmallAdvancedViewFont.getStringBounds("0", fG2D.getFontRenderContext());
        # fSmallFontHeight = round(smallCharSize.getHeight()*0.6);

        for i in [0...@fData.getNBells()]
            @fLastActualX[i] = -1
            @fLastCorrectX[i] = -1

        @fInChanges = false;

        @renderColumnHeadings()

        # First loop does background, annotations and lines.
        # fG2D.setFont(fNormalBellFont);
        @context.strokeStyle = 'black'

        y = @fY0
        for i in [0...@fData.getNRows()]
            r = @fData.getRow(i)
            if r?
                @calcEffectivePixelsPerMs(r);

                @fRowLeft = @fRowRight - Math.round(r.getRowDuration() * @fEffectivePixelsPerMs)
                @fInterbellGap = Math.round(r.getAveragedGap() * @fEffectivePixelsPerMs)

                # Draw row and duration backgrounds
                @drawRowBackground(y, r, i, if i > 0 then  @fData.getRow(i-1) else null)

                # Print row duration and interbell+handstroke gaps every ten rows
                @annotateRows(y, r, i)

                # Connect bells up with lines
                @drawLines(y, r)

            y+= @fHeightPerRow;


        # Second loop does bell numbers, to ensure they overwrite lines.
        y = @fY0
        for i in [0...@fData.getNRows()]
            r = @fData.getRow(i)
            if r?
                @calcEffectivePixelsPerMs(r)
                @drawBellNumbers(y, r, i)

            y+= @fHeightPerRow

    renderColumnHeadings: ->
        @context.fillStyle = 'blue'
        @context.font = @fTitleFontHeight.toString() + "px serif"
        @context.fillText("Row", 1, @fTitleFontHeight);
        @context.fillText("Striking Graph", @fRowLeft + (@fRowRight - @fRowLeft)/2-20, @fTitleFontHeight)
        @context.fillText("Row Length Graph", @fRowRight + @fInterbellGap + 10, @fTitleFontHeight)

    annotateRows: (y, row, i) ->
        @context.fillStyle = 'black'

        if not row.isHandstroke()
            # Draw row number on every even (backstroke) row
            @context.fillText(""+(i+1), 0,  y)

        if (@fAdvancedView && i%10==0)
            y -= @fHeightPerRow/2
            # Every tenth row, display row duration...
            x = @fRowRight+@fInterbellGap+20
            @context.fillText(""+Math.round(row.getRowDuration())+"ms" , x, y+@fTitleFontHeight/3)

            # ...and handstroke gap.
            @context.fillText(""+Math.round(row.getAveragedGap()*row.getHandstrokeGap()), @fRowLeft, y)
            @context.fillText(" ms", @fRowLeft, y+@fSmallFontHeight)
            # ...and average gap...
            xAG = @fRowRight+@fInterbellGap100
            @context.fillText(""+Math.round(row.getAveragedGap()), xAG, y)
            @context.fillText(" ms", xAG, y+@fSmallFontHeight)

    calcEffectivePixelsPerMs: (row) ->
        if row.isHandstroke()
            # fEffectivePixelsPerMs is the value needed to make this row the same pixel width as the average row (i.e. normalised width)
            @fEffectivePixelsPerMs = @fPixelsPerMs * @fAvBackDuration / (row.getRowDuration() - row.getAveragedGap() * row.getHandstrokeGap())
        else
            @fEffectivePixelsPerMs = @fPixelsPerMs * @fAvBackDuration / row.getRowDuration()

    drawRowBackground: (y, row, rowNumber, prevRow) ->
        durPixels = Math.round((@SPEED_WIDTH*(row.getRowDuration()-@fMinDur))/@fMaxMinusMinDur)
        rowBackground = @getRowColour(row, rowNumber)

        # Fill rectangle for row length, at right of display
        @context.fillStyle = rowBackground
        @context.fillRect(@fRowRight+@fInterbellGap+10, y-@fHeightPerRow, durPixels, @fHeightPerRow)
        # Fill rectangle for row itself - always a fixed, normalised length
        @context.fillRect(@fRowLeft+@fInterbellGap, y-@fHeightPerRow, @fRowRight-@fRowLeft, @fHeightPerRow)

        # Draw marker for end of previous row - shows up if calculated row duration doesn't match difference
        # between row end times.
        if prevRow?
            rowStart = row.getRowEndTime()-row.getRowDuration()
            delta = rowStart-prevRow.getRowEndTime()
            if delta isnt 0
                h = Math.round(@fHeightPerRow*0.25)
                delta *= @fEffectivePixelsPerMs
                if delta>0
                    # Gap between end of last row and start of this row.
                    @context.fillRect(@fRowLeft+@fInterbellGap-delta, y-(h+@fHeightPerRow)/2, delta, h)
                else
                    # Last row cuts into this one.
                    @context.fillStyle = 'white'
                    @context.fillRect(@fRowLeft+@fInterbellGap, y-(h+@fHeightPerRow)/2, -delta, h)

    drawLines: (y, row) ->
        # Loop over row - draw lines
        for j in [0...row.getRowSize()]
            @fThisActualX[j] = @strikeTimeToPixelX(row, row.getStrikeTime(j+1))
            @fThisCorrectX[j] = @strikeTimeToPixelX(row, row.getCorrectStrikeTime(j+1))

            b = row.getBellAt(j+1)
            if @fLastActualX[j]>0
                if (j&1) is 1
                    # For even bell position, draw straight "perfect" place line down the screen.
                    @drawLine(@fLastCorrectX[j], y-@fHeightPerRow*3/2, @fThisCorrectX[j], y-@fHeightPerRow/2, @LIGHTGRAY)

                if (!@fInChangesOnly || @fInChanges)
                    if b is @fHighlightedBell
                        # For highlighted bell, draw blue line indicating perfect ringing position
                        @drawLine(@fLastCorrectX[@fLastPlace[b-1]], y-@fHeightPerRow*3/2, @fThisCorrectX[j], y-@fHeightPerRow/2, @CORRECT_LINE_COLOUR)

                    # Draw lines for each bell, joining up actual strike positions
                    @drawLine(@fLastActualX[@fLastPlace[b-1]], y-@fHeightPerRow*3/2, @fThisActualX[j], y-@fHeightPerRow/2, @GRID_COLOUR)

        @fInChanges = row.isInChanges()
        # Loop over row - update previous bell x ordinates (actual and correct) for lines to next row.
        for j in [0...row.getRowSize()]
            b = row.getBellAt(j+1)
            @fLastPlace[b-1] = j
            @fLastActualX[j] = @fThisActualX[j]
            @fLastCorrectX[j] = @fThisCorrectX[j]

    drawBellNumbers: (y, row,  rowNumber) ->
        y -= 5
        xOff = -@fCharWidth

        # Loop over row - draw bell numbers
        for j in [0...row.getRowSize()]
            b = row.getBellAt(j+1)
            x = @strikeTimeToPixelX(row, row.getStrikeTime(j+1))
            s = cas.BELL_CHARS.charAt(b-1)
            @context.fillStyle = 'black'

            # TODO
            # if (row.getStrikeTime(j+1)==row.getCorrectStrikeTime(j+1))
            # {
            #     // For bells in exactly the right place, draw bold bell number
            #     fG2D.setFont(fBoldBellFont);
            #     fG2D.drawString(s, x+xOff, y);
            #     fG2D.setFont(fNormalBellFont);
            # }
            # else
            # {
            #     // Draw bell number
            #     fG2D.drawString(s, x+xOff, y);
            # }
            @context.fillText(s, x+xOff, y)

    strikeTimeToPixelX: (row, strikeTime) ->
        t = row.getRowEndTime()-strikeTime
        t*= @fEffectivePixelsPerMs
        return @fRowRight - t

    drawLine: (startX, startY, endX, endY, colour) ->
        oldStyle = @context.strokeStyle
        @context.strokeStyle = colour
        @context.beginPath()
        @context.moveTo(startX, startY)
        @context.lineTo(endX, endY)
        @context.stroke()
        @context.strokeStyle = oldStyle

    getRowColour: (row, rowNumber) ->
        if (row.isHandstroke())
            if (row.isGood())
                return @BACKGROUND_HANDGOOD
            else if (row.isBad())
                return @BACKGROUND_HANDBAD
            else
                return @BACKGROUND_HAND
        else
            if (row.isGood())
                return @BACKGROUND_BACKGOOD
            else if (row.isBad())
                return @BACKGROUND_BACKBAD
            else
                return @BACKGROUND_BACK

    setHighlightedBell: (highlightedBell) ->
        @fHighlightedBell = highlightedBell
        @paintCanvas()