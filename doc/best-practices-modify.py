#!/usr/bin/python3
# Modify bestpractices.coreinfrastructure.org project entries via API

# Copyright the Linux Foundation and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

"""
This program programmatically modifies BadgeApp projects.

An example of using this is
doc/best-practices-modify.py -S 1 '{"test_status": "Met"}'
which modifies project 1 on the staging site.
To modify the *production* site data, use -P instead of -S.
Updates use JSON format; remember to use double-quotes around all strings
in the JSON format.

Note: For modification to work, you need to authenticate to the BadgeApp
and provide that data to this program. Here's how.

First, use your web browser to log into
the BadgeApp and get the value of the session cookie `_BadgeApp_session`.
In Chrome, go to
More Tools => Developer Tools => Application => Cookies,
select the site, and select the _BadgeApp_session cookie.
In Firefox, go to Web Developer => Storage Inspector => Cookies.
No matter what, select JUST the value of cookie `_BadgeApp_session`
and copy it.

One you have the cookie value copied into your clipboard, 
the recommended approach is to set the environment variable _BadgeApp_session
to it. E.g., in sh:
export _BadgeApp_session='VALUE_FROM_CLIPBOARD'

Alternatively, you can pass the session value on the command line, by
using the -C argument (-C *session_cookie_value*).

Note that a given login cookie is good for 48 hours, and then expires.
"""

# Python2 is "officially" unsupported but actually in wide use,
# so we'll try to make it not hard to use Python2.
# We'll import print_function, and use "+" to concatenate strings.
# We haven't tested with Python2, so more changes are likely necessary. 
from __future__ import print_function

import os, sys, re, json, urllib
import argparse
from urllib.request import urlopen

# Plausible base URLs.
LOCAL_BASE_URL = 'http://localhost:3000/'
STAGING_BASE_URL = 'https://staging.bestpractices.coreinfrastructure.org/'
PRODUCTION_BASE_URL = 'https://bestpractices.coreinfrastructure.org/'

COOKIE_NAME = '_BadgeApp_session'

def patch_project(base_url, id, updated_data,
                  auth_token, csrf_token, session_cookie):
    """Attempts to patch project id with updated_data"""

    # Originally we tried to PATCH the JSON endpoint, but we never
    # got that working. So instead we PATCH the HTML endpoint:
    url = base_url + 'en/projects/' + str(id)

    # Convert updated_data hashes of form {'test_status': 'Unmet'}
    # into {'project[test_status]': 'Unmet'} because that's what the
    # HTML form submission format requires.
    updated_data_reformatted = {}
    for key, value in updated_data.items():
        updated_data_reformatted['project[' + key + ']'] = value
    # Add authentication_token
    updated_data_reformatted['authentication_token'] = auth_token

    # Encode data for urllib.request.html as described in
    # https://docs.python.org/3/library/urllib.request.html#request-objects
    updated_data_encoded = urllib.parse.urlencode(
            updated_data_reformatted).encode('utf-8')

    # Set up request.
    request = urllib.request.Request(url,
            data=updated_data_encoded, method='PATCH')
    # Provide authentication cookie to prove we're authorized to update.
    # Beware: add_header can only add *one* Cookie header
    request.add_header('Cookie', COOKIE_NAME + '=' + session_cookie)
    request.add_header('X-CSRF-Token', csrf_token)
    # Note: We don't send an origin; Rails considers that a valid origin.
    # Originally we tried to post JSON, but had trouble getting that working.
    # To do that you'd use the .json resource and add this header:
    # request.add_header('Content-Type', 'application/json')
    # request.add_header('Accepts', 'application/json') # Shouldn't matter

    # Attempt to send request.
    try:
        response = urlopen(request)
    except urllib.error.HTTPError as e:
        if e.code == 302 and e.headers['Location'] == url:
            # EXPECTED result - everything is fine!
            return 200
        print('Warning: Received HTTPError, code=' + str(e.code))
        print('This can happen on localhost if project badge status changes.')
        return 500

    print('Warning: No exception, even though we expected a redirect 302')
    print('There may be an invalid key or key value.')
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
    """Return string token in provided HTML that matches pattern."""
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
    if set_cookie is None:
        print('Warning: No cookie updated')
        return session_cookie
    expected_prefix = COOKIE_NAME + '='
    if not set_cookie.startswith(expected_prefix):
        print('Warning: Wrong cookie set')
        return session_cookie
    leftover = set_cookie[len(expected_prefix):]
    new_session_cookie = leftover.split(';',1)[0]
    return new_session_cookie

