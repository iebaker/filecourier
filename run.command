#!/usr/bin/env python

from __future__ import print_function
from flask import Flask, Response, request
from multiprocessing import Process
import os, webbrowser, sys, logging, time, requests

CLIENT_ID = 'lhFBjF4VWMkvoE0E7jFSRZO3lMxegg9X'
CLIENT_SECRET = 'E4SJ4F2x3gdT3eVLULtLODnwjCVpP3Xu3DuP7FlxwlXeUXQZ'

# ============ #
# FLASK SERVER #
# ============ #

app = Flask(__name__)
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

# ================ #
# END FLASK SERVER #
# ================ #

# get rid of old code file if it exists
try:
	os.remove('.code.txt')
except OSError:
	pass

# sigh...
requests.packages.urllib3.disable_warnings()

# Open a browser to initiate oauth2 sequence, redirect to hosted page which
# will send code back to flask server and shut it down
webbrowser.open('https://secure.sharefile.com/oauth/authorize?response_type=%s&client_id=%s&redirect_uri=%s' %
	('code', CLIENT_ID, 'https://izaak.host/redirect.html'))

# Wait for oauth2 to complete, then read access code off file
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
print('Access Code: %s' % access_code)

# Exchange access code for access token
payload = {
	'code': access_code,
	'client_id': CLIENT_ID,
	'client_secret': CLIENT_SECRET,
	'grant_type': 'authorization_code' }
response = requests.post('https://secure.sharefile.com/oauth/token', data=payload, verify=False).json()
access_token = response['access_token']
print('Access Token: %s' % access_token)
refresh_token = response['refresh_token']
print('Refresh Token: %s' % refresh_token)

# utility class for using the ShareFile API
class ShareFileClient:
	def __init__(self, token):
		self.token = token
		self.auth_header = {'Authorization': 'Bearer %s' % access_token}

	def ls(self, path):
		pieces = path.split('/') if path else []
		pieces.reverse()
		pieces.append('allshared')
		while pieces:
			current = pieces[-1]
			next_id = current if current == 'allshared' else result[current]
			response = requests.get('https://izaak.sf-api.com/sf/v3/Items(%s)/Children' % next_id, headers=self.auth_header, verify=False).json()
			result = {item['FileName']: item['Id'] for item in response['value']}
			pieces.pop()
		return result

	def mv(self, item, source, destination):
		destination_path = destination.split('/')
		destination_parent = ''.join(destination_path[:-1])
		destination_id = self.ls(destination_parent)[destination_path[-1]]
		source_item_id = self.ls(source)[item]
		payload = {'Parent': {'Id': destination_id}}
		print(destination_id)
		return requests.patch('https://izaak.sf-api.com/sf/v3/Items(%s)' % source_item_id,
			headers=self.auth_header,
			verify=False,
			json=payload).json()

sharefile = ShareFileClient(access_token)
print(str(sharefile.mv('vangogh.jpg', 'Folder B', 'Folder A')))
