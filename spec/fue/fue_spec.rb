# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

describe Fue do
  let(:fue) { File.expand_path(File.join(__FILE__, '../../../bin/fue')) }

  describe 'find' do
    describe 'default' do
      subject do
        Fue::Shell.system!(['ruby', %("#{fue}")].join(' '))
      end

      it 'displays help' do
        expect(subject).to include "fue - Find a GitHub user's e-mail address."
      end

      it 'displays version' do
        expect(subject).to include Fue::VERSION
      end
    end

    describe 'without a token' do
      it 'explains how to authenticate' do
        Dir.mktmpdir do |dir|
          if Gem.win_platform?
            gh = "@echo off\r\necho no oauth token found for github.com 1>&2\r\nexit /b 1\r\n"
            File.write(File.join(dir, 'gh.cmd'), gh)
          else
            gh = File.join(dir, 'gh')
            File.write(gh, "#!/bin/sh\necho 'no oauth token found for github.com' >&2\nexit 1\n")
            File.chmod(0o755, gh)
          end
          # only a logged out gh, ruby, and the Windows system directory, no git or security
          path = [dir, RbConfig::CONFIG['bindir']]
          path << File.join(ENV.fetch('SystemRoot'), 'System32') if Gem.win_platform?
          env = {
            'PATH' => path.join(File::PATH_SEPARATOR),
            'GITHUB_ACCESS_TOKEN' => nil,
            'GH_TOKEN' => nil,
            'GITHUB_TOKEN' => nil
          }
          stdout, stderr, status = Open3.capture3(env, RbConfig.ruby, fue, 'find', 'dblock', stdin_data: '')
          expect(status).not_to be_success
          expect(stderr).to include Fue::Auth::TokenNotFoundError.new.message
          expect(stdout).not_to include 'Token saved'
          expect(stdout).not_to include 'Enter GitHub username'
        end
      end
    end

    describe 'help' do
      subject do
        Fue::Shell.system!(['ruby', %("#{fue}"), 'help'].join(' '))
      end

      it 'displays help' do
        expect(subject).to include "fue - Find a GitHub user's e-mail address."
      end
    end
  end
end
