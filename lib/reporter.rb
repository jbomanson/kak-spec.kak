#! /usr/bin/env -S ruby --disable=gems

require "shellwords"

STARTUP_MONOTONIC_TIME = Process.clock_gettime(Process::CLOCK_MONOTONIC)

DEBUG_EXPECTED_CONTENT = <<EOF
*** This is the debug buffer, where debug info will be written ***

EOF

LINE_NUMBER_COLOR      = :blue
NEWLINE_MARKER_COLOR   = :blue
TITLE_COLOR            = :cyan
LIST_ITEM_BULLET_COLOR = :cyan

# Returns a magic string used in messages.
def kak_spec_delimiter
  $kak_spec_delimiter ||= ENV["KAK_SPEC_DELIMITER"]
end

# Returns a temporary directory set up by kak-spec.
def kak_spec_dir
  $kak_spec_dir ||= ENV["KAK_SPEC_DIR"]
end

# Returns a path to the kak-spec program.
def kak_spec_program
  $kak_spec_program ||= ENV["KAK_SPEC_PROGRAM"]
end

def newline_marker
  $newline_marker ||= Terminal.in_color("¬", NEWLINE_MARKER_COLOR)
end

def kak_spec_reporter_color
  $kak_spec_reporter_color ||= (ENV["KAK_SPEC_REPORTER_color"] || "auto")
end

def list_item_bullet
  @list_item_bullet ||= Terminal.in_color("-", LIST_ITEM_BULLET_COLOR) + " "
end

TEST_CASE_KAKOUNE_COMMAND_NAME = "kak-spec"

class TranslationException < StandardError
end

module Terminal
  extend self

  def enabled?
    (@@enabled ||= [kak_spec_reporter_color == "always" || (kak_spec_reporter_color == "auto" && STDOUT.tty?)]).first
  end

  # Wraps a string with terminal color codes.
  def in_color(text, color)
    # TODO: Disable if the output is not a terminal.
    return text unless enabled?
    # Source of color codes:
    # https://misc.flogisoft.com/bash/tip_colors_and_formatting
    code =
      case color
      when :red                      then 31
      when :green                    then 32
      when :yellow                   then 33
      when :blue                     then 34
      when :magenta                  then 35
      when :cyan                     then 36
      when :light_gray               then 37
      when :dark_gray                then 90
      when :light_red                then 91
      when :light_green              then 92
      when :light_yellow             then 93
      when :light_blue               then 94
      when :light_magenta            then 95
      when :light_cyan               then 96
      when :white                    then 97
      when :default_background       then 49
      when :black_background         then 40
      when :red_background           then 41
      when :green_background         then 42
      when :yellow_background        then 43
      when :blue_background          then 44
      when :magenta_background       then 45
      when :cyan_background          then 46
      when :light_gray_background    then 47
      when :dark_gray_background     then 100
      when :light_red_background     then 101
      when :light_green_background   then 102
      when :light_yellow_background  then 103
      when :light_blue_background    then 104
      when :light_magenta_background then 105
      when :light_cyan_background    then 106
      when :white_background         then 107
      else raise "Unrecognized color: #{color}"
      end
    "\e[#{code}m#{text}\e[0m"
  end

  # Highlight any trailing whitespace in given lines with terminal color codes.
  # @return [String]
  def any_trailing_whitespace_in_color(line)
    # Highlight trailing whitespace.
    line.gsub(/[[:blank:]]+$/) {|text| Terminal.in_color(text, :red_background)}
  end

  def format_title(io, level, content)
    io.puts Terminal.in_color(("#" * level) + " " + content, TITLE_COLOR)
    io.puts
  end
end

def throw(*args)
  raise TranslationException.new(*args)
end

TestCase = Struct.new(:scope, :title, :input, :evaluated_commands) do
  # Returns a shell command in the form of a string that reruns this specific
  # test case alone.
  # @return [String]
  def shell_command_details
    [
      kak_spec_program,
      "-title",
      "^#{Regexp.escape(title)}$",
      scope.suite_file,
    ].shelljoin
  end
end

# Mark all newlines with a visible character.
def mark_newlines_explicitly(string)
  string.gsub(/\n/, "#{newline_marker}\n")
end

def format_block_content(io, text, indent = "    ", is_empty_special = false)
  if is_empty_special && text.empty?
    io << Terminal.in_color(indent, LINE_NUMBER_COLOR)
    io.puts
  else
    text.each_line.each_with_index do |line, line_index|
      io << Terminal.in_color("#{indent}%3i|" % (line_index + 1), LINE_NUMBER_COLOR)
      io << mark_newlines_explicitly(Terminal.any_trailing_whitespace_in_color(line))
      io.puts unless line.end_with?("\n")
    end
  end
