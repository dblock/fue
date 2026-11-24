# frozen_string_literal: true

module Fue
  # Reads tokens saved in the macOS keychain by fue 0.5.0 and older.
  module Security
    class << self
      def get(options)
        Fue::Shell.system!(find_command(options))
      rescue RuntimeError, SystemCallError
        nil
      end

      private

      def find_command(options)
        [
          security_path,
          'find-internet-password',
          "-a #{Shellwords.escape(options[:username])}",
          "-s #{Shellwords.escape(options[:server])}",
          ("-l #{Shellwords.escape(options[:label])}" if options[:label]),
          '-w'
        ].compact.join(' ')
      end

      def security_path
        @security_path ||= begin
          path = `which security`.chomp
          path.empty? ? 'security' : path
        rescue StandardError
          'security'
        end
      end
    end
  end
end
