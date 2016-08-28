# This is an example Filecourier Program. It moves VHL files from Team Leader folders into Child folders
def program(sharefile):

	target_month = raw_input('[VHL ROBOT] Enter target month: ')

	alphabet_segments = sharefile.list('Dependent E-Files')
	alphabet_segments = {key: value for key, value in alphabet_segments.iteritems() if len(key) == 3}

	team_leaders = [leader for leader in sharefile.list('Team Leaders/Monthly Paperwork')]
	for indexed_team_leader in enumerate(team_leaders):
		print('[VHL ROBOT] [%d] %s' % indexed_team_leader)

	input_recognized = False
	while not input_recognized:
		indices = raw_input('[VHL ROBOT] Enter team leaders (space separated), or Ctrl-C to quit: ')
		try:
			indices = [int(index) for index in indices.rstrip().split(' ')]
			input_recognized = True
		except:
			print('[VHL ROBOT] Could not parse input...')

	for index in indices:
		target_folder = 'Team Leaders/Monthly Paperwork/%s/%s' % (team_leaders[index], target_month)
		print('[VHL ROBOT] Searching "%s"' % target_folder)

		month = sharefile.list(target_folder)
		for filename in month:

			if filename.find('VHL') == -1:
				print('[VHL ROBOT] "%s" does not seem to be a VHL file' % filename)
				continue

			try:
				child_name = filename.split()[2]
				print('[VHL ROBOT] "%s" is a VHL file for child %s' % (filename, child_name))
			except:
				print('[VHL ROBOT] "%s" might be a VHL file with a nonstandard name. Ignoring it.' % filename)
				continue

			found = False
			for segment in alphabet_segments:
				range_pair = segment.split('-')
				if child_name[0] >= range_pair[0] and child_name[0] <= range_pair[1]:
					found = True
					item = filename
					source = 'Team Leaders/Monthly Paperwork/%s/%s' % (team_leaders[index], target_month)
					destination = 'Dependent E-Files/%s/%s/CASA Internal Documents' % (segment, child_name[:-1] + ' ' + child_name[-1])
					sharefile.move(item, source, destination, ' '.join(filename.split()[1:]))
			if not found:
				print('[VHL ROBOT] Could not alphabetize %s in %s', child_name, str(alphabet_segments))
