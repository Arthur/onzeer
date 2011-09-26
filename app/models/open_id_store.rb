require 'openid/store/memcache'

class OpenIdStore < OpenID::Store::Memcache

  def initialize
    super(Rails.cache.instance_variable_get("@data"))
  end

  def store_association(*args)
    RAILS_DEFAULT_LOGGER.info ["store_association", args].inspect
    super
  end

  def remove_association(*args)
    RAILS_DEFAULT_LOGGER.info ["remove_association", args].inspect
    super
  end

  def use_nonce(server_url, timestamp, salt)
    Rails.logger.info ["OpenIdStore", "use_nonce", server_url, timestamp, salt].inspect
    return false if (timestamp - Time.now.to_i).abs >  OpenID::Nonce.skew
    ts = timestamp.to_s # base 10 seconds since epoch
    nonce_key = key_prefix + 'N' + server_url + '|' + ts + '|' + salt
    result = @cache_client.add(nonce_key, '', expiry( OpenID::Nonce.skew + 5))
    # original method doesn't work with dally : check result =~ /^STORED/
    # see https://github.com/mperham/dalli/blob/master/Upgrade.md
    return result
  end

end
