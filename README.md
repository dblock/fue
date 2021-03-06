Fue
===

[![Gem Version](https://badge.fury.io/rb/fue.svg)](https://badge.fury.io/rb/fue)
[![Build Status](https://travis-ci.org/dblock/fue.svg)](https://travis-ci.org/dblock/fue)
[![Build status](https://ci.appveyor.com/api/projects/status/github/dblock/fue?branch=master&svg=true)](https://ci.appveyor.com/project/dblock/fue)

Find e-mail addresses of a Github users from their commit logs.

Fue is short for "Finding Unicorn Engineers".

![](images/fue.gif)

## Usage

```
gem install fue
```

### Commands

#### Find Someone's Email

The `find` command looks through user's initial repository commits.

```
$ fue --verbose find defunkt

Chris Wanstrath <chris@ozmm.org>
Chris Wanstrath <chris@github.com>
```

#### Find All Repo Contributors' Emails

The `contributors` command looks through a git log of contributors, then fetches their e-mails.

```
$ fue --verbose contributors defunkt/colored

defunkt: Chris Wanstrath <chris@ozmm.org>
kch: Caio Chassot <kch@users.noreply.github.com>
```

### Options

#### Specify More Depth

By default the code looks at 1 commit from the last 10 repositories. You can look at more repositories (breadth) and more commits (depth). The maximum value for depth is 100, enforced by Github. Fue will iterate over a number of repositories larger than 100.

```
$ fue find --breadth=100 --depth=5 defunkt

Chris Wanstrath <chris@ozmm.org>
Chris Wanstrath <chris@github.com>
defunkt <chris@ozmm.org>
```

### Get Help

```
fue help
```

Displays additional options.

### Access Tokens

Fue will prompt you for Github credentials and 2FA, if enabled.

```
$ fue find defunkt
Enter dblock's GitHub password (never stored): ******************
Enter GitHub 2FA code: ******
Token saved to keychain.
```

The access token will be generated with `public_repo` scope and stored in the keychain. It can be later deleted from [here](https://github.com/settings/tokens). You can also skip the prompts and use a previously obtained token with `-t` or by setting the `GITHUB_ACCESS_TOKEN` environment variable.

See [Creating a Personal Access Token for the Command Line](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line) for more information about personal tokens.

## Contributing

There are [a few feature requests and known issues](https://github.com/dblock/fue/issues). Please contribute! See [CONTRIBUTING](CONTRIBUTING.md).

## Copyright and License

Copyright (c) 2018-2020, Daniel Doubrovkine, [Artsy](http://artsy.github.io), with help from [Orta](https://github.com/orta).

This project is licensed under the [MIT License](LICENSE.md).
