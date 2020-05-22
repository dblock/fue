# frozen_string_literal: true

module Fue
  module Shell
    class << self
      def system!(*cmd)
        stdout, stderr, status = Open3.capture3(*cmd)
        raise ["exit code #{status}", stderr].compact.join("\n") unless status.success?

        stdout.slice!(0..-(1 + $INPUT_RECORD_SEPARATOR.size))
      end
    end
  end
end
