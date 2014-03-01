
# Interface -------

function contributors(owner, repo, attempts = 3; auth = AnonymousAuth(), options...)
    contributors(auth, owner, repo, attempts; options...)
end

function contributors(auth::Authorization, owner, repo, attempts = 3; headers = Dict(), options...)
    r = attempt_stats_request(auth, owner, repo, "contributors", attempts; headers = headers, options...)

    data = JSON.parse(r.data)
    map!(data) do udata
        udata["author"] = User(udata["author"])
        udata
    end
end


function commit_activity(owner, repo, attempts = 3; auth = AnonymousAuth(), options...)
    commit_activity(auth, owner, repo, attempts; options...)
end

function commit_activity(auth::Authorization, owner, repo, attempts = 3; headers = Dict(), options...)
    r = attempt_stats_request(auth, owner, repo, "commit_activity", attempts; headers = headers, options...)
    JSON.parse(r.data)
end


function code_frequency(owner, repo, attempts = 3; auth = AnonymousAuth(), options...)
    code_frequency(auth, owner, repo, attempts; options...)
end

function code_frequency(auth::Authorization, owner, repo, attempts = 3; headers = Dict(), options...)
    r = attempt_stats_request(auth, owner, repo, "code_frequency", attempts; headers = headers, options...)
    JSON.parse(r.data)
end


function participation(owner, repo, attempts = 3; auth = AnonymousAuth(), options...)
    participation(auth, owner, repo, attempts; options...)
end

function participation(auth::Authorization, owner, repo, attempts = 3; headers = Dict(), options...)
    r = attempt_stats_request(auth, owner, repo, "participation", attempts; headers = headers, options...)
    JSON.parse(r.data)
end


function punch_card(owner, repo, attempts = 3; auth = AnonymousAuth(), options...)
    punch_card(auth, owner, repo, attempts; options...)
end

function punch_card(auth::Authorization, owner, repo, attempts = 3; headers = Dict(), options...)
    r = attempt_stats_request(auth, owner, repo, "punch_card", attempts; headers = headers, options...)
    JSON.parse(r.data)
end


# Utility -------

function attempt_stats_request(auth, owner, repo, stat, attempts; headers = Dict(), options...)
    authenticate_headers(headers, auth)

    for a in attempts:-1:0
        r = get(URI(API_ENDPOINT; path = "/repos/$owner/$repo/stats/$stat");
                headers = headers,
                options...)

        handle_error(r)

        if r.status == 200
            return r
        end

        sleep(2.0)
    end

    throw(StatsError("Unsuccessfully attempted to retrieve $stat $attempts times."))
end
