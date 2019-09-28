using Tm
using Test

import Dates: Nanosecond, Second, CompoundPeriod


@testset "duration sanity checks" begin

    @test Nanosecond(1) > Second(0)
    @test Nanosecond(1_000_000_001) > Second(1)

end

@testset "timespec comparisons" begin
    using Tm.clock

    a = timespec(1, 0)
    b = timespec(0, 999_999_999)
    c = timespec(0, 999_999_999)
    d = timespec(2, 0)

    @test a > b
    @test a >= b
    @test !(a < b)
    @test !(a <= b)
    @test b >= c
    @test c >= b
    @test b <= c
    @test c <= b
    @test a < d
end

@testset "duration arithmetic using a timespec" begin
    using Tm.clock
    import TimesDates: TimeDateZone

    tx = system_time()
    diff = tx - tx
    @test tx.nsec <= 1_000_000_000
    @test tx - tx == 0
    @test CompoundPeriod(tx) == Nanosecond(tx)
    @test TimeDateZone(tx) > TimeDateZone("2019-01-01T00:00:00Z")
end

@testset "monotonic clock" begin
    using Tm.clock
    t1 = monotonic_time()
    nanosleep(1_000_000)
    t2 = monotonic_time()
    @test t2 > t1
    @test t2 - t1 < 100_000_000
end

@testset "parsing time zones" begin
    using Tm.parse
    using TimeZones

    @test tz("utc") == TimeZone("UTC")
    @test tz("Etc/gmt+5") == TimeZone("Etc/GMT+5", TimeZones.Class(:ALL))
    @test tz(TimeZone("UTC")) == TimeZone("UTC")
    @test Tm.parse.UTC == TimeZone("UTC")
end

@testset "parsing string dates" begin
    using Tm.parse
    using TimeZones
    using Dates
    using TimesDates

    p = TimeParser("us/eastern")

    @test p("2019-01-01") == TimeDateZone(DateTime("2019-01-01T00:00:00"), TimeZone("US/Eastern", TimeZones.Class(:ALL)))
end
