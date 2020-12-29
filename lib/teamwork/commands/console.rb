
module Teamwork
  module Commands

    class Console < CommandBase
      desc "teamwork console"

      def call 
        info
        exec "bundle exec irb -r teamwork"
      end
    end
  end
end
