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
      query_options = {
        login: options[:username],
        author_id: author_id(options[:username]),
        # max number of commits to look into
        depth: options[:depth] || 1
      }

      $stdout.write "Searching for emails for #{options[:username]} ." if options[:verbose]

      emails = repository_emails(query_options, options.merge(is_fork: false))
      # users who only commit to their forks, see https://github.com/dblock/fue/issues/26
      emails = repository_emails(query_options, options.merge(is_fork: true)) if emails.empty?

      puts " found #{emails.size} email address#{'es' unless emails.size == 1}." if options[:verbose]

      emails.to_a
    end

    def contributors(options = {})
      contributor_logins(options).filter_map do |login|
        login_emails = emails(options.merge(username: login))
        # skip contributors without e-mail addresses, e.g. with only excluded @users.noreply.github.com ones
        [login, login_emails] unless login_emails.empty?
      rescue StandardError => e
        warn e
      end.to_h
    end

    # @logins of contributors without an e-mail address other than @users.noreply.github.com ones,
    # or of all contributors with all: true, without bots
    def mentions(options = {})
      logins = contributor_logins(options).reject { |login| login.end_with?('[bot]') }
      return logins.map { |login| "@#{login}" } if options[:all]

      logins.filter_map do |login|
        "@#{login}" if emails(options.merge(username: login, exclude_noreply: true)).empty?
      rescue StandardError => e
        warn e
      end
    end

    private

    def contributor_logins(options)
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
        query_options[:cursor] = history&.page_info&.end_cursor
        $stdout.write '.' if options[:verbose]
        break unless query_options[:cursor]
      end

      puts " found #{logins.size} contributor#{'s' unless logins.size == 1}." if options[:verbose]

      logins.to_a
    end

    def repository_emails(query_options, options)
      query = <<-GRAPHQL
        query($login: String!, $author_id: ID!, $depth: Int!, $breadth: Int!, $cursor: String, $is_fork: Boolean!) {
          user(login: $login) {
            repositories(last: $breadth, after: $cursor, isFork: $is_fork, privacy: PUBLIC) {
              nodes {
                nameWithOwner
                defaultBranchRef {
                  target {
                    ... on Commit {
                      history(first: $depth, author: { id: $author_id }) {
                        nodes {
                          author {
                            email
                            name
                          },
                          messageBody
                        }
                        pageInfo {
                          hasNextPage
                          endCursor
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
      # max number of commits to look into in each repository, GitHub returns at most 100 at a time
      max_depth = query_options[:depth]
      query_options = query_options.merge(is_fork: options[:is_fork], cursor: nil, depth: [max_depth, 100].min)
      emails = Set.new

      loop do
        query_options[:breadth] = [max_breadth, 100].min
        response = graphql_client.query(query, query_options)
        repositories = response&.data&.user&.repositories
        repositories&.nodes&.each do |repository|
          history = repository.default_branch_ref&.target&.history
          add_history_emails(emails, history, options)
          more_history_emails(emails, repository, history, query_options[:author_id], max_depth - 100, options)
        end
        query_options[:cursor] = repositories&.page_info&.start_cursor
        break unless query_options[:cursor]

        max_breadth -= 100
        break if max_breadth <= 0

        $stdout.write '.' if options[:verbose]
      end

      emails
    end

    # pages through a repository's history beyond the first 100 commits
    def more_history_emails(emails, repository, history, author_id, remaining, options)
      query = <<-GRAPHQL
        query($owner: String!, $name: String!, $author_id: ID!, $depth: Int!, $cursor: String) {
          repository(owner: $owner, name: $name) {
            defaultBranchRef {
              target {
                ... on Commit {
                  history(first: $depth, after: $cursor, author: { id: $author_id }) {
                    nodes {
                      author {
                        email
                        name
                      },
                      messageBody
                    }
                    pageInfo {
                      hasNextPage
                      endCursor
                    }
                  }
                }
              }
            }
          }
        }
      GRAPHQL

      return unless remaining.positive?

      owner, name = repository.name_with_owner.to_s.split('/', 2)

      while remaining.positive? && history&.page_info&.has_next_page
        response = graphql_client.query(
          query,
          owner: owner,
          name: name,
          author_id: author_id,
          depth: [remaining, 100].min,
          cursor: history.page_info.end_cursor
        )
        history = response&.data&.repository&.default_branch_ref&.target&.history
        add_history_emails(emails, history, options)
        remaining -= 100
        $stdout.write '.' if options[:verbose]
      end
    end

    def add_history_emails(emails, history, options)
      history&.nodes&.each do |node|
        unless noreply?(node.author.email) && options[:exclude_noreply]
          emails << format_email(node.author.name, node.author.email, options)
        end

        next if options[:exclude_signed_off_by]

        node.message_body.match(/^Signed-off-by: (?<email>[^\r\n]*)$/) do |m|
          email = m[:email]
          next if noreply?(email) && options[:exclude_noreply]

          emails << (options[:exclude_names] ? email[/<([^>]+)>/, 1] || email : email)
        end
      end
    end

    def format_email(name, email, options)
      options[:exclude_names] ? email : "#{name} <#{email}>"
    end

    def noreply?(email)
      email.include?('@users.noreply.github.com')
    end

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
