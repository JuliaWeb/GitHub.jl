using Test
using HTTP
using GitHub

primary_rate_limit_body = Vector{UInt8}("primary rate limit")
secondary_rate_limit_body = Vector{UInt8}("secondary rate limit")

@testset "github_retry_decision" begin

    @testset "HTTP.jl recoverable exceptions" begin
        # Test with a potentially recoverable exception (let HTTP.jl decide)
        # We'll just test that our function handles exceptions without crashing
        network_ex = Base.IOError("connection reset", 104)
        should_retry, sleep_seconds = GitHub.github_retry_decision("GET", nothing, network_ex, 2.0; verbose=false)
        # The actual retry decision depends on HTTP.jl's isrecoverable and isidempotent functions
        @test typeof(should_retry) == Bool
        @test sleep_seconds >= 0.0

        # Test with non-recoverable exception
        non_recoverable_ex = ArgumentError("invalid argument")
        should_retry, sleep_seconds = GitHub.github_retry_decision("GET", nothing, non_recoverable_ex, 2.0; verbose=false)
        @test should_retry == false
        @test sleep_seconds == 0.0
    end

    @testset "No response and no exception" begin
        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",nothing, nothing, 2.0; verbose=false)
        @test should_retry == false
        @test sleep_seconds == 0.0
    end

    @testset "Successful responses" begin
        for status in [200, 201, 204]
            resp = HTTP.Response(status)
            should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp, nothing, 2.0; verbose=false)
            @test should_retry == false
            @test sleep_seconds == 0.0
        end
    end

    @testset "Primary rate limit - x-ratelimit-remaining = 0" begin

        # Test with future reset time - use fixed timestamp to avoid race conditions
        future_time = "1900000000"  # Fixed timestamp in the future (year 2030)
        resp = HTTP.Response(403, [
            "x-ratelimit-remaining" => "0",
            "x-ratelimit-reset" => future_time
        ], primary_rate_limit_body)

        should_retry, sleep_seconds = GitHub.github_retry_decision("GET", resp, nothing, 2.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds > 100000  # Should be a large delay since reset time is far in future

        # Test with past reset time (should use exponential backoff)
        past_time = "1000000000"  # Fixed timestamp in the past (year 2001)
        resp2 = HTTP.Response(403, [
            "x-ratelimit-remaining" => "0",
            "x-ratelimit-reset" => past_time
        ], primary_rate_limit_body)

        should_retry, sleep_seconds = GitHub.github_retry_decision("GET", resp2, nothing, 5.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds == 5.0  # Should use the exponential delay
    end

    @testset "Secondary rate limit - retry-after header" begin

        # Test secondary rate limit with retry-after
        resp = HTTP.Response(429, ["retry-after" => "30"]; body = secondary_rate_limit_body)

        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp, nothing, 2.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds == 30.0  # Should use retry-after value

        # Test with just retry-after header (no body message)
        resp2 = HTTP.Response(429, ["retry-after" => "15"])
        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp2, nothing, 2.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds == 15.0
    end

    @testset "Secondary rate limit - no headers" begin
        resp = HTTP.Response(429; body = secondary_rate_limit_body)

        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp, nothing, 2.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds == 60.0  # Should wait at least 1 minute

        # Test with exponential delay greater than 60 seconds
        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp, nothing, 120.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds == 120.0  # Should use the larger exponential delay
    end

    @testset "Secondary rate limit - x-ratelimit-remaining = 0" begin

        # Test secondary rate limit with reset time - use fixed timestamp to avoid race conditions
        future_time = "1900000000"  # Fixed timestamp in the future (year 2030)
        resp = HTTP.Response(403, [
            "x-ratelimit-remaining" => "0",
            "x-ratelimit-reset" => future_time
        ], secondary_rate_limit_body)

        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp, nothing, 5.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds > 100000  # Should be a large delay since reset time is far in future
    end

    @testset "429 - exponential backoff" begin
        # 429 without specific headers or body
        resp = HTTP.Response(429, [])

        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp, nothing, 4.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds == 4.0  # Should use exponential delay

        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp, nothing, 8.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds == 8.0
    end

    @testset "Other HTTP errors" begin
        for status in [408, 409, 500, 502, 503, 504, 599]
            resp = HTTP.Response(status, [])

            should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp, nothing, 3.0; verbose=false)
            @test should_retry == true
            @test sleep_seconds == 3.0  # Should use exponential delay
        end
    end

    @testset "Non-retryable client errors" begin
        for status in [400, 401, 403, 404, 422]
            resp = HTTP.Response(status, [])
            should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp, nothing, 1.0; verbose=false)
            @test should_retry == false
            @test sleep_seconds == 0.0
        end
    end

    @testset "Invalid header values" begin
        # Test with invalid retry-after header (should use secondary rate limit minimum)
        resp1 = HTTP.Response(429, ["retry-after" => "invalid"], secondary_rate_limit_body)
        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp1, nothing, 2.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds == 60.0  # Falls back to secondary rate limit minimum (1 minute)

        # Test with invalid reset time (should fall back to secondary min)
        resp2 = HTTP.Response(403, [
            "x-ratelimit-remaining" => "0",
            "x-ratelimit-reset" => "invalid"
        ], secondary_rate_limit_body)
        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp2, nothing, 3.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds == 60.0  # minimum for secondary rate limit
    end

    @testset "Rate limit header precedence" begin
        # retry-after should take precedence over x-ratelimit-reset
        future_time = "1900000000"  # Fixed timestamp (doesn't matter since retry-after takes precedence)
        resp = HTTP.Response(429, [
            "retry-after" => "5",
            "x-ratelimit-remaining" => "0",
            "x-ratelimit-reset" => future_time
        ])

        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp, nothing, 10.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds == 5.0  # Should use retry-after, not reset time
    end

    @testset "Rate limit remaining non-zero" begin

        # Should use exponential backoff when x-ratelimit-remaining is not "0"
        future_time = "1900000000"  # Fixed timestamp (doesn't matter since remaining != "0")
        resp = HTTP.Response(403, [
            "x-ratelimit-remaining" => "5",
            "x-ratelimit-reset" => future_time
        ], primary_rate_limit_body)

        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp, nothing, 3.0; verbose=false)
        @test should_retry == true
        @test sleep_seconds == 3.0  # Should use exponential backoff, not reset time
    end

    @testset "Exception with successful response" begin

        # If we have both an exception and a response, the response should take precedence
        resp = HTTP.Response(200)
        ex = Base.IOError("some error", 0)

        should_retry, sleep_seconds = GitHub.github_retry_decision("GET",resp, ex, 2.0; verbose=false)
        @test should_retry == false  # Success response should not retry
        @test sleep_seconds == 0.0
    end

    @testset "Request method considerations" begin
        # Test with different HTTP methods to ensure retryable logic works

        # Network exception with different methods
        network_ex = Base.IOError("connection refused", 111)

        # Test that both work without crashing (actual retry depends on HTTP.jl internals)
        should_retry, sleep_seconds = GitHub.github_retry_decision("GET", nothing, network_ex, 1.0; verbose=false)
        @test typeof(should_retry) == Bool
        @test sleep_seconds >= 0.0

        # POST behavior depends on HTTP.jl's isidempotent() function (non-idempotent methods typically don't retry)
        should_retry, sleep_seconds = GitHub.github_retry_decision("POST", nothing, network_ex, 1.0; verbose=false)
        @test typeof(should_retry) == Bool
        @test sleep_seconds >= 0.0
    end
