#!/usr/bin/env python3

# This script will clone all repositories owned by the specified user.
# 
# Given that username/password authentication to the GitHub API was deprecated,
# the script authenticates via a personal access token. This can either be set
# using the GITHUB_API_TOKEN environment variable or via the --token option,
# the option taking precedent
#
# Usage:
#     clone.py [options]
#
# Examples:
#     GITHUB_API_TOKEN="26f4f4147352b7c943a62d43c9d5684d7a9a3669" clone.py
#     clone.py --token="26f4f4147352b7c943a62d43c9d5684d7a9a3669"
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


def get_page(url, token):
    request = urllib.request.Request(url)
    request.add_header('Authorization', 'token %s' % token)

    with urllib.request.urlopen(request) as response:
        header = response.getheader('Link')
        matches = re.findall('.*<(.*)>; rel="next".*', header)
        next_page_url = None
        if len(matches) > 0:
            next_page_url = matches[0]
        return (next_page_url, json.loads(response.read()))


def get_repo_data(token):
    (next_page_url, data) = get_page('https://api.github.com/user/repos', token)

    while next_page_url is not None:
        (next_page_url, page_data) = get_page(next_page_url, token)
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
    parser.add_argument('--token', dest='token', type=str,
                        default=None,
                        help='The personal access token used to authenticate')
    return parser.parse_args()


def main():
    args = parse_args()
    src_dir = os.path.expandvars(args.src_dir)

    token = args.token
    if token is None:
        token = os.getenv('GITHUB_API_TOKEN')
        if token is None:
            print('No GITHUB_API_TOKEN provided')
            exit(1)


    data = get_repo_data(token)

    repos = [Repo(r['owner']['login'], r['name'], r['ssh_url']) for r in data]

    for repo in repos:
        clone(src_dir, repo, args.dry_run)


if __name__ == '__main__':
    main()
