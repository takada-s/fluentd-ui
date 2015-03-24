# for read Fluent::TextParser::TEMPLATE_REGISTRY
require "fluent/registry"
require "fluent/configurable"
require "fluent/parser"

class RegexpPreview
  attr_reader :file, :format, :params, :time_format, :regexp

  def initialize(file, format, params = {}, options = {})
    @file = file
    @format = format
    @params = params
    case format
    when "regexp"
      @regexp = Regexp.new(options[:regexp])
      @time_format = options[:time_format]
    when "multiline"
    when "ltsv", "json", "csv", "tsv"
    else
      definition = Fluent::TextParser::TEMPLATE_REGISTRY.lookup(format).call
      raise "Unknown format '#{format}'" unless definition
      definition.configure({}) # NOTE: SyslogParser define @regexp in configure method so call it to grab Regexp object
      @regexp = definition.patterns["format"]
      @time_format = definition.patterns["time_format"]
    end
  end

  def matches
    return [] unless @regexp # such as ltsv, json, etc
    reader = FileReverseReader.new(File.open(file))
    matches = reader.tail.map do |line|
      result = {
        :whole => line,
        :matches => [],
      }
      m = line.match(regexp)
      next result unless m

      m.names.each_with_index do |name, index|
        result[:matches] << {
          key: name,
          matched: m[name],
          pos: m.offset(index + 1),
        }
      end
      result
    end
    matches
  end

  def matches_multiline
    return [] unless multiline_regexps.empty?
    stack = multiline_regexps.dup
    buf = []
    reader.tail.map do |line|
      if line.match(stack.last)
      end
      if stack.empty?
        stack = multiline_regexps.dup
      end
    end
  end

  def multiline_regexps
    regexps = (1..20).reverse.map do |n|
      params["format#{n}"]
    end
    regexps << params[:format_firstline]
    regexps.compact
  end
end


id = condition_key.match(/[0-9]+\z/).to_i
if condition_key.start_with?("cource_id")
  {
    course_id: id
  }
elsif condition_key.start_with?("managed_check_id")
  {
    managed_check_id: id,
    class: managed_check_id,
  }
end
