import time
from flask import Flask, jsonify, make_response, request

app = Flask(__name__)


def calculate_pi(iterations: int = 1_000_000) -> float:
    pi = 0.0
    sign = 1.0
    for i in range(iterations):
        pi += sign / (2 * i + 1)
        sign *= -1.0
    return 4.0 * pi


@app.get("/")
def root():
    user_agent = request.headers.get("User-Agent", "").lower()
    if "curl" in user_agent:
        return make_response(
            jsonify(error="curl is not allowed for this endpoint"),
            403,
        )

    start = time.perf_counter()
    pi_value = calculate_pi()
    duration = time.perf_counter() - start

    response = make_response(
        jsonify(
            message="Welcome to the backend service",
            pi=pi_value,
            calculation_time_seconds=duration,
        )
    )

    response.headers["X-HEADER-ADD"] = "Heres is how we could add EXTRA headers"

    return response


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)