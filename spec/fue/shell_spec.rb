# frozen_string_literal: true

require 'spec_helper'

describe Fue::Shell do
  describe '#system!' do
    it 'returns a zero error code' do
      expect(Fue::Shell.system!('echo OK')).to eq 'OK'
    end

    it 'returns a non zero error code' do
      expect do
        Fue::Shell.system!('exit 1')
      end.to raise_error RuntimeError, /exit code pid \d* exit 1/
    end
  end
end
