#!/usr/bin/env python

from __future__ import print_function
from flask import Flask, Response, request
from multiprocessing import Process
import os, webbrowser, sys, logging, time

try:
	os.remove('.code.txt')
except OSError:
	pass

app = Flask(__name__)
access_code = 0

# Stop flask server from printing stuff
logging.getLogger('werkzeug').setLevel(logging.ERROR)

@app.route('/code/<code>', methods=['POST'])
def receive_code(code):
	code_file = open('.code.txt', 'w+')
	code_file.write(code)
	code_file.close()

	response = Response('')
	response.headers['Access-Control-Allow-Origin'] = '*'
	return response

@app.route('/shutdown', methods=['POST'])
def shutdown():
	shutdown_function = request.environ.get('werkzeug.server.shutdown')
	if shutdown_function is not None: shutdown_function()

	response = Response('')
	response.headers['Access-Control-Allow-Origin'] = '*'
	return response

def run_server():
	app.run(port=5000, debug=False, threaded=True)

# server runs in separate process, will kill itself on hearing /shutdown
server = Process(target=run_server)
server.start()

# TODO: initiate oauth2 sequence in browser. For now just hit redirect directly
webbrowser.open('https://secure.sharefile.com/oauth/authorize?response_type=%s&client_id=%s&redirect_uri=%s' %
	('code', 'lhFBjF4VWMkvoE0E7jFSRZO3lMxegg9X', 'https://izaak.host/redirect.html'))

def spin_til_code_file_written():
	global access_code
	while True:
		try:
			code_file = open('.code.txt')
			access_code = code_file.read()
			return
		except:
			time.sleep(1)
spin_til_code_file_written()

print('Code %s retrieved!' % access_code)