end

def format_block(io, title, text, indent = "    ")
  io.puts list_item_bullet + title + ":"
  format_block_content(io, text, indent)
  io.puts
end

def format_array(io, title, text_array)
  io.puts list_item_bullet + "#{title} with #{text_array.size} #{text_array.size == 1 ? "element" : "elements"}:"
  text_array.each_with_index do |text, array_index|
    format_block_content(io, text, "    %3s:" % (array_index + 1), true)
  end
  io.puts
end

# An object representing a comparisiong between an actual and expected value of a kakoune kakoune_expansion.
Comparison = Struct.new(:type, :kakoune_expansion, :expected_array, :actual_array) do
  def self.extract_array(array)
    unless delimiter_index = array.index(kak_spec_delimiter)
      throw \
        "Expected an array of arguments ending in a magic delimiter, but got " +
        array.shelljoin
    end
    array.shift(delimiter_index).tap { array.shift }
  end

  # Parses expectation message components sent with kak-spec.
  def self.partition_and_create_from_arguments(array)
    comparisons = []
    remaining_arguments = array.clone
    until remaining_arguments.first == "END_OF_EXPECTATIONS"
      if remaining_arguments.empty?
        throw "Missing 'END_OF_EXPECTATIONS' from assertion message: #{array}"
      end
      scalar_arguments = remaining_arguments.shift(self.members.size - 2)
      if scalar_arguments.any?(&:nil?)
        throw \
          "Undefined arguments for comparison in #{scalar_arguments} #{remaining_arguments}"
      end
      comparisons << self.new(
        # Assign all but the last two fields to individual arguments.
        *scalar_arguments,
        # Assign the last two fields to sequences of arguments.
        extract_array(remaining_arguments),
        extract_array(remaining_arguments),
      )
    end
    remaining_arguments.shift
    [comparisons, remaining_arguments]
  end

  # Formats details of this expectation to an {IO} -- {#pass?} ed or not.
  def format_details(io)
    if pass?
      if type == "comparison_explicit"
        format_array(io, "Accepted #{kakoune_expansion}", expected_array)
      end
    else
      format_array(io, "Expected #{kakoune_expansion}", expected_array)
      format_array(io, "Actual #{kakoune_expansion}", actual_array)
    end
  end

  # Determines whether this expectation passed.
  def pass?
    expected_array == actual_array
  end
end

module Assertion
  # <context_file> <output> <error> <assertion> <arg>...
  def self.from_arguments(scope, array)
    comparisons, remaining_arguments = Comparison.partition_and_create_from_arguments(array)
    # Unpack the arguments.
    title, input, evaluated_commands = remaining_arguments
    # Convert the arguments into higher level objects.
    Assertion::WithComparisons.new(
      TestCase.new(scope, title, input, evaluated_commands),
      comparisons,
    )
  end

  # Determines whether this assertion was satisfied.
  def pass?
    raise "NYI"
  end

  def progress_tick
    if pass?
      Terminal.in_color(".", :green)
    else
      Terminal.in_color("F", :red)
    end
  end

  # Assuming this assertion did not {#pass?}, returns a description of the relevant details.
  def failure_details(io)
    Terminal.format_title(io, 3, test_case.title)
  end
end

module Assertion
  # An assertion that is satisfied if a number of {Comparison} objects are satisfied.
  WithComparisons = Struct.new(:test_case, :comparisons) do
    include Assertion

    # Implements {Assertion#pass?}.
    def pass?
      if @pass.nil?
        @pass = comparisons.all?(&:pass?)
      end
      @pass
    end

    # Prints details of this assertion.
    def failure_details(io)
      super
      unless test_case.input.empty?
        format_block(io, "Input", test_case.input)
      end
      format_block(io, "Evaluated commands", test_case.evaluated_commands)
      comparisons.each do |expectation|
        expectation.format_details(io)
      end
      unless test_case.scope.debug.empty?
        format_block(io, "Contents of *debug*", test_case.scope.debug)
      end
      format_block(io, "How to run this test", test_case.shell_command_details)
    end
  end
end

