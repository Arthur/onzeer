class Session

  self.class_eval do
    extend ActiveModel::Naming
  end
  def to_key; []; end

  attr_accessor :email
  attr_accessor :openid_url
  attr_accessor :openid_provider

  def openid_provider_url
    case openid_provider
    when "google"
      "https://www.google.com/accounts/o8/id"
    when "yahoo"
      "https://me.yahoo.com/"
    else
      openid_url
    end
  end

  def initialize(attributes={})
    attributes ||= {}
    self.email = attributes[:email]
    self.openid_url = attributes[:openid_url]
    self.openid_provider = attributes[:openid_provider]
  end

end
