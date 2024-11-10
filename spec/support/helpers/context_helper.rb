# frozen_string_literal: true

require 'tempfile'

module ContextHelper
  def create_result(options)
    # Here is compatibility with Ruby 2.4
    @result_class ||= ::Struct.new(*options.keys)
    @result_class.new.tap { |result| options.each { |key, value| result[key] = value } }
  end

  def create_file
    ::Tempfile.new(['temporary_spec', '.rb'])
  end
end
