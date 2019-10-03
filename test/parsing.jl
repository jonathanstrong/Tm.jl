using Test
using Tm
using Tm.parse
using TimeZones
using Dates
using TimesDates

import Dates: Nanosecond, Second, CompoundPeriod

@testset "parsing time zones" begin
    @test tz("utc") == TimeZone("UTC")
    @test tz("Etc/gmt+5") == TimeZone("Etc/GMT+5", TimeZones.Class(:ALL))
    @test tz(TimeZone("UTC")) == TimeZone("UTC")
    @test Tm.parse.UTC == TimeZone("UTC")
end

@testset "parsing string dates" begin
    p = TimeParser("us/eastern")

    @test p("2019-01-01") == TimeDateZone(DateTime("2019-01-01T00:00:00"), TimeZone("US/Eastern", TimeZones.Class(:ALL)))
end

@testset "parsing string datetimes with time zones" begin
    p = TimeParser("etc/gmt+5")

    s = "2019-01-23T04:56:22.123456789Z"
    @test p(s) == TimeDateZone(s)

    s = "2019-01-23T04:56:22.123456789"
    @test p(s) == TimeDateZone(TimeDate(s), p.from)

    s = "2019-01-23T04:56:22.123"
    @test p(s) == TimeDateZone(TimeDate(s), p.from)

    s = "2019-01-23T04:56:22"
    @test p(s) == TimeDateZone(TimeDate(s), p.from)

    s = "2019-01-23T04:56"
    @test p(s) == TimeDateZone(TimeDate(s), p.from)

    s = "2019-01-23T04:56:22.123456789-04:00"
    @test p(s) == TimeDateZone(s)
    @test TimesDates.utcoffset(p(s)) == TimesDates.utcoffset(TimeZones.now(tz("us/eastern")))

    # TODO - allow flexibility here
    #
    # s = "2019-01-23T04:56:22.123456789-0400"
    # @test p(s) == TimeDateZone(s)
    # @test TimesDates.utcoffset(p(s)) == TimesDates.utcoffset(TimeZones.now(tz("us/eastern")))

    # s = "2019-01-23 04:56:22.123456789-04:00"
    # @test p(s) == TimeDateZone(s)
    # @test TimesDates.utcoffset(p(s)) == TimesDates.utcoffset(TimeZones.now(tz("us/eastern")))
end

@testset "using from and to to localize/convert" begin
    p = TimeParser("us/central", "utc")

    s = "2019-01-23T04:56:22.123456789Z"
    @test p(s) == TimeDateZone(s)
    @test TimesDates.utcoffset(p(s)) == Second(0)
    @test p(s) == TimeDateZone(DateTime(2019, 1, 23, 4, 56, 22), tz("utc")) + Nanosecond(123456789) 

    s = "2019-01-23T04:56:22.123456789-04:00"
    @test p(s) == TimeDateZone(s)
    @test TimesDates.utcoffset(p(s)) == Second(0)
    @test p(s) == astimezone(TimeDateZone(s), tz("utc"))
    @test p(s) == astimezone(TimeDateZone(TimeDate(2019, 1, 23, 4, 56, 22, 0, 0, 123456789), tz("us/eastern")), tz("utc"))

    s = "2019-01-23T04:56:22.123456789"
    @test p(s) == TimeDateZone(s)
    @test TimesDates.utcoffset(p(s)) == Second(0)
    @test p(s) == astimezone(TimeDateZone(DateTime(2019, 1, 23, 4, 56, 22), p.from) + Nanosecond(123456789), tz("utc")) 
end
