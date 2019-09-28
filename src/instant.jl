module instant

using clock

import Dates: Nanosecond, CompoundPeriod

struct Instant
    tx :: timespec
end

Instant() = Instant(monotonic_time())

function -(a::Instant, b::Instant)
    Nanosecond(a.tx - b.tx)
end

end # module

