# frozen_string_literal: true

module RuboCop
  module Cop
    module Vibe
      # Shared helper methods for spec file handling.
      module SpecFileHelper
        SPEC_FILE_PATTERN = %r{spec/.*_spec\.rb}

        private

        # Check if file is a spec file.
        #
        # @return [Boolean]
        def spec_file?
          processed_source.file_path.match?(SPEC_FILE_PATTERN)
        end
      end
    end
  end
end
