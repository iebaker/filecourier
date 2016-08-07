#!/usr/bin/env python

from __future__ import print_function
import os

folder = raw_input('Which folder are the files in? ')
print('Listing files in %s' % folder)
for file in os.listdir(folder):
	print(file)
