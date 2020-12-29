module Teamwork
  module Commands
    class Version < CommandBase
      desc "Print version"

      def call
        puts Teamwork::VERSION
      end
    end
  end
end
