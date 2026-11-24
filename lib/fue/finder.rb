# frozen_string_literal: true

module Fue
  class Finder
    # GitHub times out or truncates responses with many more commits, stay well below that
    MAX_COMMITS_PER_REQUEST = 200

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
            repositories(last: $breadth, before: $cursor, isFork: $is_fork, privacy: PUBLIC) {
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
                hasPreviousPage
              }
            }
          }
        }
      GRAPHQL

      # max number of repositories to search
      max_breadth = options[:breadth] || 10
      # max number of commits to look into in each repository, GitHub returns at most 100 at a time
      max_depth = query_options[:depth]
      depth = [max_depth, 100].min
      query_options = query_options.merge(is_fork: options[:is_fork], cursor: nil, depth: depth)
      # repositories per request, fewer when looking into more commits in each
      page_size = (MAX_COMMITS_PER_REQUEST / depth).clamp(1, 100)
      emails = Set.new

      while max_breadth.positive?
        query_options[:breadth] = [max_breadth, page_size].min
        response = query_with_retry(query, query_options) do
          page_size = [page_size / 2, 1].max
          query_options[:breadth] = [max_breadth, page_size].min
        end
        repositories = response&.data&.user&.repositories
        repositories&.nodes&.each do |repository|
          history = repository.default_branch_ref&.target&.history
          add_history_emails(emails, history, options)
          more_history_emails(emails, repository, history, query_options[:author_id], max_depth - 100, options)
        end
        # repositories are listed oldest first, page backwards from the most recent
        break unless repositories&.page_info&.has_previous_page

        query_options[:cursor] = repositories.page_info.start_cursor
        max_breadth -= query_options[:breadth]

        $stdout.write '.' if options[:verbose]
      end

      emails
    end

    # Retries a request that GitHub could not complete, after the block makes it smaller.
    def query_with_retry(query, query_options)
      graphql_client.query(query, query_options)
    rescue Graphlient::Errors::TimeoutError, Faraday::ParsingError, Graphlient::Errors::FaradayServerError => e
      raise if e.is_a?(Graphlient::Errors::FaradayServerError) && e.status_code.to_i < 500
      raise if query_options[:breadth] <= 1

      yield
      retry
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

        node.message_body.scan(/^Signed-off-by: ([^\r\n]*)$/).flatten.each do |email|
          next if noreply?(email) && options[:exclude_noreply]
          next unless signed_off_by_author?(email, node.author, options[:username])

          emails << (options[:exclude_names] ? email[/<([^>]+)>/, 1] || email : email)
        end
      end
    end

    # A Signed-off-by line belongs to the commit author when its name or e-mail address matches
    # the author's name, the author's e-mail address, or the user's GitHub login, ignoring case.
    def signed_off_by_author?(signed_off_by, author, login)
      name = signed_off_by[/\A([^<]*)</, 1]&.strip
      email = signed_off_by[/<([^>]+)>/, 1]
      candidates = [author.name, author.email, login].compact.map(&:downcase)
      ([name, email].compact.map(&:downcase) & candidates).any?
    end

    def format_email(name, email, options)
      options[:exclude_names] ? email : "#{name} <#{email}>"
    end

    # GitHub's addresses that don't receive e-mail, including noreply@github.com on commits made on github.com
    def noreply?(email)
      email.include?('@users.noreply.github.com') || email.include?('noreply@github.com')
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
