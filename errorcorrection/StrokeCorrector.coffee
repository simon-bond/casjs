
# An error corrector which attempts to assign correct handstroke/backstroke flags to each incoming row;
# it is necessary for Lowndes-format input files, which do not guarantee correct stroke information.
# The StrokeCorrector assumes that any "row overlaps" have been corrected, i.e. that the bongs are arriving
# in sets of rows, without any interleaving caused by, for example, a quick leading bell striking before the
# tenor in the previous row. This is done by the RowOverlapCorrector.
# <p>
# If we can assume rows are not interleaved, it is simple enough to detect the start of a new row: it is when
# we see a bell which has already rung in the previous row. We swap the stroke at this point.
# However, a complicating factor is the possibility of missing sensor bongs at the start of a row.
# Consider these two changes:
# <pre>
#    23456 H
#   123456 B
# </pre>
# Here the treble strike has been missed from the start of the first, handstroke, row. Unfortunately, this
# means that when the first treble bong does come through, the error corrector assumes that it must be
# at the end of the handstroke, not the start of the next backstroke. In fact there is no way, in the absence
# of other information, to come to any better conclusion. Hence, the job of sorting out these problems is
# left to a later corrector, the LeadLieCorrector.
#

class cas.StrokeCorrecter
    fBongs: new Array(cas.MAXNBELLS)

    constructor: (handstrokeStart) ->
        unless handstrokeStart? then handstrokeStart = true
        @fHandstrokeStart = handstrokeStart;
        @fStroke = if @fHandstrokeStart then cas.HANDSTROKE else cas.BACKSTROKE

    receiveBong: (bong) ->
        prevBong = @fBongs[bong.bell-1]
        if prevBong?
            @fStroke = -@fStroke
            for i in [0..@fBongs.length]
                @fBongs[i] = null

        @fBongs[bong.bell-1] = bong
        bong.stroke = @fStroke
        @fNextStage.receiveBong(bong)

    notifyInputComplete: ->
        @fNextStage.notifyInputComplete()

    setNextStage: (nextStage) ->
        @fNextStage = nextStage