module VER
  module_function

  def info(message = nil, color = nil)
    return @info unless message
    @info.info_color = color if color
    @info.info = message
    @info
  end

  def status(message = nil, color = nil)
    return @info unless message
    @info.status_color = color if color
    @info.status = message
    @info
  end

  def ask(question = nil, completer = nil, &block)
    return @ask unless question and completer
    @ask.open(question, completer, &block)
  end

  def choice(question = nil, choices = nil, &block)
    return @choice unless question and choices
    @choice.open(question, choices, &block)
  end

  def complete; @complete end

  def warn(message)
    # info(message)
    Log.warn(message)
  end

  # F1
  def help(topic = 'index')
    require 'ver/view/ask/doc'
    doc = View::AskDoc.new
    doc.open
  end

=begin
    help = View[:help]
    help.topic = topic
    View.active = help
=end

  # F2
  def doc(regexp)
    require 'ver/view/doc'
    doc = View::Doc.new(:doc)
    doc.open(regexp)
  end

  def error(exception, message = nil)
    if @last_error_message = message
      Log.error(message)
    end

    @last_error = exception
    Log.error(exception)
    info(exception.inspect)
    # View[:error].error(message, exception)
  end
end
