# frozen_string_literal: true

module Teamwork
  module Commands
    # no doc
    class Console < CommandBase
      desc 'teamwork console'

      def call
        info
        exec 'bundle exec irb -r teamwork'
      end
    end
  end
end
