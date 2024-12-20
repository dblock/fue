# frozen_string_literal: true

require 'spec_helper'

describe Fue::Auth do
  context 'username' do
    context 'without a username configured' do
      before do
        expect(Fue::Shell).to receive(:system!).with('git config user.name').and_return(nil)
      end

      it 'prompts for a username and otherwise returns nil' do
        expect(subject).to receive(:get_username).and_return(nil)
        expect(subject.username).to be_nil
      end

      it 'prompts for a username and returns it' do
        expect(subject).to receive(:get_username).and_return('username')
        expect(subject.username).to eq 'username'
      end

      it 'reads the username from stdin and chomps it' do
        expect($stdin).to receive(:gets).and_return("username\n")
        expect(subject.username).to eq 'username'
      end
    end

    context 'with a username configured' do
      it 'returns username' do
        expect(Fue::Shell).to receive(:system!).with('git config user.name').and_return('user')
        expect(subject).not_to receive(:get_username)
        expect(subject.username).to eq 'user'
      end

      it 'chomps username' do
        expect(Fue::Shell).to receive(:system!).with('git config user.name').and_return("user\n")
        expect(subject).not_to receive(:get_username)
        expect(subject.username).to eq 'user'
      end
    end
  end

  context 'with a previously stored token' do
    before do
      expect(Fue::Shell).to receive(:system!).with('git config user.name').and_return('user')
      expect(Fue::Security).to receive(:get).with(
        {
          username: 'user',
          label: 'fue',
          server: 'github.com'
        }).and_return('stored')
    end

    it 'returns token' do
      expect(Fue::Auth.instance.token).to eq 'stored'
    end
  end

  context 'without a previously stored token' do
    before do
      expect(Fue::Security).to receive(:get).and_return(nil)
    end

    it 'returns token' do
      expect(Fue::Auth.instance).to receive(:get_secure).and_return('secure')
      expect(Fue::Security).to receive(:store!).with(
        {
          username: 'user',
          label: 'fue',
          password: 'secure',
          server: 'github.com'
        }
      )
      expect(Fue::Auth.instance.token).to eq 'secure'
    end
  end
end
