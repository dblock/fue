require 'spec_helper'

describe Fue::Finder do
  let(:token) { 'token' }
  let(:finder) { Fue::Finder.new(token) }
  let(:graphql_client) { finder.send(:graphql_client) }
  it 'finds all e-mails', vcr: { cassette_name: 'github/defunkt' } do
    expect(finder.emails(username: 'defunkt')).to eq(
      [
        'Chris Wanstrath <chris@ozmm.org>',
        'Chris Wanstrath <chris@github.com>'
      ]
    )
  end

  it 'adjusts depth and breadth' do
    expect(finder).to receive(:author_id).and_return('id')
    data = RecursiveOpenStruct.new(
      data: {
        user: {
          repositories: {
            edges: []
          }
        }
      }
    )
    expect(finder.send(:graphql_client)).to receive(:query).with(
      kind_of(String),
      hash_including(depth: 1, breadth: 2)
    ).and_return(data)
    finder.emails(username: 'defunkt', depth: 1, breadth: 2)
  end
end
