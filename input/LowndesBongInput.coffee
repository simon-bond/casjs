class cas.LowndesBongInput extends cas.BongInputHelper

    @fTimesHeardTreble = 0
    @fSeenFirstBong = false

    constructor: (filename) ->
        super(filename)
        @fLastTime = 0
        @fHighTime = 0

    getErrorCorrecters: ->
        errorCorrectors = []
        # Lownes data is typically coming either from unreliable light sensors on the bells, or equally unreliable
        # "Hawkear" audio analysis. In either case, we probably don't have handstroke/backstroke data, and there
        # may be sensor artifacts and erros we need to clean up. To deal with these problems, we add lots of
        # error conversion layers, as follows:
        # First, remove any sensor echoes - basically, double strikes of bells.
        errorCorrectors.push(new cas.SensorEchoCorrecter());
        # We can still have rogue extra strikes of bells in the middle of the change; try and get rid of these next.
        errorCorrectors.push(new cas.ExtraneousStrikeCorrector());
        # Up to now the data has been in time-sorted order, however now we attempt to correct "row overlaps", where
        # one bell has struck so late it is in the next change, or vice versa. We want the bells in the same row
        # all together, even if this breaks strike time order.
        errorCorrectors.push(new cas.RowOverlapCorrector())
        # Finally we can look at assigning correct hand/back flags.
        errorCorrectors.push(new cas.StrokeCorrecter())
        # But do a final pass to cope with missing or misaligned data, causing a bell to be treated as ringing at the end
        # of a row when it should have been at the other stroke at the start of the next. This also tries to deal with
        # recording where we come in halfway through a change.
        #errorCorrectors.push(new cas.LeadLieCorrector())
        return errorCorrectors

    processLine: (line) ->
        if line.length isnt 10
            throw new Error("Format error in Lowndes file - line unexpected length: "+line)
            return

        # Although Lowndes files contain a handstroke indicator, in fact they provide no indication of stroke,
        # since the data has generally come from audio transcription where the stroke is not discernable.
        # Hence, although we read and check the information, we do not currently use it in the creation of the Bong.
        stroke = @readStrokeCharacter(line.charAt(0))

        b = @readBellCharacter(line.charAt(2))
        if b <= 0 then return
        if b > @fNBells then @fNBells = b

        t = parseInt(line.substring(6,10), 16)
        if isNaN(t)
            throw new Error("Format error in Lowndes file - bad hex time: "+line)
            return

        if t < @fLastTime
            @fHighTime += 0x10000
        @fLastTime = t;

        bong = new cas.Bong(b, t + @fHighTime, cas.UNKNOWNSTROKE)
        @fInputListener.receiveBong(bong)
        @fSeenFirstBong = true