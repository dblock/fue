require 'spec_helper'

describe Fue::Finder do
  let(:token) { 'token' }
  let(:finder) { Fue::Finder.new(token) }
  it 'finds all e-mails', vcr: { cassette_name: 'github/defunkt' } do
    expect(finder.emails(username: 'defunkt')).to eq([
                                                       'Chris Wanstrath <chris@ozmm.org>',
                                                       'Chris Wanstrath <chris@github.com>'
                                                     ])
  end
end
