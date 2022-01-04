from flask import Flask,request
import requests
app = Flask(__name__)

@app.route("/")
def hello():
    addr = request.args.get('url')
    print(addr)
    if addr == None:
        addr = 'https://api.ipify.org'
    resp =requests.get(addr)
    if resp.status_code == 200:
        return ("Respond from " + addr + ":<br>" + resp.text)
    else:
        return "Couldn't access requested website!"
