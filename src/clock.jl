module clock

@assert Base.Sys.WORD_SIZE == 64 "unsupported architecture"

using TimesDates, TimeZones, Dates

import Base: +, -, >, >=, <, <=
import Dates: Nanosecond, CompoundPeriod

export nanosleep, system_time, monotonic_time, now, timespec 

const BILLION               = 1_000_000_000
const UTC                   = tz"UTC"
const EPOCH                 = TimeDateZone("1970-01-01T00:00:00Z")

const clockid_t             = Int32
const time_t                = Int64

@enum Clock begin
    Realtime  = 0
    Monotonic = 1
end

mutable struct timespec
    sec  :: time_t
    nsec :: Int64
end

Nanosecond(tx::timespec)        = Nanosecond(Int64(tx.sec) * Int64(BILLION) + Int64(tx.nsec))

CompoundPeriod(tx::timespec)    = Second(tx.sec) + Nanosecond(tx.nsec)

TimeDateZone(tx::timespec)      = EPOCH + CompoundPeriod(tx)

Int64(tx::timespec)             = nanos(tx)

for cmp in (:>, :>=, :<, :<=)
    @eval begin
        function $cmp(a::timespec, b::timespec)
            normalize!(a)
            normalize!(b)
            $cmp((a.sec, a.nsec), (b.sec, b.nsec))
        end
    end
end

@inline function nanos(tx::timespec)
    Int64(tx.secs) * Int64(BILLION) + Int64(tx.nsec)
end

@inline function normalize!(t::timespec)
    t.nsec < BILLION && return t
    ss, ns = divrem(t.nsec, BILLION)
    t.sec += ss
    t.nsec = ns
    nothing
end

function -(t1::timespec, t2::timespec)
    if t1.sec < 0 || t1.nsec < 0 || t2.sec < 0 || t2.nsec < 0
        error("Subtracting timespec is only defined for positive time values")
    end
    # find the larger time value
    if t1.sec - t2.sec > 0
        tend = t1; tbegin = t2; dsign = +1
    elseif t1.sec - t2.sec < 0
        tend = t2; tbegin = t1; dsign = -1
    else # t1.sec == t2.sec
        if t1.nsec > t2.nsec
            tend = t1; tbegin = t2; dsign=+1
        elseif t1.nsec < t2.nsec
            tend = t2; tbegin = t1; dsign=-1
        else # a tie!
            tend = t1; tbegin = t2; dsign=+1
        end
    end
    dnsec = tend.nsec - tbegin.nsec
    dsec = tend.sec - tbegin.sec
    dnsec < 0 && (dnsec += BILLION; dsec -= 1)
    d::Int64 = dsign * (dnsec + BILLION * dsec)
    d
end

module TIMER_FLAG
  const RELTIME = Val{0}
  const ABSTIME = Val{1}
end

function system_time()
    tx = timespec(0, 0)
    clock_gettime!(tx, Realtime)
    tx
end

function now()
    TimeDateZone(system_time())
end

function monotonic_time()
    tx = timespec(0, 0)
    clock_gettime!(tx, Monotonic)
    tx
end


function clock_gettime!(tx::timespec, clockid::Clock)

    s = ccall(
        (:clock_gettime, "librt"),
        Int32,
        (clockid_t, Ptr{timespec}),
        clockid,
        pointer_from_objref(tx)
    )

    s != 0 && error("Error in gettime() (code = $s)")

    nothing
end

function clock_nanosleep(clockid::Clock, tx::timespec, ::Type{TIMER_FLAG.ABSTIME})
    f = pointer_from_objref(tx) # hack, to avoid unnecessary memory allocation

    s = ccall(
        (:clock_nanosleep, "librt"),
        Int32,
        (clockid_t, Int32, Ptr{timespec}, Ptr{timespec}),
        clockid, 1, f, f
    )

    s != 0 && error("Error in nanosleep() (code = $s, tx = $tx)")

    nothing
end

clock_nanosleep(clockid::Clock, t::timespec) = clock_nanosleep(clockid, t, TIMER_FLAG.ABSTIME)

#function nanosleep(clockid::Clock, t::timespec, ::Type{TIMER_FLAG.RELTIME})
#  error("Relative time nanosleep not supported yet!")
#  return nothing
#end

@inline function nanosleep(n::Int64)
    tx = monotonic_time()
    tx.nsec += n
    normalize!(tx)
    clock_nanosleep(Monotonic, tx)
    nothing
end

#nanosleep!(tx::timespec,nanosec::Int64) = nanosleep!(tx,nanosec,Monotonic)

end # module
