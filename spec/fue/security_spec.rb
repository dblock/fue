# frozen_string_literal: true

require 'spec_helper'

describe Fue::Security do
  before do
    allow(described_class).to receive(:security_path).and_return('security-exec')
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

    it 'returns nil when the security command is not available' do
      expect(Fue::Shell).to receive(:system!).and_raise(Errno::ENOENT, 'security-exec')
      expect(subject.get(username: 'user', server: 'server', label: 'fue')).to be_nil
    end

    it 'quotes usernames' do
      expect(Fue::Shell).to receive(:system!).with(
        'security-exec find-internet-password -a user\\ name -s server -w'
      )
      subject.get(username: 'user name', server: 'server')
    end
  end
end
