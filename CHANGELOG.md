### 0.6.0 (Next)

* [#51](https://github.com/dblock/fue/pull/51): Added Windows support and CI using the GitHub CLI token, and stopped prompting for a GitHub username - [@dblock](https://github.com/dblock).
* [#50](https://github.com/dblock/fue/pull/50): Use the GitHub CLI token with `gh auth token`, and stop prompting for and saving tokens in the macOS keychain; fixes fue on Linux - [@dblock](https://github.com/dblock).
* [#48](https://github.com/dblock/fue/pull/48): `--depth` looks through more than 100 commits in each repository - [@dblock](https://github.com/dblock).
* [#47](https://github.com/dblock/fue/pull/47): Added `--[no-]names` to display only e-mail addresses - [@dblock](https://github.com/dblock).
* [#46](https://github.com/dblock/fue/pull/46): `fue find` searches forks when the user has no commits in their own repositories - [@dblock](https://github.com/dblock).
* [#45](https://github.com/dblock/fue/pull/45): Fixed using a GitHub token stored in the keychain by another tool, such as ghi - [@dblock](https://github.com/dblock).
* [#44](https://github.com/dblock/fue/pull/44): Added release automation with ruby-gem-release and RubyGems Trusted Publishing - [@dblock](https://github.com/dblock).
* [#43](https://github.com/dblock/fue/pull/43): Upgraded to danger/danger-pr-comment 0.3.0 and stopped commenting on pull requests without Danger issues - [@dblock](https://github.com/dblock).
* [#41](https://github.com/dblock/fue/pull/41): Modernized CI with separate Test, Lint, and Package workflows, testing Ruby 3.0 and 4.0 on Linux and macOS, and removed AppVeyor - [@dblock](https://github.com/dblock).
* [#40](https://github.com/dblock/fue/pull/40): Upgraded RuboCop to 1.92, added rubocop-performance and rubocop-prose to lint Markdown, and fixed a `NoMethodError` when paging contributors of a repository without history - [@dblock](https://github.com/dblock).
* [#39](https://github.com/dblock/fue/pull/39): Fix `unknown keyword: quirks_mode` and Faraday JSON errors with json 3.x by upgrading to graphlient 0.9 (Faraday 2) and graphql 2.6.8+, and removing the unused github_api dependency - [@dblock](https://github.com/dblock).
* [#38](https://github.com/dblock/fue/pull/38): Migrate Danger to use danger-pr-comment workflow - [@dblock](https://github.com/dblock).
* [#37](https://github.com/dblock/fue/pull/36): Added fetching of e-mails from `Signed-off-by` and `--[no-]signed-off-by` - [@dblock](https://github.com/dblock).
* [#36](https://github.com/dblock/fue/pull/36): Added `--[no-]reply` to exclude `@users.noreply.github.com` email addresses - [@dblock](https://github.com/dblock).
* Your contribution here.

### 0.5.0 (2024-11-15)

* [#33](https://github.com/dblock/fue/pull/33): Fix: shell escape command lines - [@dblock](https://github.com/dblock).
* [#32](https://github.com/dblock/fue/pull/32): Upgraded to ruby 3.3 - [@dblock](https://github.com/dblock).

### 0.4.0 (2022/12/31)

* [#31](https://github.com/dblock/fue/pull/31): Use Danger - [@dblock](https://github.com/dblock).
* [#31](https://github.com/dblock/fue/pull/31): Replace Travis CI with GHA - [@dblock](https://github.com/dblock).
* [#31](https://github.com/dblock/fue/pull/31): Remove deprecated GitHub PAT creation workflow - [@dblock](https://github.com/dblock).

### 0.3.1 (2021/07/19)

* [#29](https://github.com/dblock/fue/issues/29): Fix: `error: can't modify frozen String` - [@dblock](https://github.com/dblock).

### 0.3.0 (2020/05/22)

* [#25](https://github.com/dblock/fue/pull/25): Added `contributors`, find repo contributors' e-mails - [@dblock](https://github.com/dblock).
* [#12](https://github.com/dblock/fue/issues/12): Added explicit ruby call to run fue - [@SYNstack](https://github.com/SYNstack).
* [#13](https://github.com/dblock/fue/issues/13): Changed shell tests to be OS-neutral - [@SYNstack](https://github.com/SYNstack).
* [#16](https://github.com/dblock/fue/issues/16): Setup Windows CI - [@SYNstack](https://github.com/synstack).
* [#17](https://github.com/dblock/fue/issues/19): Fix open-ended dependencies in gemspec - [@SYNstack](https://github.com/synstack).

### 0.2.1 (2018/8/23)

* [#2](https://github.com/dblock/fue/issues/2): Prompt to authenticate with Github - [@dblock](https://github.com/dblock).
* [#7](https://github.com/dblock/fue/issues/7): Display version - [@dblock](https://github.com/dblock).

### 0.2.0 (2018/8/22)

* [#6](https://github.com/dblock/fue/issues/6): Configure max depth and breadth separately - [@dblock](https://github.com/dblock).
* [#5](https://github.com/dblock/fue/issues/5): Iterate over more than 100 repositories - [@dblock](https://github.com/dblock).
* [#5](https://github.com/dblock/fue/issues/5): Fix error message and clarify max depth - [@dblock](https://github.com/dblock).

### 0.1.1 (2018/8/14)

* Initial public release, with help from [@orta](https://github.com/orta) - [@dblock](https://github.com/dblock).
