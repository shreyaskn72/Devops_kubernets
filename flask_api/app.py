from flask import Flask
from flask import Flask, request

app = Flask(__name__)

@app.route("/")
def hello():
    return {"message": "Good morning from Shreyas K N. Great job!"}


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
    app.run(host="0.0.0.0", port=5001)