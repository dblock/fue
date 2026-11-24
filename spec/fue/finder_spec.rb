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
      expect(finder.emails(username: 'defunkt', breadth: 50)).to contain_exactly(
        'Chris Wanstrath <2+defunkt@users.noreply.github.com>',
        'Chris Wanstrath <chris@ozmm.org>',
        'defunkt <chris@ozmm.org>'
      )
    end

    it 'excludes names', vcr: { cassette_name: 'github/find/defunkt' } do
      expect(finder.emails(username: 'defunkt', breadth: 50, exclude_names: true)).to contain_exactly(
        '2+defunkt@users.noreply.github.com',
        'chris@ozmm.org'
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

    it 'looks through more than 100 commits in a repository' do
      history = lambda do |email, has_next_page|
        {
          nodes: [{ author: { name: 'Name', email: email }, message_body: '' }],
          page_info: { has_next_page: has_next_page, end_cursor: 'cursor' }
        }
      end
      first_ref = { target: { history: history.call('first@example.com', true) } }
      next_ref = { target: { history: history.call('next@example.com', false) } }
      first_page = RecursiveOpenStruct.new(
        {
          data: {
            user: {
              repositories: {
                nodes: [{ name_with_owner: 'owner/repo', default_branch_ref: first_ref }],
                page_info: { start_cursor: nil }
              }
            }
          }
        },
        recurse_over_arrays: true
      )
      next_page = RecursiveOpenStruct.new(
        { data: { repository: { default_branch_ref: next_ref } } },
        recurse_over_arrays: true
      )
      expect(finder).to receive(:author_id).and_return('MDQ6VXNlcjI=')
      expect(graphql_client).to receive(:query).with(
        kind_of(String),
        hash_including(depth: 100, breadth: 1, is_fork: false)
      ).ordered.and_return(first_page)
      expect(graphql_client).to receive(:query).with(
        kind_of(String),
        hash_including(owner: 'owner', name: 'repo', depth: 50, cursor: 'cursor')
      ).ordered.and_return(next_page)
      expect(finder.emails(username: 'defunkt', depth: 150, breadth: 1)).to eq(
        ['Name <first@example.com>', 'Name <next@example.com>']
      )
    end

    context 'with request sizes' do
      let(:server_error) do
        Graphlient::Errors::FaradayServerError.new(Faraday::ServerError.new('502', { status: 502, body: '' }))
      end

      before do
        allow(finder).to receive(:author_id).and_return('MDQ6VXNlcjI=')
      end

      it 'looks into fewer repositories per request when looking into more commits' do
        expect(graphql_client).to receive(:query).with(
          kind_of(String), hash_including(depth: 100, breadth: 2, is_fork: false)
        )
        allow(graphql_client).to receive(:query).with(kind_of(String), hash_including(is_fork: true))
        finder.emails(username: 'defunkt', depth: 100, breadth: 10, is_fork: false)
      end

      it 'retries a failed request with fewer repositories' do
        expect(graphql_client).to receive(:query).with(
          kind_of(String), hash_including(depth: 10, breadth: 20, is_fork: false)
        ).ordered.and_raise(server_error)
        expect(graphql_client).to receive(:query).with(
          kind_of(String), hash_including(depth: 10, breadth: 10, is_fork: false)
        ).ordered.and_raise(Faraday::ParsingError.new('unexpected end of input'))
        expect(graphql_client).to receive(:query).with(
          kind_of(String), hash_including(depth: 10, breadth: 5, is_fork: false)
        ).ordered.and_raise(Graphlient::Errors::TimeoutError.new('timeout'))
        expect(graphql_client).to receive(:query).with(
          kind_of(String), hash_including(depth: 10, breadth: 2, is_fork: false)
        ).ordered.and_return(nil)
        allow(graphql_client).to receive(:query).with(kind_of(String), hash_including(is_fork: true)).and_return(nil)
        expect(finder.emails(username: 'defunkt', depth: 10, breadth: 100)).to eq []
      end

      it 'does not retry client errors' do
        unauthorized = Faraday::UnauthorizedError.new('401', { status: 401 })
        client_error = Graphlient::Errors::FaradayServerError.new(unauthorized)
        expect(graphql_client).to receive(:query).once.and_raise(client_error)
        expect { finder.emails(username: 'defunkt', depth: 10, breadth: 100) }.to raise_error(client_error)
      end

      it 'gives up when a request for one repository fails' do
        # 100, 50, 25, 12, 6, 3 and 1 repositories
        expect(graphql_client).to receive(:query).exactly(7).times.and_raise(server_error)
        expect { finder.emails(username: 'defunkt', depth: 1, breadth: 100) }.to raise_error(server_error)
      end
    end

    it 'treats noreply@github.com as a no-reply e-mail' do
      expect(finder.send(:noreply?, 'GitHub <noreply@github.com>')).to be true
      expect(finder.send(:noreply?, 'dblock <542335+dblock@users.noreply.github.com>')).to be true
      expect(finder.send(:noreply?, 'dblock <dblock@dblock.org>')).to be false
    end

    it 'finds e-mails in forks', vcr: { cassette_name: 'github/find/lundefugl' } do
      expect(finder.emails(username: 'lundefugl')).to eq(['lundefugl <montgomery_scott@gmx.de>'])
    end

    it 'pages backwards through more than 100 repositories', vcr: { cassette_name: 'github/find/dblock_breadth_142' } do
      expect(finder).to receive(:author_id).and_return('MDQ6VXNlcjU0MjMzNQ==')
      expect(graphql_client).to receive(:query).with(
        kind_of(String),
        hash_including(depth: 1, breadth: 100, cursor: nil)
      ).ordered.and_call_original
      expect(graphql_client).to receive(:query).with(
        kind_of(String),
        hash_including(depth: 1, breadth: 42, cursor: kind_of(String))
      ).ordered.and_call_original
      finder.emails(username: 'dblock', depth: 1, breadth: 142, exclude_signed_off_by: true)
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

    it 'skips contributors without e-mail addresses',
       vcr: { cassette_name: 'github/contributors/opensearch-project/opensearch-sdk-py' } do
      allow(finder).to receive(:emails).and_return(['someone@example.com'])
      allow(finder).to receive(:emails).with(hash_including(username: 'ignacia-kihn')).and_return([])
      contributors = finder.contributors(repo: 'opensearch-project/opensearch-sdk-py', exclude_noreply: true)
      expect(contributors.keys).to eq(
        ['mend-for-github-com[bot]', 'dependabot[bot]', 'isaac_gerlach', 'carroll', 'dblock']
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

  describe '#mentions' do
    let(:repo) { 'opensearch-project/opensearch-sdk-py' }

    it 'mentions contributors without an e-mail address',
       vcr: { cassette_name: 'github/contributors/opensearch-project/opensearch-sdk-py' } do
      allow(finder).to receive(:emails).and_return(['someone@example.com'])
      expect(finder).to receive(:emails).with(hash_including(username: 'carroll', exclude_noreply: true)).and_return([])
      expect(finder.mentions(repo: repo)).to eq ['@carroll']
    end

    it 'mentions all contributors without bots',
       vcr: { cassette_name: 'github/contributors/opensearch-project/opensearch-sdk-py' } do
      expect(finder).not_to receive(:emails)
      expect(finder.mentions(repo: repo, all: true)).to eq ['@isaac_gerlach', '@carroll', '@ignacia-kihn', '@dblock']
    end

    it 'skips contributors whose e-mail addresses cannot be found',
       vcr: { cassette_name: 'github/contributors/opensearch-project/opensearch-sdk-py' } do
      allow(finder).to receive(:emails).and_return([])
      expect(finder).to receive(:emails).with(hash_including(username: 'dblock')).and_raise('Not Found')
      expect { expect(finder.mentions(repo: repo)).not_to include '@dblock' }.to output(/Not Found/).to_stderr
    end
  end
end
