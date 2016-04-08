# A base class for all command handlers.
class SmsCommandHandler
  def can_handle?(_sms_text)
    true
  end

  def failure_message
    'Not a valid command.'
  end

  def handle(_sms_text)
    nil
  end
end