end


@testset "with_retries function tests" begin
    @testset "Success after retries" begin
        call_count = Ref(0)
        sleep_calls = Float64[]

        # Custom sleep function that records sleep durations
        function test_sleep(seconds)
            push!(sleep_calls, seconds)
        end

        result = GitHub.with_retries(method="GET", max_retries=2, verbose=false, sleep_fn=test_sleep) do
            call_count[] += 1
            if call_count[] < 3
                # Return a rate limit response for first 2 attempts
                return HTTP.Response(429, ["retry-after" => "1"])
            else
                # Success on 3rd attempt
                return HTTP.Response(200)
            end
        end

        @test result.status == 200
        @test call_count[] ==3
        @test length(sleep_calls) == 2  # Should have slept twice
        @test all(s -> s >= 1.0, sleep_calls)  # Should respect retry-after
    end

    @testset "Exception handling" begin
        call_count = Ref(0)
        sleep_calls = Float64[]

        function test_sleep(seconds)
            push!(sleep_calls, seconds)
        end

        # Test with recoverable exception (for GET method)
        result = GitHub.with_retries(method="GET", max_retries=2, verbose=false, sleep_fn=test_sleep) do
            call_count[] += 1
            if call_count[] < 3
                throw(Base.IOError("connection refused", 111))
            else
                return HTTP.Response(200)
            end
        end

        @test result.status == 200
        @test call_count[] ==3
        @test length(sleep_calls) == 2
    end

    @testset "Non-retryable exceptions" begin
        # Test that ArgumentError is not retried
        @test_throws ArgumentError GitHub.with_retries(method="GET", verbose=false) do
            throw(ArgumentError("invalid argument"))
        end
    end

    @testset "Max retries exhausted" begin
        call_count = Ref(0)
        sleep_calls = Float64[]

        function test_sleep(seconds)
            push!(sleep_calls, seconds)
        end

        # Test exhausting retries with rate limit responses
        result = GitHub.with_retries(method="GET", max_retries=2, verbose=false, sleep_fn=test_sleep) do
            call_count[] += 1
            return HTTP.Response(429, ["retry-after" => "0.1"])  # Always return rate limit
        end

        @test result.status == 429  # Should return the final failed response
        @test call_count[] ==3  # Initial + 2 retries
        @test length(sleep_calls) == 2
    end

    @testset "Max retries exhausted with exception" begin
        call_count = Ref(0)

        # Test exhausting retries with exceptions
        @test_throws Base.IOError GitHub.with_retries(method="GET", max_retries=1, verbose=false, sleep_fn=x->nothing) do
            call_count[] += 1
            throw(Base.IOError("persistent error", 104))
        end

        @test call_count[] ==2  # Initial + 1 retry
    end

    @testset "Non-idempotent methods" begin
        call_count = Ref(0)

        # POST requests should not retry on exceptions (non-idempotent)
        @test_throws Base.IOError GitHub.with_retries(method="POST", verbose=false) do
            call_count[] += 1
            throw(Base.IOError("connection refused", 111))
        end

        @test call_count[] ==1  # Should not retry
    end

    @testset "GitHub rate limit handling" begin
        call_count = Ref(0)
        sleep_calls = Float64[]

        function test_sleep(seconds)
            push!(sleep_calls, seconds)
        end

        # Test primary rate limit with reset time
        current_time = time()
        reset_time = string(Int(round(current_time)) + 500000000)  # 500000000 seconds from now

        result = GitHub.with_retries(method="GET", max_retries=1, verbose=false, sleep_fn=test_sleep, max_sleep_seconds=2*500000000) do
            call_count[] += 1
            if call_count[] == 1
                return HTTP.Response(403, [
                    "x-ratelimit-remaining" => "0",
                    "x-ratelimit-reset" => reset_time
                ], primary_rate_limit_body)
            else
                return HTTP.Response(200)
            end
        end

        @test result.status == 200
        @test call_count[] ==2
        @test length(sleep_calls) == 1
        @test sleep_calls[1] >= 500000000  # Should wait at least until reset time


        @test_throws RetryDelayException GitHub.with_retries(method="GET", max_retries=1, verbose=false, sleep_fn=test_sleep) do
            return HTTP.Response(403, [
                "x-ratelimit-remaining" => "0",
                "x-ratelimit-reset" => reset_time
            ], primary_rate_limit_body)
        end
    end

    @testset "Secondary rate limit with retry-after" begin
        call_count = Ref(0)
        sleep_calls = Float64[]

        function test_sleep(seconds)
            push!(sleep_calls, seconds)
        end

        body = """{"message": "You have exceeded a secondary rate limit."}"""

        result = GitHub.with_retries(method="GET", max_retries=1, verbose=false, sleep_fn=test_sleep) do
            call_count[] += 1
            if call_count[] == 1
                return HTTP.Response(429, ["retry-after" => "3"]; body = Vector{UInt8}(body))
            else
                return HTTP.Response(200)
            end
        end

        @test result.status == 200
        @test call_count[] == 2
        @test length(sleep_calls) == 1
        @test sleep_calls[1] == 3.0  # Should respect retry-after exactly
    end

    @testset "Non-retryable HTTP errors" begin
        call_count = Ref(0)

        # 404 should not be retried
        result = GitHub.with_retries(method="GET", verbose=false) do
            call_count[] += 1
            return HTTP.Response(404)
        end

        @test result.status == 404
        @test call_count[] ==1  # Should not retry
    end

    @testset "Zero max_retries" begin
        call_count = Ref(0)

        # With max_retries=0, should only try once
        result = GitHub.with_retries(method="GET", max_retries=0, verbose=false) do
            call_count[] += 1
            return HTTP.Response(429)  # Rate limit response
        end

        @test result.status == 429
        @test call_count[] ==1  # Should not retry at all
    end

    @testset "Sleep function not called on success" begin
        sleep_called = Ref(false)

        function test_sleep(seconds)
            sleep_called[] = true
        end

        result = GitHub.with_retries(method="GET", verbose=false, sleep_fn=test_sleep) do
            return HTTP.Response(200)
        end

        @test result.status == 200
        @test !sleep_called[]
    end

end
