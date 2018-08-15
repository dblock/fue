module Fue
  class Finder
    attr_reader :token

    def initialize(token, _options = {})
      @token = token
    end

    def author_id(username)
      query = <<-GRAPHQL
        query($login: String!) {
          user(login: $login) {
            id
          }
        }
      GRAPHQL
      graphql_client.query(query, login: username).data.user.id
    end

    def emails(options = {})
      query = <<-GRAPHQL
        query($login: String!, $author_id: ID!, $depth: Int!) {
          user(login: $login) {
            repositories(last: $depth, isFork:false, privacy: PUBLIC) {
              edges {
                node {
                  defaultBranchRef {
                    target {
                      ... on Commit {
                        history(first: 1, author: { id: $author_id }) {
                          nodes {
                            author {
                              email
                              name
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      GRAPHQL

      query_options = {
        login: options[:username],
        author_id: author_id(options[:username]),
        depth: (options[:depth] || 10).to_i
      }

      graphql_client.query(query, query_options).data.user.repositories.edges.map do |edge|
        next unless edge.node.default_branch_ref
        edge.node.default_branch_ref.target.history.nodes.map do |node|
          "#{node.author.name} <#{node.author.email}>"
        end
      end.flatten.compact.uniq
    end

    private

    def graphql_client
      @graphql_client ||= Graphlient::Client.new(
        'https://api.github.com/graphql',
        headers: {
          'Authorization' => "Bearer #{token}",
          'Content-Type' => 'application/json'
        }
      )
    end
  end
end
