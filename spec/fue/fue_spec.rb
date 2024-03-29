# frozen_string_literal: true

require 'spec_helper'

describe Fue do
  let(:fue) { File.expand_path(File.join(__FILE__, '../../../bin/fue')) }

  context 'find' do
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
