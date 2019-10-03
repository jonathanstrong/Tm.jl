module parse

import Dates: DateTime
import TimeZones: TimeZones, TimeZone, timezone_names, @tz_str, astimezone
import TimesDates: TimeDateZone, TimeDate

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
    localized =
        if length(x) <= ISO_DT_LENGTH 
            TimeDateZone(DateTime(x), p.from)

        elseif endswith(x, "Z") || occursin(r"[\+-]\d{2}:\d{2}$", x)
            TimeDateZone(x)

        else
            try TimeDateZone(TimeDate(x), p.from)
            catch
                try
                    TimeDateZone(x)
                catch
                    error("failed to parse datetime string '$x'")
                end
            end
        end

    p.to === nothing && return localized

    astimezone(localized, p.to)
end


end # module
