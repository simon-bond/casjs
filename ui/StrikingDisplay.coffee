 class cas.StrikingDisplay
    fZoomX: 1.0
    fZoomY: 1.0
    fZoomFont: 1.0

    fWidthPerBell: 100
    fHeightPerRow: 20
    fAdvancedView: false
    fRowsLoaded: false
 
    fNowPlayingBell: -1

    EXTRA_WIDTH = 150
    ROW_WIDTH = 300
    SPEED_WIDTH = 200
    CORRECT_LINE_COLOUR = 'rgb(0,150,255)'
    GRID_COLOUR = 'rgb(150,150,150)'
    LIGHT_GREY = 'rgb(200,200,200)'
    BLACK = 'rgb(0,0,0)'

    MIN_ZOOM_TO_SHOW_BELLS = 0.3

    BACKGROUND_HAND = 'rgb(242,242,242)'
    BACKGROUND_BACK = 'rgb(230,230,230)'
    BACKGROUND_HANDBAD = 'rgb(245,220,220)'
    BACKGROUND_BACKBAD = 'rgb(230,207,207)'
    BACKGROUND_HANDGOOD = 'rgb(230,245,230)'
    BACKGROUND_BACKGOOD = 'rgb(216,230,216)'

    constructor: ->
        canvas = document.getElementById('canvas'); 
        @ctx = canvas.getContext('2d')

    setZoom: (zoom) ->
        @fZoomFont = Math.pow(zoom, 0.4)
        @fZoomX = Math.pow(zoom, 0.2)
        @fZoomY = zoom
        if not @fData?
            @fWidthPerBell = zoomX(100)
        else
            @fWidthPerBell = Math.round(@fZoomX * @getTotalWidth() / @fData.getNBells())
        @fHeightPerRow = @zoomY(20)
        @setupFonts()
        @revalidate()
        @repaint()

    zoomX: (d) -> return Math.round(d * @fZoomX)

    zoomY: (d) -> return Math.round(d * @fZoomY)

    setAutoScroll: (autoscroll) -> @fAutoScroll = autoscroll

    storePreviousScrollPosition: ->  @fPreviousScrollPosition = @getVisibleRect();

    scrollToPreviousPosition: ->
        # if @fPreviousScrollPosition?
            #scrollRectToVisible(fPreviousScrollPosition);

    doLoadRows: (data) ->
        @fWidthPerBell = Math.round(@fZoomX * @getTotalWidth() / data.getNBells())
        @fData = data
        @fRowsLoaded = true
        @paintComponent()

    setAdvancedView: (advancedView) ->
        if @fAdvancedView isnt advancedView
            @fAdvancedView = advancedView
            @updateDisplay()

    getHighlightedBell: -> return @fHighlightedBell

    setHighlightedBell: (highlightedBell) ->
        @fHighlightedBell = highlightedBell
        @repaint()

    setPlayingRow: (row) ->
        if row isnt @fNowPlayingRow
            if @fNowPlayingRow >= 0
                repaintRow(@fNowPlayingRow)
            @fNowPlayingRow = row
            if fNowPlayingRow >= 0
                @repaintRow(@fNowPlayingRow)
                if (@fAutoScroll)
                    @scrollToRow(@fNowPlayingRow)

    setPlayingBell: (bell) ->
        @fNowPlayingBell = bell
        if (@fNowPlayingRow >= 0)
            @repaintRow(@fNowPlayingRow)

    getTotalWidth: -> return @zoomX(ROW_WIDTH)


    repaintRow: (row) ->
        unless @measureUp() then return
        y = @getTopYFromRowNumber(row)
        @repaint(fInsets.left, y, fRowRight+1000, fHeightPerRow*2)

    getRowNumberFromYOrdinate: (y) -> return (y + @fHeightPerRow - @fY0) / @fHeightPerRow
    
    getTopYFromRowNumber: (rowNumber) -> return @fY0 + (rowNumber - 1) * @fHeightPerRow

    scrollToRow: (row) ->
        unless @measureUp() then return
        y = @getTopYFromRowNumber(row)
        #Rectangle r = new Rectangle(0, y-fHeightPerRow, fRowRight, fHeightPerRow*4);
        #scrollRectToVisible(r);

    measureUp: ->
        unless @fRowsLoaded then return false
        @fInsets = @getInsets()
        if not @fNormalBellFont? then setupFonts()

        minDuration = @fData.getMinDuration(false)
        maxDuration = @fData.getMaxDuration(false)
        @fAvBackDuration = (minDuration.back + maxDuration.back)/2
        @fMinDur = Math.min(minDuration.hand, minDuration.back)
        @fMaxMinusMinDur = Math.max(1, Math.max(maxDuration.hand, maxDuration.back) - @fMinDur)

        @fPixelsPerMs = (@fWidthPerBell * @fData.getNBells() * @fZoomX) / @fAvBackDuration

        # Would really like to use the title font height in the calculation of fY0, since it must reserve space for the title.
        # However, fTitleFontHeight can only be determined once we get a Graphics object and hence a FontRenderContext.
        # These are only available in paintComponent(), not in other methods which might like to call measureUp(), e.g.
        # printing or repaint rectangle invalidation. The safest thing to do is to assume a fixed space for the title,
        # so it is set here to 20 pixels. If you make the title font bigger, this might not be enough!
        @fY0 = 20 + @fHeightPerRow + @fInsets.top
        @fRowRight = @fWidthPerBell * 2 + @fInsets.left + @fWidthPerBell * fData.getNBells()
        return true

    setupFonts: ->
        # Title font is never scaled by zoom
        @fTitleFont = '12px bold Arial'

        # Advanced-view fonts are scaled only slightly - same as X zoom ratio - and not less than 75%
        z = Math.max(0.75, @fZoomX)
        @fNormalAdvancedViewFont = "#{Math.round(12*z)}px Arial"
        @fNormalAdvancedViewFont = "#{Math.round(10*z)}px Arial"

        # Other fonts are scaled by a font factor between X (slight) and Y (actual zoom) ratios,
        # But note they are not usually displayed below a zoom ratio of 30%
        @fNormalBellFont = "#{Math.round(12*@fZoomFont)}px Arial"
        @fBoldBellFont = "#{Math.round(12*@fZoomFont)}px bold Arial"
        @fBigBellFont = "#{Math.round(16*@fZoomFont)}px Arial"

    paintComponent:  ->
        unless @measureUp() then return

        # @ctx = (Graphics2D)g;
        # Rectangle2D charSize = fNormalBellFont.getStringBounds("0", @ctx.getFontRenderContext());
        # fCharWidth = round(charSize.getWidth()/2);
        # Rectangle2D titleCharSize = fTitleFont.getStringBounds("0", @ctx.getFontRenderContext());
        # fTitleFontHeight = round(titleCharSize.getHeight());
        # Rectangle2D smallCharSize = fSmallAdvancedViewFont.getStringBounds("0", @ctx.getFontRenderContext());
        # fSmallFontHeight = round(smallCharSize.getHeight()*0.6);

        for i in [0...@fData.getNBells()]
            @fLastActualX[i] = -1
            @fLastCorrectX[i] = -1
        @fInChanges = false

        # Do column headings
        # if @fClip.y<=fY0)
        #    renderColumnHeadings();

        # First loop does background, annotations and lines.
        @ctx.setFont(fNormalBellFont);
        @ctx.setColor('rgb(0,0,0)')
        # firstRow = Math.max(0, getRowNumberFromYOrdinate(fClip.y)-1);
        firstRow = 0
        y = @fY0 + firstRow * @fHeightPerRow
        for i in [firstRow...@fData.getNRows()]
            r = @fData.getRow(i)
            if r?
                @calcEffectivePixelsPerMs(r)

                @fRowLeft = @fRowRight - Math.round(r.getRowDuration() * @fEffectivePixelsPerMs)
                @fInterbellGap = Math.round(r.getAveragedGap() * @fEffectivePixelsPerMs)

                # Draw row and duration backgrounds
                @drawRowBackground(y, r, i, if i>0 then @fData.getRow(i-1) else null)

                # Print row duration and interbell+handstroke gaps every ten rows
                @annotateRows(y, r, i)

                #Connect bells up with lines
                @drawLines(y, r)
            
            # if (y - @fHeightPerRow > fClip.y+fClip.height)
            #     break;
            y += @fHeightPerRow

        # Second loop does bell numbers, to ensure they overwrite lines.
        y = @fY0 + firstRow * @fHeightPerRow;
        for i in [firstRow...@fData.getNRows()]
            r = @fData.getRow(i)
            if r?
                @calcEffectivePixelsPerMs(r)
                @drawBellNumbers(y, r, i)
            
            # if (y - @fHeightPerRow > @fClip.y + @fClip.height)
            #     break
            y += @fHeightPerRow

    # renderColumnHeadings: ->
    #     @ctx.setFont(fTitleFont);
    #     @ctx.setColor(Color.blue);
    #     @ctx.drawString("Row", fInsets.left+1,  fInsets.top+fTitleFontHeight);
    #     @ctx.drawString("Striking Graph", fRowLeft+(fRowRight-fRowLeft)/2-20,  fInsets.top+fTitleFontHeight);
    #     @ctx.drawString("Row Length Graph", fRowRight+fInterbellGap+10,  fInsets.top+fTitleFontHeight);

    drawRowBackground: (y, row, rowNumber, prevRow) ->
        durPixels = Math.round((SPEED_WIDTH * @fZoomX * (row.getRowDuration() - @fMinDur)) / @fMaxMinusMinDur)
        rowBackground = @getRowColour(row, rowNumber)
        depress = rowNumber is @fPlaybackStartRow ? 1 : 0

        # Fill rectangle for row length, at right of display
        @paintRectangle(@fRowRight + @fInterbellGap + zoomX(10), y - @fHeightPerRow, durPixels, @fHeightPerRow, rowBackground, depress)
        # Fill rectangle for row itself - always a fixed, normalised length
        @paintRectangle(@fRowLeft + @fInterbellGap, y - @fHeightPerRow, @fRowRight - @fRowLeft, @fHeightPerRow, rowBackground, depress)

        # Draw marker for end of previous row - shows up if calculated row duration doesn't match difference
        # between row end times.
        if prevRow?
            rowStart = row.getRowEndTime() - row.getRowDuration()
            delta = rowStart - prevRow.getRowEndTime()
            if delta isnt 0
                h = Math.round(@fHeightPerRow * 0.25)
                delta *= @fEffectivePixelsPerMs
                if delta > 0
                    # Gap between end of last row and start of this row.
                    @paintRectangle(@fRowLeft + @fInterbellGap - delta, y - (h + @fHeightPerRow)/2, delta, h, rowBackground, depress*2)
                else
                    # Last row cuts into this one.
                    @paintRectangle(@fRowLeft + @fInterbellGap, y - (h + @fHeightPerRow)/2, -delta, h, @getBackground(), -depress)

    paintRectangle: (x, y, width, height, c, depressedBorder) ->
        @ctx.setColor(c);
        if depressedBorder is 0
            @ctx.fillRect(x, y, width, height)
        else if (depressedBorder > 0)
            ct6w.fillRect(x, y, width+1, height)
            if depressedBorder is 2
                width--
            @ctx.setColor('rgb(255,255,255)')
            @ctx.drawLine(x, y+height-1, x+width, y+height-1)
            @ctx.drawLine(x, y+height-2, x+width, y+height-2)
            if (depressedBorder < 2)
                @ctx.drawLine(x+width, y, x+width, y+height-1)
                @ctx.drawLine(x+width-1, y, x+width-1, y+height-1)
            @ctx.setColor('rgb(200,200,200)')
            if depressedBorder is 2
                width++
            ctw.drawLine(x, y, x+width, y)
            @ctx.drawLine(x, y, x, y+height-1)

        else if depressedBorder < 0
            width += 2
            height += 2
            @ctx.fillRect(x, y, width, height)
            y--
            @ctx.setColor('rgb(255,255,255)')
            @ctx.drawLine(x, y, x+width, y)
            @ctx.drawLine(x, y+1, x+width, y+1)
            @ctx.setColor('rgb(200,200,200)')
            @ctx.drawLine(x, y+height, x+width, y+height)
            @ctx.drawLine(x+width, y, x+width, y+height)

    annotateRows: (y, row, i) ->
        @ctx.setColor('rgb(0,0,0)')
        @ctx.setFont(@fNormalAdvancedViewFont)
        if (!row.isHandstroke())
            if (i % 10 is 9 or @fZoomY > MIN_ZOOM_TO_SHOW_BELLS)
                # Draw row number on every even (backstroke) row, or every tenth row for higher levels of zoom-out
                @ctx.fillString("#{i+1}", @fInsets.left,  y)
        # if (fAdvancedView && i%10==0)
        # {
        #     y-= fHeightPerRow/2;
        #     // Every tenth row, display row duration...
        #     int x = fRowRight+(fZoomY>MIN_ZOOM_TO_SHOW_BELLS? fInterbellGap+zoomX(20): SPEED_WIDTH);
        #     @ctx.drawString(""+row.getRowDuration()+"ms" , x, y+fTitleFontHeight/3);

        #     if (fZoomY>MIN_ZOOM_TO_SHOW_BELLS)
        #     {
        #         @ctx.setFont(fSmallAdvancedViewFont);
        #         // ...and handstroke gap.
        #         @ctx.drawString(""+(int)(row.getAveragedGap()*row.getHandstrokeGap()), fRowLeft, y);
        #         @ctx.drawString(" ms", fRowLeft, y+fSmallFontHeight);
        #         // ...and average gap...
        #         int xAG = fRowRight+fInterbellGap+zoomX(100);
        #         @ctx.drawString(""+(int)(row.getAveragedGap()), xAG, y);
        #         @ctx.drawString(" ms", xAG, y+fSmallFontHeight);
        #     }
        # }
        @ctx.setFont(@fNormalBellFont)

    drawLines: (y, row) ->
        # Loop over row - draw lines
        for j in [0...row.getRowSize()]
            @fThisActualX[j] = @strikeTimeToPixelX(row, row.getStrikeTime(j+1))
            @fThisCorrectX[j] = @strikeTimeToPixelX(row, row.getCorrectStrikeTime(j+1))

            b = row.getBellAt(j+1)
            if @fLastActualX[j] > 0
                if ((j & 1) is 1)
                    # For even bell position, draw straight "perfect" place line down the screen.
                    @ctx.setColor(LIGHT_GREY);
                    @ctx.drawLine(@fLastCorrectX[j], y-@fHeightPerRow*3/2, @fThisCorrectX[j], y-@fHeightPerRow/2)
                if (!@fInChangesOnly or @fInChanges)
                    if (b is @fHighlightedBell)
                        # For highlighted bell, draw blue line indicating perfect ringing position
                        @ctx.setColor(CORRECT_LINE_COLOUR);
                        @ctx.drawLine(@fLastCorrectX[@fLastPlace[b-1]], y-@fHeightPerRow*3/2, @fThisCorrectX[j], y-@fHeightPerRow/2)
                        @ctx.setColor(BLACK)
                    else
                        @ctx.setColor(GRID_COLOUR)
                    # Draw lines for each bell, joining up actual strike positions
                    @ctx.drawLine(@fLastActualX[@fLastPlace[b-1]], y-@fHeightPerRow*3/2, @fThisActualX[j], y-@fHeightPerRow/2)

        @fInChanges = row.isInChanges()
        # Loop over row - update previous bell x ordinates (actual and correct) for lines to next row.
        for j in [0...row.getRowSize()]
            b = row.getBellAt(j+1)
            @fLastPlace[b-1] = j
            @fLastActualX[j] = @fThisActualX[j]
            @fLastCorrectX[j] = @fThisCorrectX[j]


    drawBellNumbers: (y, row, rowNumber) ->
        y -= @zoomY(5)
        xOff = -@fCharWidth
        if rowNumber is @fPlaybackStartRow
            y++
            xOff++
        
        # Loop over row - draw bell numbers
        for j in [0...row.getRowSize()]
            b = row.getBellAt(j+1)
            x = strikeTimeToPixelX(row, row.getStrikeTime(j+1))
            s = cas.BELL_CHARS.substring(b-1, b)
            @ctx.setColor(BLACK)
            if (rowNumber is @fNowPlayingRow and b is @fNowPlayingBell)
                # If audio playing this bell, draw big bell number
                @ctx.setFont(@fBigBellFont)
                @ctx.fillString(s, x+xOff-1, y+1)
                @ctx.setFont(@fNormalBellFont)
            
            else if (@fZoomY > MIN_ZOOM_TO_SHOW_BELLS)
                if (row.getStrikeTime(j+1) is row.getCorrectStrikeTime(j+1))
                    # For bells in exactly the right place, draw bold bell number
                    @ctx.setFont(@fBoldBellFont)
                    @ctx.fillString(s, x+xOff, y)
                    @ctx.setFont(@fNormalBellFont)
                else
                    # Draw bell number
                    @ctx.fillString(s, x+xOff, y);

    calcEffectivePixelsPerMs: (row) ->
        if (row.isHandstroke())
            # fEffectivePixelsPerMs is the value needed to make this row the same pixel width as the average row (i.e. normalised width)
            @fEffectivePixelsPerMs = @fPixelsPerMs * @fAvBackDuration / (row.getRowDuration() - row.getAveragedGap() * row.getHandstrokeGap())
        else
            @fEffectivePixelsPerMs = @fPixelsPerMs * @fAvBackDuration / row.getRowDuration()

    strikeTimeToPixelX: (row, strikeTime) ->
        t = row.getRowEndTime() - strikeTime
        t *= @fEffectivePixelsPerMs
        return @fRowRight - t

    getRowColour: (row, rowNumber) ->
        rowBackground = null
        if (row.isHandstroke())
            if (row.isGood())
                rowBackground = BACKGROUND_HANDGOOD
            else if (row.isBad())
                rowBackground = BACKGROUND_HANDBAD
            else
                rowBackground =  BACKGROUND_HAND
        else
            if (row.isGood())
                rowBackground = BACKGROUND_BACKGOOD
            else if (row.isBad())
                rowBackground = BACKGROUND_BACKBAD
            else
                rowBackground =  BACKGROUND_BACK
        
       #  if (rowNumber is @fNowPlayingRow)
       #      float[] col = rowBackground.getRGBColorComponents(null);
       #      int best = 0;
       #      for (int i=1; i<3; i++)
       #          if (col[i]>=col[best])
       #              best = i;
       #      for (int i=0; i<3; i++)
       #          if (i==best)
       #              col[i] = Math.min(col[i]*1.2f, 1.0f);
       #          else
       #              col[i] = col[i]*0.9f;
       #      rowBackground = new Color(col[0], col[1], col[2]);
       #  /*
       #      float rowPlayingDarken = 0.8f/256;
       #  rowBackground = new Color(rowBackground.getRed()*rowPlayingDarken, rowBackground.getGreen()*rowPlayingDarken, rowBackground.getBlue()*rowPlayingDarken);
       # */
        # }
        return rowBackground;

    getPreferredSize: ->
        x = EXTRA_WIDTH + ROW_WIDTH + SPEED_WIDTH
        if (!@fRowsLoaded)
            return {x: x, y: 800}
        y = @fHeightPerRow * (@fData.getNRows()+2)
        return {x:x, y:y}