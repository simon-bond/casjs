class window.cas.Bong

    cas.HANDSTROKE = -1
    cas.BACKSTROKE = +1
    cas.UNKNOWNSTROKE = 0

    constructor: (bell, time, stroke) ->
        @bell = bell
        @time = time
        @stroke = stroke


    # Returns the same Bong, with the stroke swapped.
    swapStroke: ->
        @stroke = -stroke
        return @this

    #Two Bongs are equal if they have the same bell - don't care about the timestamp.
    equals: (other) ->
        return @bell is other.bell

    compareTo: (other) ->
        if @time < other.time
            return -1
        if @time > other.time
            return +1
        return 0

    toString: ->
        return "#{@bell} #{@time} #{if @stroke is HANDSTROKE then 'H' else if @stroke is BACKSTROKE then 'B'}"

    @fromString: (s) ->
        i = s.indexOf(" ")
        if i < 0
            throw new Error "Bad bong: #{s}"
        b = s.substring(0, i).trim()
        t = s.substring(i+1).trim()
        stroke = cas.UNKNOWNSTROKE;
        j = s.indexOf(" ", i+1)
        if j > 0
            t = s.substring(i+1, j).trim();
            if (s.substring(j+1).equals("H"))
                stroke = cas.HANDSTROKE;
            else if (s.substring(j+1).equals("B"))
                stroke = cas.BACKSTROKE;
        return new cas.Bong(parseInt(b), parseInt(t), stroke)