# frozen_string_literal: true

require 'spec_helper'

describe Fue::Finder do
  let(:token) { ENV['GITHUB_ACCESS_TOKEN'] || 'token' }
  let(:finder) { Fue::Finder.new(token) }
  let(:graphql_client) { finder.send(:graphql_client) }

  describe '#find' do
    it 'excludes @noreply e-mails', vcr: { cassette_name: 'github/find/defunkt' } do
      expect(finder.emails(username: 'defunkt', breadth: 50, exclude_noreply: true)).to eq(
        [
          'Chris Wanstrath <chris@ozmm.org>',
          'defunkt <chris@ozmm.org>'
        ]
      )
    end

    it 'finds all e-mails', vcr: { cassette_name: 'github/find/defunkt' } do
      expect(finder.emails(username: 'defunkt', breadth: 50, exclude_noreply: false)).to eq(
        [
          'Chris Wanstrath <chris@ozmm.org>',
          'Chris Wanstrath <defunkt@users.noreply.github.com>',
          'defunkt <chris@ozmm.org>'
        ]
      )
    end

    it 'adjusts depth and breadth' do
      expect(finder).to receive(:author_id).and_return('MDQ6VXNlcjI=')
      expect(finder.send(:graphql_client)).to receive(:query).with(
        kind_of(String),
        hash_including(depth: 1, breadth: 2)
      ).and_return(nil)
      finder.emails(username: 'defunkt', depth: 1, breadth: 2)
    end

    it 'paginates over more than 100 items', vcr: { cassette_name: 'github/find/defunkt_breadth_142' } do
      expect(finder).to receive(:author_id).and_return('MDQ6VXNlcjI=')
      expect(finder.send(:graphql_client)).to receive(:query).with(
        kind_of(String),
        hash_including(depth: 1, breadth: 100)
      ).and_call_original
      expect(finder.send(:graphql_client)).to receive(:query).with(
        kind_of(String),
        hash_including(depth: 1, breadth: 42)
      ).and_call_original
      finder.emails(username: 'defunkt', depth: 1, breadth: 142)
    end
  end

  describe '#contributors' do
    it 'finds e-mails', vcr: { cassette_name: 'github/contributors/colored' } do
      expect(finder.contributors(repo: 'defunkt/colored', exclude_noreply: true)).to eq(
        'defunkt' => ['Chris Wanstrath <chris@ozmm.org>'],
        'kch' => []
      )
    end

    it 'finds e-mails', vcr: { cassette_name: 'github/contributors/colored' } do
      expect(finder.contributors(repo: 'defunkt/colored', exclude_noreply: false)).to eq(
        'defunkt' => ['Chris Wanstrath <chris@ozmm.org>'],
        'kch' => ['Caio Chassot <dev@users.noreply.github.com>']
      )
    end
  end
end
