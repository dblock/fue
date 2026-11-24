# frozen_string_literal: true

require 'spec_helper'

describe Fue::Security do
  before do
    allow(described_class).to receive(:security_path).and_return('security-exec')
  end

  describe '#store!' do
    it 'returns an add command line' do
      expect(Fue::Shell).to receive(:system!).with(
        'security-exec add-internet-password -a user -s server -l label -U -w password'
      )
      subject.store!(username: 'user', server: 'server', password: 'password', label: 'label')
    end
  end

  describe '#get' do
    it 'returns a find command line' do
      expect(Fue::Shell).to receive(:system!).with(
        'security-exec find-internet-password -a user -s server -w'
      )
      subject.get(username: 'user', server: 'server')
    end

    it 'matches the label to avoid tokens stored by other tools' do
      expect(Fue::Shell).to receive(:system!).with(
        'security-exec find-internet-password -a user -s server -l fue -w'
      )
      subject.get(username: 'user', server: 'server', label: 'fue')
    end

    it 'quotes usernames' do
      expect(Fue::Shell).to receive(:system!).with(
        'security-exec find-internet-password -a user\\ name -s server -w'
      )
      subject.get(username: 'user name', server: 'server')
    end
  end
end
