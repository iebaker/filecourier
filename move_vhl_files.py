def program(sharefile):
    # Find all the different alphabet pieces (e.g. "A-C", "S-U")
    alphabet_segments = sharefile.list('Dependent E-Files')
    alphabet_segments = {key: value for key, value in alphabet_segments.iteritems() if len(key) == 3}

    # Search Team Leaders/Monthly Paperwork/*/August 2016 for files (assume all are VHL files!) and move them appropriately
    team_leaders_monthly_paperwork = sharefile.list('Team Leaders/Monthly Paperwork')
    for team_leader_folder in team_leaders_monthly_paperwork:
    	august_2016 = sharefile.list('Team Leaders/Monthly Paperwork/%s/August 2016' % team_leader_folder)
    	for filename in august_2016:
            if filename.find('VHL') == -1:
                continue
    		child_first_initial = filename.split(' ')[3][0]
    		child_name = ' '.join([filename.split(' ')[3], filename.split(' ')[4]])
    		for segment in alphabet_segments:
    			range_pair = segment.split('-')
    			if child_first_initial >= range_pair[0] and child_first_initial <= range_pair[1]:
    				item = filename
    				source = 'Team Leaders/Monthly Paperwork/%s/August 2016' % team_leader_folder
    				destination = 'Dependent E-Files/%s/%s/CASA Internal Documents' % (segment, child_name)
    				sharefile.move(item, source, destination)
