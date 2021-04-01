#!/usr/bin/python3
# Demo how to modify bestpractices.coreinfrastructure.org entries via API

# Copyright 2018, the Linux Foundation and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# To authenticate, you need a session cookie for the site and store
# that in the environment variable `_BadgeApp_session`.
# The easy way is to login as usual using your web browser and then
# find the cookie value for `_BadgeApp_session`.
# In Chrome, login to site & leave on screen. Then go to
# More Tools => Developer Tools => Application => Cookies
# select the site, select the _BadgeApp_session cookie,
# then go to the right and select JUST its value under the "Value" column.
# Now copy (control-C or cmd-C).
# In Firefox, Web Developer => Storage Inspector => Cookies
# shows the cookie value.
#
# One you have the cookie value copied into your clipboard, 
# set the environment variable _BadgeApp_session to it. E.g., in sh:
# export _BadgeApp_session='VALUE_FROM_CLIPBOARD'

import os, sys, re, json, urllib
from urllib.request import urlopen

# This is the base URL for project data.
base_url = 'https://master.bestpractices.coreinfrastructure.org/'
base_url = 'http://localhost:3000/'

# This will fail if the cookie is not set.
cookie = os.environ['_BadgeApp_session']

# This doesn't work, reasons unknown.
# curl -b "_BadgeApp_session=$BadgeApp_session" -i 'http://localhost:3000/en/projects/1/edit'


# In *principle* this is how to modify a project programmatically:
# * Log in
# * GET the HTML page for the edit page of the project you’re editing,
#   which will be
#   <https://bestpractices.coreinfrastructure.org/projects/NUMBER/edit>.
#   You’re looking for this in the HTML. You should see two values
#   (the ..._HERE are the values you want): <meta name="csrf-token"
#   content=“CSRF_TOKEN_VALUE_HERE" />
#   ...  <input type="hidden" name="authenticity_token"
#   value=“AUTH_TOKEN_VALUE_HERE" />
#   I think the value you actually want is the one with
#   “authenticity_token”.
# * Capture the cookie that represents login & related session data,
#   it’s named _BadgeApp_session
#   You must do this *AFTER* you’ve done GET on the form, because the
#   cookie includes encrypted data that must be matched with the form data.
# * Post the project data update, sending the cookie & data to authenticate
#   that this isn’t a CSRF attack.
#   It’s probably easier to send as JSON, e.g., POST
#   https://bestpractices.coreinfrastructure/projects/NUMBER.json).
#   I suggest sending the csrf token using the "X-CSRF-Token" HTTP
#   header, though you should also be able to include it as a POST
#   parameter. I think the token you need to send is the one set by
#   “authenticity_token”, and not csrf-token.

if __name__ == '__main__':
    print('Hello')


# # Retrieve paged JSON data
# def retrieve_data():
#     retrieved_dataset = []
#     page_number = 1
#     while True:
#         url = base_url + '?page=' + str(page_number)
#         page_string = urlopen(url).read()
#         page_data = json.loads(page_string)
#         print(page_number, file=sys.stderr)
#         if len(page_data) == 0:
#             break
#         retrieved_dataset += page_data
#         page_number += 1
#     return retrieved_dataset
# 
# # Load JSON data (from a file if possible, else it's retrieved and saved)
# def load_data():
#     if os.path.exists(cached_filename):
#         print('Loading existing file: %s' % cached_filename, file=sys.stderr)
#         f = open(cached_filename, 'r')
#         return json.load(f)
#     else:
#         print('Retrieving data', file=sys.stderr)
#         retrieved_dataset = retrieve_data()
#         # Save data into file so we don't need to retrieve later
#         print('Saving data to file: %s' % cached_filename, file=sys.stderr)
#         f = open(cached_filename, 'w')
#         json.dump(retrieved_dataset, f)
#         return retrieved_dataset
# 
# #
# # Load the JSON data by calling load_data()
# #
# 
# json_dataset = load_data()
# 
# # Now json_dataset has complete set of data.  Print a count.
# print('Number of projects = ', len(json_dataset))
# 
# # Now do some sample analysis.  Example analysis:
# # Count projects saying they use the R programming language.
# re_split_list = re.compile(r' *, *')
# r_projects = 0
# for project in json_dataset:
#     if project['implementation_languages']:
#         langs = re.split(re_split_list, project['implementation_languages'])
#         if 'R' in langs: r_projects += 1
# print('R projects =', r_projects)
