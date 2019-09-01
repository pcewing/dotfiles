#!/usr/bin/env python3

# This script will prompt for GitHub credentials and then clone all
# repositories owned by the specified user.
#
# Usage:
#     clone.py [options]
#
# For more details:
#     clone.py -h

import json
import subprocess
import os
import argparse
import urllib.request
import base64
import getpass
import re


class Repo:
    def __init__(self, org='', name='', url=''):
        self.org = org
        self.name = name
        self.url = url


def clone(src_dir, repo, dry_run):
    os.makedirs(repo.org, exist_ok=True)

    path = os.path.join(src_dir, repo.org, repo.name)
    if os.path.exists(path):
        print('Repo path {}/{} already exists, skipping...'.format(
            repo.org, repo.name))
        return

    if dry_run:
        print('git clone {} {}'.format(repo.url, path))
    else:
        subprocess.run(['git', 'clone', repo.url, path])


def get_page(url, creds):
    request = urllib.request.Request(url)
    request.add_header('Authorization', 'Basic %s' % creds.decode('ascii'))

    with urllib.request.urlopen(request) as response:
        header = response.getheader('Link')
        matches = re.findall('.*<(.*)>; rel="next".*', header)
        next_page_url = None
        if len(matches) > 0:
            next_page_url = matches[0]
        return (next_page_url, json.loads(response.read()))


def get_repo_data():
    username = input('Enter GitHub username: ')
    password = getpass.getpass(prompt='Enter GitHub password: ')

    credentials = ('%s:%s' % (username, password))
    encoded_credentials = base64.b64encode(credentials.encode('ascii'))

    (next_page_url, data) = get_page(
            'https://api.github.com/user/repos', encoded_credentials)

    while next_page_url is not None:
        (next_page_url, page_data) = get_page(next_page_url,
                                              encoded_credentials)
        data += page_data

    return data


def parse_args():
    parser = argparse.ArgumentParser(
            description='Clone a user\'s git repositories.')
    parser.add_argument('--dry-run', dest='dry_run', action='store_true',
                        help='Print actions without running them')
    parser.add_argument('--source-directory', dest='src_dir', type=str,
                        default='$HOME/src/github',
                        help='The base source directory to clone to')
    return parser.parse_args()


def main():
    args = parse_args()
    src_dir = os.path.expandvars(args.src_dir)

    data = get_repo_data()

    repos = [Repo(r['owner']['login'], r['name'], r['ssh_url']) for r in data]

    for repo in repos:
        clone(src_dir, repo, args.dry_run)


if __name__ == '__main__':
    main()
