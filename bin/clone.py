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

class Repo:
    def __init__(self, org='', name='', url=''):
        self.org = org
        self.name = name
        self.url = url


def clone(src_dir, repo, dry_run):
    os.makedirs(repo.org, exist_ok=True)

    path = os.path.join(src_dir, repo.org, repo.name)
    if os.path.exists(path):
        print('Repo path {}/{} already exists, skipping...'.format(repo.org, repo.name))
        return

    if dry_run:
        print('git clone {} {}'.format(repo.url, path))
    else:
        subprocess.run(['git', 'clone', repo.url, path])


def get_repo_data():
    request = urllib.request.Request('https://api.github.com/user/repos')

    username = input('Enter GitHub username: ')
    password = getpass.getpass(prompt='Enter GitHub password: ')

    credentials = ('%s:%s' % (username, password))
    encoded_credentials = base64.b64encode(credentials.encode('ascii'))

    request.add_header('Authorization', 'Basic %s' % encoded_credentials.decode('ascii'))

    with urllib.request.urlopen(request) as response:
        return json.loads(response.read())


def parse_args():
    parser = argparse.ArgumentParser(description='Clone a user\'s git repositories.')
    parser.add_argument('--dry-run', dest='dry_run', action='store_true',
                        help='Print what actions would be run without running them')
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

