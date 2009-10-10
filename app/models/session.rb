class Session

  attr_accessor :email
  attr_accessor :openid_url

  def gmail?
    openid_url.blank?
  end

  def openid_url_or_gmail
    openid_url.blank? ? "https://www.google.com/accounts/o8/id" : openid_url
  end

  def initialize(attributes={})
    attributes ||= {}
    self.email = attributes[:email]
    self.openid_url = attributes[:openid_url]
  end

end
