require 'openid/store/memcache'

class OpenIdStore < OpenID::Store::Memcache

  def initialize
    super(Rails.cache.instance_variable_get("@data"))
  end

  def store_association(*args)
    RAILS_DEFAULT_LOGGER.debug ["store_association", args].inspect
    super
  end

  def remove_association(*args)
    RAILS_DEFAULT_LOGGER.debug ["remove_association", args].inspect
    super
  end

  def use_nonce(*args)
    RAILS_DEFAULT_LOGGER.debug ["use_nonce", args].inspect
    super
  end

end