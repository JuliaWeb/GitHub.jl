correct_jwt = replace("""
eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.
eyJleHAiOjE0NzM5NDgwNjAsImlhdCI6MTQ3Mzk0ODAwMCwiaXNzIjoxMjM0fQ.
uDZWWptpvEy4Dv1h_jHcqqROzs2HpE_XMcSfNWhpCuLNwnVPWUVoTYqiCPbNdO7
PgsuTMhtuF4PQN0bJdz7_Bnn0UqmHZ-P1ktFeMBT7IvfEBolIVLMTa2LJQC6UG7
_qCoY2kjLdriWiLFHznJvG6jfPHK-iX9VIolNjkiM9e4DG9Aq60UnZ_df40wZXd
696sRpgCakvIV3mQTmRv9IfOLVF9eRRD4yVvwTtYNGOqewpQqkPnm6K3ctYlQIX
kwKMynp6R-CgbwRedA4n0WAvy1o14TyZZ-QAChQUcS-OKb0ZM4z-fbG5ZSpWP7f
wsQxsZgWFIz6hodiw_q45bHYsLw
""",'\n' => "")
# Fix iat, to make sure the payload is reproducible
auth = GitHub.JWTAuth(1234, joinpath(dirname(@__FILE__), "not_a_real_key.pem");
    iat = DateTime("2016-9-15T14:00"))
key = MbedTLS.PKContext()
MbedTLS.parse_key!(key,
    read(joinpath(dirname(@__FILE__), "not_a_real_key.pem"), String))
auth = GitHub.JWTAuth(1234, joinpath(dirname(@__FILE__), "not_a_real_key.pem");
    iat = DateTime("2016-9-15T14:00"))
auth2 = GitHub.JWTAuth(1234, key; iat = DateTime("2016-9-15T14:00"))
# The validity of this token can be checked with jwt.io. This is just a smoke
# test to make sure things don't break.
@test auth.JWT == correct_jwt
@test auth2.JWT == correct_jwt
