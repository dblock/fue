# Releasing Fue

There are no hard rules about when to release fue. Release bug fixes frequently, features not so frequently and breaking API changes rarely.

Releases use [ruby-gem-release](https://github.com/dblock/ruby-gem-release/tree/v0.9.0) and the manual [Release workflow](.github/workflows/release.yml). Merges do not publish. Every workflow dispatch performs a real release unless it is a dry run. Bundler's local `rake release` tasks are disabled, so releases can't bypass the workflow.

## One-Time Setup

Create a GitHub environment named `release` in this repository. Restrict deployment to `master` and require approval when available.

On [RubyGems.org](https://rubygems.org/gems/fue/trusted_publishers), configure a trusted publisher with repository owner `dblock`, repository name `fue`, workflow filename `release.yml`, and environment `release`. Set the separate workflow repository owner to `dblock` and name to `ruby-gem-release` because publication uses its reusable workflow. No stored RubyGems API key is needed.

The workflow requests `contents: write` and `id-token: write`. Branch rules must allow the release identity to push fast-forward release and next-version commits to `master` and create tags, without allowing force pushes or deletion. Adding the workflow does not configure these permissions or the trusted publisher.

To verify this setup without releasing, dispatch a dry run. It runs in the `release` environment and only checks release prerequisites, including RubyGems Trusted Publishing and that the release identity can push to `master`; it never edits files, tags, pushes, builds, or publishes.

```sh
gh workflow run release.yml --ref master -f dry-run=true
```

## Prepare and Publish

Prepare the intended version in `lib/fue/version.rb` and its matching `### VERSION (Next)` section in `CHANGELOG.md` through a PR. Keep exactly one `* Your contribution here.` placeholder in that section. The workflow releases the current version, dates the changelog, and removes the placeholder; it does not select a new release version.

Run tests and RuboCop locally and review the release changes before merging:

```sh
bundle exec rake
```

After merging, explicit release approval, and successful Trusted Publishing setup, dispatch from `master`:

```sh
gh workflow run release.yml --ref master
```

The workflow verifies Trusted Publishing and push access, validates release preconditions, prepares the changelog, runs `bundle exec rake`, and preserves verified recovery artifacts before publication. It then publishes the verified gem to RubyGems, pushes the release commit and tag atomically, and creates a GitHub Release with the gem attached. Finally, it increments the patch version and pushes a new development commit with a fresh changelog section. Actions-token pushes do not trigger ordinary push workflows, so the release workflow runs tests and RuboCop before publication.

## Verify and Recover

Verify the published RubyGems version, matching tag and GitHub Release, attached gem, and next development version on `master`.

Never automatically rerun a failed or timed-out publication: RubyGems may have accepted the upload. Check registry and GitHub state first. Do not republish an existing version or move its tag. Available `release.gem`, `release.json`, and `release.bundle` recovery artifacts are retained for 30 days; follow the [upstream recovery instructions](https://github.com/dblock/ruby-gem-release/blob/v0.9.0/RELEASING.md#verify-and-recover) to complete only the missing steps.
