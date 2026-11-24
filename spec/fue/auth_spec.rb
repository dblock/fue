# frozen_string_literal: true

require 'spec_helper'

describe Fue::Auth do
  describe '#username' do
    it 'returns nil without a git username' do
      expect(Fue::Shell).to receive(:system!).with('git config user.name').and_return(nil)
      expect(subject.username).to be_nil
    end

    it 'returns nil with an empty git username' do
      expect(Fue::Shell).to receive(:system!).with('git config user.name').and_return('')
      expect(subject.username).to be_nil
    end

    it 'returns nil without git' do
      expect(Fue::Shell).to receive(:system!).with('git config user.name').and_raise(Errno::ENOENT, 'git')
      expect(subject.username).to be_nil
    end

    it 'returns and chomps the git username' do
      expect(Fue::Shell).to receive(:system!).with('git config user.name').and_return("user\n")
      expect(subject.username).to eq 'user'
    end

    it 'does not prompt' do
      expect(Fue::Shell).to receive(:system!).with('git config user.name').and_return(nil)
      expect($stdin).not_to receive(:gets)
      expect { subject.username }.not_to output.to_stdout
    end
  end

  describe '#token' do
    subject(:auth) { described_class.new }

    let(:keychain_options) { { username: 'user', server: 'github.com', label: 'fue' } }

    before do
      allow(Fue::Shell).to receive(:system!).with('git config user.name').and_return('user')
      stub_const('RUBY_PLATFORM', 'arm64-darwin25')
    end

    it 'returns the GitHub CLI token' do
      expect(Fue::Shell).to receive(:system!).with('gh auth token').and_return('gh-token')
      expect(Fue::Security).not_to receive(:get)
      expect(auth.token).to eq 'gh-token'
      expect(auth.token_source).to eq 'gh auth token'
    end

    it 'falls back to the keychain when the GitHub CLI is not installed' do
      expect(Fue::Shell).to receive(:system!).with('gh auth token').and_raise(Errno::ENOENT, 'gh')
      expect(Fue::Security).to receive(:get).with(keychain_options).and_return('stored')
      expect(auth.token).to eq 'stored'
      expect(auth.token_source).to eq 'the macOS keychain'
    end

    it 'falls back to the keychain when the GitHub CLI is not logged in' do
      expect(Fue::Shell).to receive(:system!).with('gh auth token').and_raise(
        RuntimeError, "exit code 1\nno oauth token found for github.com"
      )
      expect(Fue::Security).to receive(:get).with(keychain_options).and_return('stored')
      expect(auth.token).to eq 'stored'
    end

    it 'ignores an empty GitHub CLI token' do
      expect(Fue::Shell).to receive(:system!).with('gh auth token').and_return('')
      expect(Fue::Security).to receive(:get).and_return('stored')
      expect(auth.token).to eq 'stored'
    end

    it 'does not look in the keychain outside macOS' do
      stub_const('RUBY_PLATFORM', 'x86_64-linux')
      expect(Fue::Shell).to receive(:system!).with('gh auth token').and_raise(Errno::ENOENT, 'gh')
      expect(Fue::Security).not_to receive(:get)
      expect { auth.token }.to raise_error Fue::Auth::TokenNotFoundError, /gh auth login/
    end

    it 'does not look up a username when the GitHub CLI has a token' do
      expect(Fue::Shell).to receive(:system!).with('gh auth token').and_return('gh-token')
      expect(Fue::Shell).not_to receive(:system!).with('git config user.name')
      expect(auth.token).to eq 'gh-token'
    end

    it 'uses a configured username for the keychain' do
      auth.username = 'configured'
      expect(Fue::Shell).to receive(:system!).with('gh auth token').and_raise(Errno::ENOENT, 'gh')
      expect(Fue::Security).to receive(:get).with(keychain_options.merge(username: 'configured')).and_return('stored')
      expect(auth.token).to eq 'stored'
    end

    it 'skips the keychain without a username' do
      allow(Fue::Shell).to receive(:system!).with('git config user.name').and_return(nil)
      expect(Fue::Shell).to receive(:system!).with('gh auth token').and_raise(Errno::ENOENT, 'gh')
      expect(Fue::Security).not_to receive(:get)
      expect { auth.token }.to raise_error Fue::Auth::TokenNotFoundError
    end

    it 'raises an error when no token is found' do
      expect(Fue::Shell).to receive(:system!).with('gh auth token').and_raise(Errno::ENOENT, 'gh')
      expect(Fue::Security).to receive(:get).and_return(nil)
      expect { auth.token }.to raise_error(
        Fue::Auth::TokenNotFoundError,
        'No GitHub token found. Run `gh auth login`, or pass --token or set GITHUB_ACCESS_TOKEN.'
      )
    end
  end
end
