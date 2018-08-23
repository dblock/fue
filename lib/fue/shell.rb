module Fue
  module Shell
    class << self
      def system!(*cmd)
        stdout, _, status = Open3.capture3(*cmd)
        raise "failed with exit code #{status}" unless status.success?
        stdout.slice!(0..-(1 + $INPUT_RECORD_SEPARATOR.size))
      end
    end
  end
end
