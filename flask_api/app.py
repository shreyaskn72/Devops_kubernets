from flask import Flask, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route("/")
def hello():
    return {"message": "Good morning from Shreyas K N! Welcome"}


@app.route('/greeting')
def greeting():
    data = request.args
    name = data.get('Name')
    city = data.get('City')
    if not name or not city:
        return {
            "Message": "Name and City fields are required"
        }, 403
    return {
        "Greeting": f"Hello {name}",
        "Message": f"How are things at {city}?",
    }, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)