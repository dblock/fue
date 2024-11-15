# frozen_string_literal: true

module Fue
  module Security
    class << self
      def store!(options)
        Fue::Shell.system!(security('add', options))
      end

      def get(options)
        Fue::Shell.system!(security('find', options))
      rescue RuntimeError
        nil
      end

      private

      def security(command = nil, options = nil)
        run = [security_path]
        run << "#{command}-internet-password"
        run << "-a #{Shellwords.escape(options[:username])}"
        run << "-s #{Shellwords.escape(options[:server])}"
        if command == 'add'
          run << "-l #{Shellwords.escape(options[:label])}"
          run << '-U'
          run << "-w #{Shellwords.escape(options[:password])}" if options.key?(:password)
        else
          run << '-w'
        end
        run.join ' '
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
