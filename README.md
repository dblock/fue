Fue
===

[![Gem Version](https://badge.fury.io/rb/fue.svg)](https://badge.fury.io/rb/fue)
[![Tests](https://github.com/dblock/fue/actions/workflows/test.yml/badge.svg)](https://github.com/dblock/fue/actions/workflows/test.yml)

Find e-mail addresses of a Github users from their commit logs.

Fue is short for "Finding Unicorn Engineers".

![](images/fue.gif)

## Table of Contents

- [Usage](#usage)
  - [Commands](#commands)
    - [Find Someone’s Email](#find-someones-email)
    - [Find All Repo Contributors’ Emails](#find-all-repo-contributors-emails)
  - [Options](#options)
    - [Specify More Depth](#specify-more-depth)
  - [Get Help](#get-help)
  - [Access Tokens](#access-tokens)
- [Debugging](#debugging)
- [Contributing](#contributing)
- [Copyright and License](#copyright-and-license)

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

Fue will ask you to create a personal access token and will store it in the keychain. The access token should be created with `public_repo` scope [here](https://github.com/settings/tokens). You can also skip the prompts and use a previously obtained token with `-t` or by setting the `GITHUB_ACCESS_TOKEN` environment variable.

See [Creating a Personal Access Token for the Command Line](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line) for more information about personal tokens.

## Debugging

If you run into an unexpected error, try getting a stack trace with `GLI_DEBUG=true`.

```
$ GLI_DEBUG=true fue find dblock

FrozenError: can't modify frozen String
  /Users/dblock/source/dblock/fue/lib/fue/auth.rb:97:in `get_secure'
  /Users/dblock/source/dblock/fue/lib/fue/auth.rb:80:in `get_password'
  /Users/dblock/source/dblock/fue/lib/fue/auth.rb:50:in `password'
  /Users/dblock/source/dblock/fue/lib/fue/auth.rb:59:in `block in github'
```

## Contributing

There are [a few feature requests and known issues](https://github.com/dblock/fue/issues). Please contribute! See [CONTRIBUTING](CONTRIBUTING.md).

## Copyright and License

Copyright (c) 2018-2022, Daniel Doubrovkine, [Artsy](http://artsy.github.io), with help from [Orta](https://github.com/orta).

This project is licensed under the [MIT License](LICENSE.md).