def get_project_tokens(base_url, id, session_cookie):
    """Returns auth_token,csrf_token,session_cookie for project id."""
    # Try to get the "edit" page with our logged-in session cookie
    url = base_url + 'en/projects/' + str(id) + '/edit'
    request = urllib.request.Request(url)
    # Provide authentication cookie to prove we're authorized to get page.
    # Beware: add_header can only add *one* Cookie header
    request.add_header('Cookie', COOKIE_NAME + '=' + session_cookie)
    # Note: We don't send an origin; Rails considers that a valid origin.

    # Note: This will raise exception on open failure
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

def write_to_project(base_url, id, updated_data, session_cookie):
    """Write to project #id the updated_data in json format -> true if ok"""
    # First request the HTML edit form; it includes information we
    # must have to successfully patch a project.
    auth_token, csrf_token, updated_session_cookie = get_project_tokens(
            base_url, id, session_cookie)
    # Now request patching the project.
    # We have to send various other data, including an updated_session_cookie,
    # because we need them to be allowed to do an update.
    status = patch_project(base_url, id, updated_data,
            auth_token, csrf_token, updated_session_cookie)
    return status == 200

def main():
    """Main entry for command line interface"""

    # Create argument parser, then parse command line arguments with it.
    parser = argparse.ArgumentParser(
            description='Modify project data on BadgeApp',
            epilog=__doc__
    )
    parser.add_argument('-C', '--cookie',
        help='Session cookie value, else uses env variable ' + COOKIE_NAME,
        dest='session_cookie', default=os.environ.get(COOKIE_NAME))
    # Make it easy to select base URL
    group_base = parser.add_mutually_exclusive_group()
    group_base.add_argument('-b', '--base', dest='base_url',
            default=LOCAL_BASE_URL, help='Arbitrary base URL to modify')
    group_base.add_argument('-L', '--local', dest='base_url',
            action='store_const',
            const=LOCAL_BASE_URL, help='Store in local repo')
    group_base.add_argument('-S', '--staging', dest='base_url',
            action='store_const',
            const=STAGING_BASE_URL, help='Store in staging repo')
    group_base.add_argument('-P', '--production', dest='base_url',
            action='store_const',
            const=PRODUCTION_BASE_URL, help='Store in production (REAL) repo')
    parser.add_argument('project_id', help='Project id (number) to modify')
    parser.add_argument('updated_data', help='Updated data (JSON format)')

    # Process command line arguments.
    args = parser.parse_args()

    if (args.session_cookie is None or args.session_cookie == ''):
        print('We MUST have a session cookie value to proceed')
        sys.exit(1)

    # Convert JSON data into a Python dictionary.
    # This will fail & raise an exception if non-JSON provided.
    # Remember to use *double-quotes* around all strings in JSON;
    # the JSON data needs to look like this:
    # {"test_status": "Met"}
    # Note that status values can be "Met", "Unmet", or "?".
    updated_data_json = json.loads(args.updated_data)

    # Notify what we're doing.
    print("Writing data to project " + args.project_id +
          " at base URL " + args.base_url)

    # Now go do it!
    result = write_to_project(args.base_url,
            args.project_id, updated_data_json, args.session_cookie)
    sys.exit(not result)

if __name__ == '__main__':
    main()
