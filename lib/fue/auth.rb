# frozen_string_literal: true

module Fue
  class Auth
    class TokenNotFoundError < StandardError
      def initialize
        super('No GitHub token found. Run `gh auth login`, or pass --token or set GITHUB_ACCESS_TOKEN.')
      end
    end

    attr_reader :token_source
    attr_writer :username

    def self.instance
      @instance ||= new
    end

    # A token from the GitHub CLI, or one saved in the macOS keychain by fue 0.5.0 and older.
    def token
      @token ||= find_token
    end

    def username
      @username ||= begin
        username = git_username&.chomp
        username unless username.nil? || username.empty?
      end
    end

    private

    def find_token
      if (token = gh_token)
        @token_source = 'gh auth token'
      elsif (token = keychain_token)
        @token_source = 'the macOS keychain'
      else
        raise TokenNotFoundError
      end
      token
    end

    def gh_token
      token = Fue::Shell.system!('gh auth token')
      token unless token.nil? || token.empty?
    rescue RuntimeError, SystemCallError
      nil
    end

    def keychain_token
      return unless RUBY_PLATFORM.include?('darwin') && username

      Fue::Security.get(username: username, server: 'github.com', label: 'fue')
    end

    def git_username
      Fue::Shell.system!('git config user.name')
    rescue RuntimeError, SystemCallError
      nil
    end
  end
end
