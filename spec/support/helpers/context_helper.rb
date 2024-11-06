# frozen_string_literal: true

require 'tempfile'

module ContextHelper
  def create_result(options)
    @result_class ||= ::Struct.new(*options.keys, keyword_init: true)
    @result_class.new(**options)
  end

  def create_file
    ::Tempfile.new(['temporary_spec', '.rb'])
  end
end
