# frozen_string_literal: true

require 'spec_helper'

describe Fue::Finder do
  let(:token) { ENV['GITHUB_ACCESS_TOKEN'] || 'token' }
  let(:finder) { described_class.new(token) }
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
      expect(finder.emails(username: 'defunkt', breadth: 50)).to eq(
        [
          'Chris Wanstrath <2+defunkt@users.noreply.github.com>',
          'Chris Wanstrath <chris@ozmm.org>',
          'defunkt <chris@ozmm.org>'
        ]
      )
    end

    it 'excludes names', vcr: { cassette_name: 'github/find/defunkt' } do
      expect(finder.emails(username: 'defunkt', breadth: 50, exclude_names: true)).to eq(
        [
          '2+defunkt@users.noreply.github.com',
          'chris@ozmm.org'
        ]
      )
    end

    it 'adjusts depth and breadth, then searches forks when nothing was found' do
      expect(finder).to receive(:author_id).and_return('MDQ6VXNlcjI=')
      expect(finder.send(:graphql_client)).to receive(:query).with(
        kind_of(String),
        hash_including(depth: 1, breadth: 2, is_fork: false)
      ).ordered.and_return(nil)
      expect(finder.send(:graphql_client)).to receive(:query).with(
        kind_of(String),
        hash_including(depth: 1, breadth: 2, is_fork: true)
      ).ordered.and_return(nil)
      expect(finder.emails(username: 'defunkt', depth: 1, breadth: 2)).to eq([])
    end

    it 'finds e-mails in forks', vcr: { cassette_name: 'github/find/lundefugl' } do
      expect(finder.emails(username: 'lundefugl')).to eq(['lundefugl <montgomery_scott@gmx.de>'])
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
    it 'excludes no-reply emails', vcr: { cassette_name: 'github/contributors/opensearch-project/opensearch-sdk-py' } do
      expect(
        finder.contributors(repo: 'opensearch-project/opensearch-sdk-py', exclude_noreply: true)
      ).to eq(
        'ignacia-kihn' => [
          'Catina <catina.barton@senger.test>'
        ],
        'dblock' => [
          'DB <dblock@dblock.org>',
          'DB <dblock@example.com>',
          'dblock <dblock@example.com>'
        ],
        'isaac_gerlach' => [
          'Isaac Gerlach <otelia@rolfson.test>',
          'Isaac Gerlach Signed <otelia-signed-by@rolfson.test>'
        ],
        'carroll' => ['Hobert Ondricka <yolande_simonis@mckenzie.example>']
      )
    end

    it 'excludes signed off by', vcr: { cassette_name: 'github/contributors/opensearch-project/opensearch-sdk-py' } do
      expect(
        finder.contributors(repo: 'opensearch-project/opensearch-sdk-py', exclude_signed_off_by: true)
      ).to eq(
        'ignacia-kihn' => [
          'Ignacia Kihn <83948568+ignacia-kihn@users.noreply.github.com>',
          'Catina <catina.barton@senger.test>'
        ],
        'dblock' => [
          'DB <dblock@dblock.org>',
          'DB <dblock@example.com>',
          'dblock <dblock@example.com>'
        ],
        'isaac_gerlach' => ['Isaac Gerlach <otelia@rolfson.test>'],
        'carroll' => ['Hobert Ondricka <yolande_simonis@mckenzie.example>']
      )
    end

    it 'excludes both no-reply and signed off by',
       vcr: { cassette_name: 'github/contributors/opensearch-project/opensearch-sdk-py' } do
      expect(
        finder.contributors(
          repo: 'opensearch-project/opensearch-sdk-py',
          exclude_noreply: true,
          exclude_signed_off_by: true
        )
      ).to eq(
        'ignacia-kihn' => [
          'Catina <catina.barton@senger.test>'
        ],
        'dblock' => [
          'DB <dblock@dblock.org>',
          'DB <dblock@example.com>',
          'dblock <dblock@example.com>'
        ],
        'isaac_gerlach' => ['Isaac Gerlach <otelia@rolfson.test>'],
        'carroll' => ['Hobert Ondricka <yolande_simonis@mckenzie.example>']
      )
    end

    it 'excludes names', vcr: { cassette_name: 'github/contributors/opensearch-project/opensearch-sdk-py' } do
      expect(finder.contributors(repo: 'opensearch-project/opensearch-sdk-py', exclude_names: true)).to eq(
        'ignacia-kihn' => [
          '83948568+ignacia-kihn@users.noreply.github.com',
          'catina.barton@senger.test'
        ],
        'dblock' => [
          'dblock@dblock.org',
          'dblock@example.com'
        ],
        'isaac_gerlach' => [
          'otelia@rolfson.test',
          'otelia-signed-by@rolfson.test'
        ],
        'carroll' => ['yolande_simonis@mckenzie.example']
      )
    end

    it 'finds e-mails', vcr: { cassette_name: 'github/contributors/opensearch-project/opensearch-sdk-py' } do
      expect(finder.contributors(repo: 'opensearch-project/opensearch-sdk-py')).to eq(
        'ignacia-kihn' => [
          'Ignacia Kihn <83948568+ignacia-kihn@users.noreply.github.com>',
          'Catina <catina.barton@senger.test>'
        ],
        'dblock' => [
          'DB <dblock@dblock.org>',
          'DB <dblock@example.com>',
          'dblock <dblock@example.com>'
        ],
        'isaac_gerlach' => [
          'Isaac Gerlach <otelia@rolfson.test>',
          'Isaac Gerlach Signed <otelia-signed-by@rolfson.test>'
        ],
        'carroll' => ['Hobert Ondricka <yolande_simonis@mckenzie.example>']
      )
    end
  end
end
