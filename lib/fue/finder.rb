# frozen_string_literal: true

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
        query($login: String!, $author_id: ID!, $depth: Int!, $breadth: Int!, $cursor: String) {
          user(login: $login) {
            repositories(last: $breadth, after: $cursor, isFork:false, privacy: PUBLIC) {
              nodes {
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
              pageInfo {
                startCursor
              }
            }
          }
        }
      GRAPHQL

      # max number of repositories to search
      max_breadth = options[:breadth] || 10

      query_options = {
        login: options[:username],
        author_id: author_id(options[:username]),
        # max number of commits to look into
        depth: options[:depth] || 1
      }

      $stdout.write "Searching for emails for #{options[:username]} ." if options[:verbose]

      emails = Set.new

      loop do
        query_options[:breadth] = [max_breadth, 100].min
        response = graphql_client.query(query, query_options)
        repositories = response&.data&.user&.repositories
        repositories&.nodes&.each do |history|
          default_history = history.default_branch_ref&.target&.history
          default_history&.nodes&.each do |node|
            next if node.author.email.end_with?('@users.noreply.github.com') && !!options[:exclude_noreply]

            emails << "#{node.author.name} <#{node.author.email}>"
          end
        end
        query_options[:cursor] = repositories&.page_info&.start_cursor
        break unless query_options[:cursor]

        max_breadth -= 100
        break if max_breadth <= 0

        $stdout.write '.' if options[:verbose]
      end

      puts " found #{emails.size} email address#{emails.size == 1 ? '' : 'es'}." if options[:verbose]

      emails.to_a
    end

    def contributors(options = {})
      query = <<-GRAPHQL
        query($owner: String!, $name: String!, $cursor: String) {
          repository(owner: $owner, name: $name) {
            defaultBranchRef {
              target {
                ... on Commit {
                  history(first: 100, after: $cursor) {
                    nodes {
                      author {
                        user {
                          login
                        }
                      }
                    }
                    pageInfo {
                      endCursor
                    }
                  }
                }
              }
            }
          }
        }
      GRAPHQL

      repo_owner, repo_name = options[:repo].split('/', 2)

      query_options = {
        owner: repo_owner,
        name: repo_name
      }

      logins = Set.new

      $stdout.write 'Fetching contributors .' if options[:verbose]

      loop do
        response = graphql_client.query(query, query_options)
        history = response&.data&.repository&.default_branch_ref&.target&.history
        history&.nodes&.each do |node|
          login = node.author.user&.login
          logins << login if login
        end
        query_options[:cursor] = history&.page_info.end_cursor
        $stdout.write '.' if options[:verbose]
        break unless query_options[:cursor]
      end

      puts " found #{logins.size} contributor#{logins.size == 1 ? '' : 's'}." if options[:verbose]

      logins.map do |login|
        [login, emails(options.merge(username: login))]
      rescue StandardError => e
        warn e
      end.compact.to_h
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
