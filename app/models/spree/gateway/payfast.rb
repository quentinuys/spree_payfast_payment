require 'uri'
class Spree::Gateway::Payfast < Spree::Gateway

  class_attribute :name_first, :name_last, :email_address, :m_payment_id, :amount
  preference :merchant_id, :string
  preference :merchant_key, :string
  preference :return_url, :string
  preference :notify_url, :string
  preference :cancel_url, :string

  def auto_capture?
    true
  end

  def amount
    @amount.to_f 
  end

  def custom_int
    #custom integer to be passed through
    9556
  end

  def custom_str
    #custom string to be passed through with the transaction to the notify_url page'
    "Test string to payfast"
  end

  def source_required?
    false
  end
  
  def payment_source_class
    Spree::CreditCard
  end

  def provider_class
    Spree::Gateway::Payfast
  end

  def method_type
    'payfast'
  end

  def purchase(amount, transaction_details, options = {}, products)

    ActiveMerchant::Billing::Response.new(true, 'success', {}, {})
  end

  def authorize(amount, transaction_details, options = {}, products)

    ActiveMerchant::Billing::Response.new(true, 'success', {}, {})
  end
end
