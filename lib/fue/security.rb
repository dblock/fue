module Fue
  module Security
    class << self
      def store!(options)
        system!(security('add', options))
      end

      def get(options)
        system!(security('find', options))
      rescue RuntimeError
        nil
      end

      private

      def security(command = nil, options = nil)
        run = [security_path]
        run << "#{command}-internet-password"
        run << "-a #{options[:username]}"
        run << "-s #{options[:server]}"
        if command == 'add'
          run << "-l #{options[:label]}"
          run << '-U'
          run << "-w #{options[:password]}" if options.key?(:password)
        else
          run << '-w'
        end
        run.join ' '
      end

      def security_path
        @security_path ||= begin
          `which security`.chomp
        rescue StandardError
          'security'
        end
      end

      def system!(*cmd)
        stdout, _, status = Open3.capture3(*cmd)
        raise "failed with exit code #{status}" unless status.success?
        stdout.slice!(0..-(1 + $INPUT_RECORD_SEPARATOR.size))
      end
    end
  end
end
