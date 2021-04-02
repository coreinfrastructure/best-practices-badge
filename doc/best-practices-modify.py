#!/usr/bin/python3
# Demo how to modify bestpractices.coreinfrastructure.org entries via API

# Copyright the Linux Foundation and the
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

# NOTE: A given login cookie is good for 48 hours, and then expires.

import os, sys, re, json, urllib
from urllib.request import urlopen

# This is the base URL for project data.
# base_url = 'https://master.bestpractices.coreinfrastructure.org/'
# TODO
base_url = 'http://localhost:3000/'

COOKIE_NAME = '_BadgeApp_session'

# This doesn't work, reasons unknown.
# curl -b "_BadgeApp_session=$BadgeApp_session" -i 'http://localhost:3000/en/projects/1/edit'


# In *principle* this is how to modify a project programmatically:
# * Log in using your browser and store the session cookie data
#   in the environment variable "_BadgeApp_session" as described above.
# * In some cases you might want to GET the JSON data
#   for the project you're editing, which will be
#   <https://bestpractices.coreinfrastructure.org/projects/NUMBER.json>.
# * GET the HTML page for the edit page of the project you’re editing,
#   which will be
#   <https://bestpractices.coreinfrastructure.org/projects/NUMBER/edit>.
#   You’re looking for this in the HTML. You should see two values
#   (the ..._HERE are the values you want): <meta name="csrf-token"
#   content="CSRF_TOKEN_VALUE_HERE" />
#   ...  <input type="hidden" name="authenticity_token"
#   value="AUTH_TOKEN_VALUE_HERE" />
#   I think the value you actually want is the one with
#   "authenticity_token".
# * Capture the cookie that represents login & related session data,
#   it’s named _BadgeApp_session
#   You must do this *AFTER* you’ve done GET on the form, because the
#   cookie includes encrypted data that must be matched with the form data.
# * PATCH the project data update, sending the cookie & data to authenticate
#   that this isn’t a CSRF attack.
#   It’s probably easier to send as JSON, e.g., POST
#   https://bestpractices.coreinfrastructure/projects/NUMBER.json).
#   I suggest sending the csrf token using the "X-CSRF-Token" HTTP
#   header, though you should also be able to include it as a POST
#   parameter. I think the token you need to send is the one set by
#   “authenticity_token”, and not csrf-token.




# Enable per-form CSRF tokens. Previous versions had false. CHANGED.
# Rails.application.config.action_controller.per_form_csrf_tokens = true
# Enable origin-checking CSRF mitigation. Previous versions had false. CHANGED.
# Rails.application.config.action_controller.forgery_protection_origin_check = true


def patch_project(id, updated_data, auth_token, csrf_token, session_cookie):
    """Attempts to patch project id with updated_data"""
    # We assume updated_data is a string, in JSON format, of changes.

    # TODO
    print('starting patch_project')
    """Returns auth_token,session_cookie for editing given project."""

    # Try to get the "edit" page with our logged-in session cookie
    url = base_url + 'en/projects/' + str(id) + '.json'

    # https://docs.python.org/3/library/urllib.request.html#request-objects
    # For an HTTP POST request method, data should be a buffer in the standard application/x-www-form-urlencoded format. The urllib.parse.urlencode() function takes a mapping or sequence of 2-tuples and returns an ASCII string in this format. It should be encoded to bytes before being used as the data parameter.
    # https://docs.python.org/3/library/urllib.parse.html#urllib.parse.urlencode

    # updated_data_bytes = bytes(updated_data, 'utf-8')
    # urllib.parse.urlencode({'spam': 1, 'eggs': 2, 'bacon': 0})
    # updated_data_encoded = urllib.parse.urlencode(updated_data) # .encode('ascii')
    updated_data_encoded = bytes(updated_data, 'utf-8')

    request = urllib.request.Request(url,
            data=updated_data_encoded, method='PATCH')
    # Beware: add_header can only add *one* Cookie header
    request.add_header('Cookie', COOKIE_NAME + '=' + session_cookie)
    request.add_header('X-CSRF-Token', csrf_token)
    request.add_header('Content-Type', 'application/json')
    # request.add_header('Accepts', 'application/json') # Shouldn't matter
    # TODO: auth_token???
    # Note: We don't send an origin; Rails considers that a valid origin.

    # TODO: Handle exception on open failure
    response = urlopen(request)

    redirected = (response.url != url)
    if redirected or response.code != 200:
        print('Error: Did not have permission to change project data')
        return 403 # Forbidden

    return 200

