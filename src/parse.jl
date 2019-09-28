module parse

import Dates: DateTime
import TimeZones: TimeZones, TimeZone, timezone_names, @tz_str
import TimesDates: TimeDateZone

export tz, TimeParser

const ISO_DT_LENGTH     = 10 # i.e. length("2019-01-01")
const TZ_NAMES          = Dict(map(x -> (lowercase(x), x), timezone_names()))
const UTC               = tz"UTC"

struct TimeParser
    from :: TimeZone
    to   :: Union{TimeZone, Nothing}
end

tz(x::String)                               = TimeZone(TZ_NAMES[lowercase(x)], TimeZones.Class(:ALL))
tz(x::TimeZone)                             = x

TimeParser(from::String)                    = TimeParser(tz(from), nothing)
TimeParser(from::String, to::Nothing)       = TimeParser(tz(from), to)
TimeParser(from::String, to::String)        = TimeParser(tz(from), tz(to))

function (p::TimeParser)(x::String)
    if length(x) <= ISO_DT_LENGTH
        return TimeDateZone(DateTime(x), p.from)
    else
        error("uh oh")
    end
end


end # module