# An error caught in kakoune code outside of assertions.
# These errors are reported separately from assertion failures.
NonAssertionError = Struct.new(:scope, :message) do
  def progress_tick
    Terminal.in_color("E", :red)
  end

  def non_assertion_error_details(io)
    Terminal.format_title(io, 3, "Error")
    scope.each_with_index do |context_scope, index|
      format_block(
        io,
        index == 0 ? "Suite" : "Context",
        context_scope.description,
      )
    end
    format_block(io, "Message", message)
    unless scope.debug.empty?
      format_block(io, "Contents of *debug*", scope.debug)
    end
  end
end

class Presenter
  attr_reader :assertions
  attr_reader :io
  attr_reader :non_assertion_errors

  def initialize(io)
    @assertions = []
    @io = io
    @non_assertion_errors = []
    Terminal.format_title(io, 1, "kak-spec")
  end

  def present_assertion(assertion)
    @assertions << assertion
    @io.print assertion.progress_tick
  end

  def present_error(error)
    @non_assertion_errors << error
    @io.print error.progress_tick
  end

  def failure_count
    @failure_count ||= assertions.count { |assertion| !assertion.pass? }
  end

  def pass?
    non_assertion_errors.empty? && failure_count == 0
  end

  def present_failed_example_details
    return if failure_count == 0
    Terminal.format_title(@io, 2, "Failures")
    assertions.each_with_index do |assertion, index|
      next if assertion.pass?
      assertion.failure_details(@io)
    end
  end

  # Summarises failed examples in a way that shows files and line numbers.
  def present_non_assertion_error_summary
    return if non_assertion_errors.empty?
    Terminal.format_title(@io, 2, "Errors other than assertion failures")
    non_assertion_errors.each do |error|
      error.non_assertion_error_details(@io)
    end
  end

  def present_summary_briefly
    elapsed_time =
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - STARTUP_MONOTONIC_TIME
    Terminal.format_title(@io, 2, "Summary")
    @io.puts list_item_bullet + "Finished in %0.2f milliseconds" % (elapsed_time * 1000.0)
    @io.puts list_item_bullet + Terminal.in_color(
      "#{assertions.size} examples, " +
      "#{failure_count} failures, " +
      "#{non_assertion_errors.size} errors",
      pass? ? :green : :red
    )
  end

  def present_summary
    # Print two newlines: one to end any progress ticks and another to separate the ticks from
    # what follows.
    @io.puts
    @io.puts
    present_failed_example_details
    present_summary_briefly
    @io.puts unless non_assertion_errors.empty?
    present_non_assertion_error_summary
  end
end

def stubbornly
  begin
    yield
  rescue TranslationException => e
    puts
    puts e
  rescue StandardError => e
    puts
    puts "Caught unexpected Ruby exception: #{e}"
    puts e.backtrace
    puts
  end
end

# A wrapper over an IO for reading messages sent with the kakoune command `kak-spec-send`.
class MessageReader
  def initialize(io)
    # An IO object that will be set to nil after the first time it returns nil.
    @io = io
  end

  # Reads the next message as an array of strings.
  # The order in which messages are read is exactly the same as in which they are sent via the
  # kakoune command `kak-spec-send`.
  # Returns nil once there are no more messages.
  # @return [Array<String>, nil]
  def read_message
    if @io
      # Read lines until the first newline outside of kakoune-style single quotes.
      message_string = ""
      num_quotes = 0
      while true
        unless line = @io.gets
          @io = nil
          message_string.empty? ? return : break
        end
        message_string << line
        num_quotes += line.count("'")
        break if num_quotes % 2 == 0
      end
      message_string.chomp!
      unless message_string.start_with?("'") && message_string.end_with?("'")
        throw "Bad message_string: #{message_string}"
      end
      # Parse an array quoted by kakoune using single quotes (') to surround elements
      # and doubled-up single quotes ('') to escape regular single quotes.
      message_string.scan(/'(?:[^']|'')*'/).map do |quoted_element|
        quoted_element[1..-2].gsub("''", "'")
      end
    end
  end

  # Yields all remaining messages one by one.
  # @yieldparam [Array<String>]
  def each
    while message = read_message
      yield message
    end
  end

  # Returns an {Enumerable} consisting of all messages until target_message.
  # Using the enumerable will advance this {MessageReader} until and over the target message.
  def until_message(target_message_task)
    UntilMessage.new(self, target_message_task)
  end

  # This is an implementation detail of {MessageReader#until_message}.
  class UntilMessage
    include Enumerable

    attr_reader :target_message

    def initialize(reader, target_message_task)
      @reader = reader
      @target_message_task = target_message_task
    end

    def each
      @reader.each do |message|
        if message.first == @target_message_task
          @target_message = message
          break
        else
          yield message
        end
      end
    end
  end
