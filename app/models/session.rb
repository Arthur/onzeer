class Session

  attr_accessor :email

  def initialize(attributes={})
    attributes ||= {}
    self.email = attributes[:email]
  end

end
