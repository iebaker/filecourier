#!/usr/bin/env python

from __future__ import print_function
from flask import Flask, Response, request
from multiprocessing import Process
from colors import red, blue
import os, webbrowser, sys, logging, time, requests, json

path = '/'.join(sys.argv[0].split('/')[:-1])
config = json.load(open(path + '/run.config'))

CLIENT_ID = config['client_id']
CLIENT_SECRET = config['client_secret']

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
print('[FILECOURIER] Opening ShareFile Login')
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
print('[FILECOURIER] Access Code: %s' % access_code)

# Exchange access code for access token
payload = {
	'code': access_code,
	'client_id': CLIENT_ID,
	'client_secret': CLIENT_SECRET,
	'grant_type': 'authorization_code' }
response = requests.post('https://secure.sharefile.com/oauth/token', data=payload, verify=False).json()
access_token = response['access_token']
print('[FILECOURIER] Access Token: %s' % access_token)
refresh_token = response['refresh_token']
print('[FILECOURIER] Refresh Token: %s' % refresh_token)

# utility class for using the ShareFile API
class ShareFileClient:
	def __init__(self, token):
		self.token = token
		self.auth_header = {'Authorization': 'Bearer %s' % access_token}

	def list(self, path=None):
		pieces = path.split('/') if path else []
		pieces.reverse()
		pieces.append('allshared')
		while pieces:
			current = pieces[-1]
			try:
				next_id = current if current == 'allshared' else result[current]
			except:
				print(red('[FILECOURIER][list] Could not find item "%s"' % current))
				return {}
			response = requests.get('https://%s.sf-api.com/sf/v3/Items(%s)/Children' % (config['sharefile_prefix'], next_id),
				headers=self.auth_header,
				verify=False).json()
			result = {item['FileName']: item['Id'] for item in response['value']}
			pieces.pop()
		return result

	def rename(self, item_id, new_name):
		payload = {'Name': new_name, 'FileName': new_name}
		print(green('[FILECOURIER][rename] Renaming file to "%s"' % new_name))
		return requests.patch('https://%s.sf-api.com/sf/v3/Items(%s)' % (config['sharefile_prefix'], item_id),
			headers=self.auth_header,
			verify=False,
			json=payload).json()

	def move(self, item, source, destination, new_name=None):
		try:
			print(green('[FILECOURIER][move] Attempting to move "%s" from "%s" to "%s"' % (item, source, destination)))
			destination_path = destination.split('/')
			destination_parent = '/'.join(destination_path[:-1])
			destination_id = self.list(destination_parent)[destination_path[-1]]
			source_item_id = self.list(source)[item]
		except:
			print(red('[FILECOURIER][move] Unable to move "%s" from "%s" to "%s"' % (item, source, destination)))
			return
		if new_name:
			self.rename(item_id=source_item_id, new_name=new_name)
		payload = {'Parent': {'Id': destination_id}}
		return requests.patch('https://%s.sf-api.com/sf/v3/Items(%s)' % (config['sharefile_prefix'], source_item_id),
			headers=self.auth_header,
			verify=False,
			json=payload).json()

	def copy(self, item, source, destination, new_name=None):
		try:
			print('[FILECOURIER][copy] Attempting to copy "%s" from "%s" to "%s"' % (item, source, destination))
			destination_path = destination.split('/')
			destination_parent = '/'.join(destination_path[:-1])
			destination_id = self.list(destination_parent)[destination_path[-1]]
			source_item_id = self.list(source)[item]
		except:
			print(red('[FILECOURIER][copy] Unable to copy "%s" from "%s" to "%s"' % (item, source, destination)))
			return
		copy_result = requests.post('https://%s.sf-api.com/sf/v3/Items(%s)/Copy?targetid=%s' % (config['sharefile_prefix'], source_item_id, destination_id),
			headers=self.auth_header,
			verify=False,
			json=payload).json()
		if new_name:
			self.rename(item_id=self.list(destination)[item], new_name=new_name)
		return copy_result

# Make a new sharefile client!
sharefile = ShareFileClient(access_token)
for indexed_program in enumerate(config['programs']):
	print('[FILECOURIER] [%d] %s' % indexed_program)

input_regognized = False
while not input_regognized:
	indices = raw_input('[FILECOURIER] Enter programs to run (space separated) or Ctrl-C to quit: ')
	try:
		indices = [int(index) for index in indices.rstrip().split(' ')]
		input_regognized = True
	except:
		print(red('[FILECOURIER] Could not parse input...'))

for index in indices:
	program = config['programs'][index]
	print('[FILECOURIER] Running Program "%s"' % program)
	# __import__(program).program(sharefile, config['programs'][program])
	# print('[FILECOURIER] Program "%s" complete!' % program)

print('[FILECOURIER] Done!')
