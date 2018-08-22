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
        query($login: String!, $author_id: ID!, $depth: Int!, $breadth: Int!, $breadthCursor: String) {
          user(login: $login) {
            repositories(last: $breadth, after: $breadthCursor, isFork:false, privacy: PUBLIC) {
              edges {
                cursor
                node {
                  defaultBranchRef {
                    target {
                      ... on Commit {
                        history(first: $depth, author: { id: $author_id }) {
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

      max_breadth = options[:breadth] || 10

      query_options = {
        login: options[:username],
        author_id: author_id(options[:username]),
        depth: options[:depth] || 1
      }

      emails = Set.new

      loop do
        query_options[:breadth] = [max_breadth, 100].min
        response = graphql_client.query(query, query_options)
        edges = response.data.user.repositories.edges if response
        if edges
          edges.each do |edge|
            query_options[:breadthCursor] = edge.cursor
            branch_ref = edge.node.default_branch_ref
            next unless branch_ref
            branch_ref.target.history.nodes.each do |node|
              emails << "#{node.author.name} <#{node.author.email}>"
            end
          end
        end
        max_breadth -= 100
        break if max_breadth <= 0
      end

      emails.to_a
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
