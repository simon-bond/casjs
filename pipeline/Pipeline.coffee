class Pipeline
    @fNRowsAvailable = 0
    @fAllRowsRung = false

    constructor: (inputStage) ->
        @fInputStage = inputStage

    getNBells: -> return @fRowAccumulator.getNBells()


    # Start the pipeline running.
    # An input stage will have been plugged in already (via the Pipeline constructor) so this is started,
    # causing it to begin to deliver Bongs to the error correction stage.
    # Visualiser and UI stages do not need to be plugged in yet - but they will start receiving pipeline
    # events as soon as they are.

    # Java CAS does this on a separate thread, but we only have one...

    start: ->
        # Set up the error correctors and row accumulator stage.
        @fErrorCorrectors = fInputStage.getErrorCorrecters()
        @fRowAccumulator = new RowAccumulator(this)
        if (not @fErrorCorrectors? or @fErrorCorrectors.size() is 0)
            @fFirstErrorCorrecter = @fRowAccumulator
        else
            # Chain error correctors together
            errorCorrecter = @fErrorCorrectors[0]
            @fFirstErrorCorrecter = errorCorrecter
            for i in [1...@fErrorCorrectors.length]
                nextCorrecter = @fErrorCorrectors[i]
                errorCorrecter.setNextStage(nextCorrecter)
                errorCorrecter = nextCorrecter

            errorCorrecter.setNextStage(@fRowAccumulator);

        # The pipeline is started by starting the input stage.
        @fInputStage.startLoad(this)


    # First stage: receive Bongs (and possibly errors) from the StrikingDataInput.
    receiveBong: (bong) -> @fFirstErrorCorrecter.receiveBong(bong)

    notifyInputComplete: -> @fFirstErrorCorrecter.notifyInputComplete()

    notifyInputError: (msg) ->
        console.error("Input failed: "+msg)
        @fUI.notifyInputError(msg) if @fUI?

    # Second stage: receive error-corrected Rows, pass on to the visualiser (if present)
    rowsAvailable: (nrows) ->
        @fNRowsAvailable = nrows
        @rowSource = getRowSource(nrows)
        @fCurrentVisualiser.newRowsAvailable(rowSource) if @fCurrentVisualiser?

    #Returns null if input not yet finished.
    getRawTouchData: ->
        if @fAllRowsRung then return @getRowSource(@fNRowsAvailable)
        return null

    getRowSource: (nrows) ->
        return {
            getNRows: -> return nrows

            getRow: (i) -> return @fRowAccumulator.getRow(i)

            getNBells: -> return if @fRowAccumulator? then @fRowAccumulator.getNBells() else 0
        }

    # Final stage: pass averaged row data to the ui
    notifyLastRowRung: ->
        @fAllRowsRung = true
        @fCurrentVisualiser.notifyLastRowRung() if @fCurrentVisualiser?

    setVisualiser: (visualiser) ->
        visualiser.setAnalysisListener(this)

        @fCurrentVisualiser = visualiser
        existingVisualiserData = @fCurrentVisualiser.getAveragedTouchData()

        if (existingVisualiserData.getNRows() > 0)
            fUI?.loadRows(existingVisualiserData)

        rowSource = @getRowSource(@fNRowsAvailable)
        @fCurrentVisualiser.newRowsAvailable(rowSource)

        if @fAllRowsRung
            @fCurrentVisualiser.notifyLastRowRung()

    setUI: (ui) -> @fUI = ui

    newAveragedRowAvailable: ->
        @fUI.loadRows(@fCurrentVisualiser.getAveragedTouchData());

    # Should be called by visualisers when they have sent us the last row.
    analysisComplete: -> @fUI.visualisationComplete()