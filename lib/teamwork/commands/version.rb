# frozen_string_literal: true

module Teamwork
  module Commands
    # no doc
    class Version < CommandBase
      desc 'Print version'

      def call
        puts Teamwork::VERSION
      end
    end
  end
end