# To find the form's authenticity token we look for this pattern:
AUTH_TOKEN_HTML_PATTERN = re.compile(
    r'<input type="hidden" name="authenticity_token" value="([^"]+)"'
)

# To find the form's csrf token we look for this pattern:
CSRF_TOKEN_HTML_PATTERN = re.compile(
    r'<meta name="csrf-token" content="([^"]+)"'
)


def get_token(html, pattern):
    """Return token in provided HTML that matches pattern."""
    result = pattern.search(html)
    if result:
        return result.group(1)
    else:
        print('Failed to find token')
        return None

def get_updated_cookie(headers, session_cookie):
    """Retrieve the updated session cookie"""
    # We should have received an HTTP header of this form:
    # Set-Cookie: _BadgeApp_session=VALUE; path=/; HttpOnly
    # We will try to return the VALUE part.
    set_cookie = headers['Set-Cookie']
    if set_cookie == None:
        print('Warning: No cookie updated')
        return session_cookie
    expected_prefix = COOKIE_NAME + '='
    if not set_cookie.startswith(expected_prefix):
        print('Warning: Wrong cookie set')
        return session_cookie
    leftover = set_cookie[len(expected_prefix):]
    new_session_cookie = leftover.split(';',1)[0]
    return new_session_cookie

def get_project_tokens(id, session_cookie):
    """Returns auth_token,csrf_token,session_cookie for project id."""
    # Try to get the "edit" page with our logged-in session cookie
    url = base_url + 'en/projects/' + str(id) + '/edit'
    request = urllib.request.Request(url)
    # Beware: add_header can only add *one* Cookie header
    request.add_header('Cookie', COOKIE_NAME + '=' + session_cookie)
    # Note: We don't send an origin; Rails considers that a valid origin.

    # TODO: Handle exception on open failure
    response = urlopen(request)

    redirected = (response.url != url)
    if redirected or response.code != 200:
        print('Error: Did not have permission to view edit page')
        return None, None

    html = str(response.read(), 'utf-8')
    auth_token = get_token(html, AUTH_TOKEN_HTML_PATTERN)
    csrf_token = get_token(html, CSRF_TOKEN_HTML_PATTERN)

    new_session_cookie = get_updated_cookie(response.headers, session_cookie)
    return auth_token, csrf_token, new_session_cookie

def get_session_cookie():
    if '_BadgeApp_session' in os.environ:
        return os.environ['_BadgeApp_session']
    else:
        print('Error: Environment variable _BadgeApp_session not set!')
        print('Please log in and set the environment variable.')
        # Just exit, we can't do anything in this situation.
        sys.exit(1)

def write_to_project(id, updated_data):
    """Write to project #id the updated_data in json format -> true if ok"""
    session_cookie = get_session_cookie()
    auth_token, csrf_token, session_cookie = get_project_tokens(
            id, session_cookie)
    status = patch_project(id, updated_data, auth_token, csrf_token, session_cookie)
    return status == 200

# TODO: Stub until we're confident it works
PROJECT_NUMBER = 1
# UPDATED_DATA = "{ 'automated_integration_testing_status' : 'Unmet' }"
# UPDATED_DATA = "{'id': 25, 'project': { 'id': 25, 'automated_integration_testing_status' : 'Unmet' }}"
# UPDATED_DATA = {'id': 25, 'project': { 'id': 25, 'automated_integration_testing_status' : 'Unmet' }}
UPDATED_DATA = "{'id':25,'project':{'id':25,'automated_integration_testing_status':'Unmet'}}"

def main():
    print('Writing to project')
    # TODO: Stub until we're confident it works
    sys.exit(not write_to_project(PROJECT_NUMBER, UPDATED_DATA))

if __name__ == '__main__':
    main()


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
