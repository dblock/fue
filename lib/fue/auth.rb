# frozen_string_literal: true

module Fue
  class Auth
    def self.instance
      @instance ||= new
    end

    def token
      stored_options = { username: username, server: 'github.com', label: 'fue' }
      stored_token = Fue::Security.get(stored_options)
      unless stored_token
        stored_token = github_token
        Fue::Security.store!(stored_options.merge(password: stored_token))
        puts 'Token saved to keychain.'
      end
      stored_token
    end

    def username
      @username ||= begin
        username = get_git_username&.chomp
        username = get_username if username.nil? || username.empty?
        username
      end
    end

    private

    def github_token(_code = nil)
      puts 'Create a personal access token on https://github.com/settings/tokens: '
      get_secure
    end

    def get_git_username
      Fue::Shell.system!('git config user.name')
    rescue RuntimeError
      nil
    end

    def get_username
      print 'Enter GitHub username: '
      username = $stdin.gets
      username&.chomp
    rescue Interrupt => e
      raise e, 'ctrl + c'
    end

    def get_secure
      current_tty = `stty -g`
      system 'stty raw -echo -icanon isig' if $CHILD_STATUS.success?
      input = String.new
      while (char = $stdin.getbyte) && !((char == 13) || (char == 10))
        if (char == 127) || (char == 8)
          input[-1, 1] = '' unless input.empty?
        else
          $stdout.write '*'
          input << char.chr
        end
      end
      print "\r\n"
      input
    rescue Interrupt => e
      raise e, 'ctrl + c'
    ensure
      system "stty #{current_tty}" unless current_tty.empty?
    end
  end
end
