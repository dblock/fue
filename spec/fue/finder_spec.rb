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
    expect(finder.send(:graphql_client)).to receive(:query).with(
      kind_of(String),
      hash_including(depth: 1, breadth: 2)
    ).and_return(nil)
    finder.emails(username: 'defunkt', depth: 1, breadth: 2)
  end

  it 'paginates over more than 100 items' do
    expect(finder).to receive(:author_id).and_return('id')
    expect(finder.send(:graphql_client)).to receive(:query).with(
      kind_of(String),
      hash_including(depth: 1, breadth: 100)
    ).and_return(nil)
    expect(finder.send(:graphql_client)).to receive(:query).with(
      kind_of(String),
      hash_including(depth: 1, breadth: 42)
    ).and_return(nil)
    finder.emails(username: 'defunkt', depth: 1, breadth: 142)
  end
end
