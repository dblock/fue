# frozen_string_literal: true

require 'spec_helper'

describe Fue::Shell do
  describe '#system!' do
    it 'returns a zero error code' do
      expect(described_class.system!('echo OK')).to eq 'OK'
    end

    it 'removes a trailing CRLF' do
      status = instance_double(Process::Status, success?: true)
      expect(Open3).to receive(:capture3).and_return(["token\r\n", '', status])
      expect(described_class.system!('gh auth token')).to eq 'token'
    end

    it 'keeps output without a trailing newline' do
      status = instance_double(Process::Status, success?: true)
      expect(Open3).to receive(:capture3).and_return(['token', '', status])
      expect(described_class.system!('gh auth token')).to eq 'token'
    end

    it 'returns a non zero error code' do
      expect do
        described_class.system!('exit 1')
      end.to raise_error RuntimeError, /exit code pid \d* exit 1/
    end
  end
end