end

Scope = Struct.new(:parent, :description, :debug_line_begin) do
  include Enumerable

  attr_accessor :debug
  attr_accessor :debug_line_end

  def self.top_level
    @top_level ||= Scope.new(nil, "Top Level", 0)
  end

  def each
    return unless parent
    parent.each {|parent_scope| yield parent_scope}
    yield self
  end

  def suite_file
    first.description
  end
end

# Parses a debug line number sent as part of scope messages into an integer.
def parse_debug_line_number(number_as_string)
  # Deduct 1 because kakoune always maintains an extra empty line at the end of the debug buffer.
  number_as_string.to_i - 1
end

# A wrapper class that helps implement state machines.
StateMachine = Struct.new(:state) do
  def transition(method_name, *args)
    unless new_state = state.send(method_name, *args)
      raise "BUG: State #{state}##{method_name} -> #{new_state}"
    end
    self.state = new_state
  end
end

module MessageHandler
  Uninitiated = Struct.new(:presenter) do
    def handle_message(task, session, client)
      unless task == "message_init" && session && client
        throw "Expected message_init <session> <client>, received: #{[task, session, client]}"
      end
      Initiated.new(*values, session, client)
    end
  end

  Initiated = Struct.new(*Uninitiated.members, :session, :client) do
    def scope_stack
      @scope_stack ||= [Scope.top_level]
    end

    def scope_universe
      @scope_universe ||= []
    end

    def handle_message(task, *arguments)
      case task.chomp
      when "message_assert"
        presenter.present_assertion(Assertion.from_arguments(scope_stack.last, arguments))
      when "message_non_assertion_error"
        presenter.present_error(NonAssertionError.new(scope_stack.last, arguments.join(" ")))
      when "message_scope_begin"
        description, debug_line_begin = arguments
        scope_stack << Scope.new(scope_stack.last, description, parse_debug_line_number(debug_line_begin))
        scope_universe << scope_stack.last
      when "message_scope_end"
        description, debug_line_end = arguments
        if scope_stack.last.description == description
          scope_stack.pop.debug_line_end = parse_debug_line_number(debug_line_end)
        else
          throw \
            "Expected end of scope #{scope_stack.last}, " +
            "got end of scope #{description}"
        end
      else
        throw "Unexpected task: #{([task] + arguments).shelljoin}"
      end
      self
    end

    def finish(source_file, debug_buffer_lines)
      # Attribute debug information to the appropriate scopes.
      scope_universe.reverse_each do |scope|
        lines = debug_buffer_lines[scope.debug_line_begin...scope.debug_line_end]
        scope.debug = lines.join
        lines.each(&:clear)
      end
      # Print any unaccounted debug values.
      unless (stray_debug_message = debug_buffer_lines.join) == DEBUG_EXPECTED_CONTENT
        presenter.io.puts
        presenter.io.puts "P.S.:"
        format_block(
          presenter.io,
          "Contents of *debug* that oddly did not fall into any context in '#{source_file}'",
          stray_debug_message,
        )
      end
      system("echo 'evaluate-commands -client #{client} %(kak-spec-quit-end)' | kak -p #{session}")
      Finished.new
    end
  end

  class Finished
  end
end

Main = Struct.new(:presenter) do
  # Reads commands from a fifo until the "quit" command arrives.
  # The commands can consist of one or more lines.
  # The first line must indicate the type of the command.
  def handle_fifo(source_file, fifo)
    unless File.exist?(fifo)
      raise "Missing fifo '#{fifo}' for source '#{source_file}'"
    end
    machine = StateMachine.new(MessageHandler::Uninitiated.new(presenter))
    File.open(fifo, "r") do |io|
      message_reader = MessageReader.new(io)
      machine.transition(:handle_message, *message_reader.read_message)
      until_reader = message_reader.until_message("message_quit")
      until_reader.to_a.each do |message_components|
        stubbornly do
          machine.transition(:handle_message, *message_components)
        end
      end
      machine.transition(
        :finish,
        source_file,
        until_reader.target_message.last.each_line.to_a,
      )
    end
  end

  def main(kak_spec_arguments)
    kak_spec_arguments.each_with_index do |argument, index|
      handle_fifo(argument, File.join(kak_spec_dir, index.to_s + ".fifo"))
    end
    # Present a summary of assertions.
    presenter.present_summary
  end
end

begin
  Main.new(Presenter.new(STDOUT)).main(ARGV.clone)
rescue => e
  puts e.to_s
  puts e.backtrace
end
