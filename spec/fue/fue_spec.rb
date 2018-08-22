require 'spec_helper'

describe Fue do
  let(:fue) { File.expand_path(File.join(__FILE__, '../../../bin/fue')) }
  context 'find' do
    describe '#help' do
      it 'displays help by default' do
        help = `"#{fue}"`
        expect(help).to include "fue - Find a Github user's e-mail address."
      end
      it 'displays help' do
        help = `"#{fue}" help`
        expect(help).to include "fue - Find a Github user's e-mail address."
      end
      it 'displays version' do
        help = `"#{fue}"`
        expect(help).to include Fue::VERSION
      end
    end
  end
end
