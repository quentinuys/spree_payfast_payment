require 'digest/md5'
module Spree
  class PayfastReturnController < Spree::StoreController
    skip_before_filter  :verify_authenticity_token
    
    def success
      @order = current_order
      if @order.nil?
        PaymentMailer.payment_success().deliver_now!
        flash.notice = "Thank you. Your payment has been received and your order is being processed."
        flash['order_completed'] = true
        redirect_to '/'
      elsif !@order.paid? && @order.state == "payment"
        success_payment!
      else
        PaymentMailer.payment_failed("There has been an error on the current order number #{@order.number}. it should be nil. ").deliver_now!
        flash.notice = "There has been an error with your payment."
        redirect_to checkout_state_path(@order.state)
      end
      flash['order_completed'] = true
    end

    def notice
      logger.debug "Notice Method triggered..........."
      assign_params
      success_payment! if valid?
      if valid?
        head :ok
      else
        head :error
      end
    end

    def cancel
      @order = current_order
      PaymentMailer.payment_canceled("#{@order.number}").deliver_now!
      flash.notice = "Not happy with the payment system? Try another."
      redirect_to '/checkout/payment'
    end

    private

    def assign_params
      logger.debug "Assigning params: #{params}..........."
      @params = params
      @order = Spree::Order.find(@params[:m_payment_id])
    end

    def valid?
      PaymentMailer.payment_invalid("Payment status is not complete").deliver_now! unless successful_status?
      PaymentMailer.payment_invalid("Amount does not match").deliver_now! unless valid_amount?
      PaymentMailer.payment_invalid("Host not valid").deliver_now! unless valid_host?
      PaymentMailer.payment_invalid("Current Order status is already complete").deliver_now! unless not_processed?

      successful_status? && valid_amount? && valid_host? && not_processed? # && valid_signature? 
    end

    def successful_status?
      logger.debug "Check Success return......................."
      @params[:payment_status] == 'COMPLETE'
    end

    def valid_signature?
      logger.debug "Validating Signature......................."
      @signature = signature_url
      logger.debug "Got Signature URL...#{@signature}...................."
      @md5_encode = Digest::MD5.hexdigest(@signature)
      logger.debug "Got Encoded URL...#{@md5_encode}...................."
      @md5_encode == @params['signature']
    end

    def valid_amount?
      logger.debug "Validate amount..........#{@order.total.to_f}............."
      @params['amount_gross'].to_f === @order.total.to_f
    end

    def valid_host?
      logger.debug "Validate host.........#{request.host}.............."
      valid_hosts = %W{'www.payfast.co.za' 'sandbox.payfast.co.za' 'w1w.payfast.co.za' 'w2w.payfast.co.za' 'localhost' 'zook-staging.herokuapp.com' 'zook.co.za' 'www.zook.co.za'}
      valid_hosts.rindex("'#{request.host}'")
    end

    def not_processed?
      !@order.complete?
    end

    def signature_url
      logger.debug "Get signature url......................."
      map_data = @params.map do |key, val|
        val = "" if val.nil?
        "#{key}=#{CGI.escape(val)}" unless key == 'signature'
      end.compact.join('&')
      Digest::MD5.hexdigest(map_data)
    end

    def pass_phrase
      logger.debug "Get pass phrase......................."
      if Rails.env.production?
        ENV['payfast_pass_phrase']
      else
        ""
      end
    end

    def success_payment!
      logger.debug "Successful Payment......................."
      

      @payment = @order.payments.create!({
        amount: @order.total,
        payment_method: payment_method
      })

      while @order.next; end

      logger.debug "Payment. Created......................"

      logger.debug "Order status.....#{@order.state}................."
      if @order.complete?
        logger.debug "Order is complete.............."
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:order_completed] = true
        session[:order_id] = @order.id
      end
    end

    def cancel_payment
      logger.debug "Payment canceled......................."
      flash[:notice] = Spree.t('flash.cancel', scope: 'paypal')
      redirect_to checkout_state_path(@order.state, cancel_token: @params[:m_payment_id])
    end

    def payment_method
      logger.debug "Fetching payment method......................."
      Spree::PaymentMethod.where("type = ?", "Spree::Gateway::Payfast").first
    end

    def create_insert
      logger.debug "Creating Insert......................."
      @order = Spree::Order.find(@params[:m_payment_id])
      @order.special_instructions = @params[:item_description]
      if @order.save!
        logger.debug "Order update saved.............."
      end
    end
  end
end