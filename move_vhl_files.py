# This is an example Filecourier Program. It moves VHL files from Team Leader folders into Child folders
def program(sharefile):

	# First, find all the different alphabet segment folders (e.g. "A-C", "S-U")
	alphabet_segments = sharefile.list('Dependent E-Files')
	alphabet_segments = {key: value for key, value in alphabet_segments.iteritems() if len(key) == 3}

	# Then, find the names of all the team leaders in Team Leaders/Monthly Paperwork
	team_leaders_monthly_paperwork = sharefile.list('Team Leaders/Monthly Paperwork')

	# Go through each team leader and...
	for team_leader_folder in team_leaders_monthly_paperwork:

		# Go through all the files in that team leader's august 2016 folder and...
		august_2016 = sharefile.list('Team Leaders/Monthly Paperwork/%s/August 2016' % team_leader_folder)
		for filename in august_2016:

			# If the filename doesn't have 'VHL' in it, move on to the next team leader
			if filename.find('VHL') == -1:
				continue

			# Otherwise, find the child's name by splitting the filename around spaces and joining the 4th and 5th pieces
			child_name = ' '.join([filename.split(' ')[3], filename.split(' ')[4]])

			# With this child name, go through all the alphabet segments and ...
			for segment in alphabet_segments:
				range_pair = segment.split('-')

				# If the child's name falls into this alphabet segment...
				if child_name[0] >= range_pair[0] and child_name[0] <= range_pair[1]:

					# Move the file into the appropriate result folder!
					item = filename
					source = 'Team Leaders/Monthly Paperwork/%s/August 2016' % team_leader_folder
					destination = 'Dependent E-Files/%s/%s/CASA Internal Documents' % (segment, child_name)
					sharefile.move(item, source, destination)
