require 'digest/md5'
module Spree
  class PayfastReturnController < Spree::StoreController
    skip_before_filter  :verify_authenticity_token
    
    def success
      @order = current_order
      if @order.complete?
        flash.notice = "Thank you, Order Num: #{@order.id}. Your payment has been made and your order is being processed."
        flash['order_completed'] = true
        redirect_to completion_route(@order)
      else
        flash.notice = "There has been an error with your payment."
        redirect_to checkout_state_path(@order.state)
      end
      flash['order_completed'] = true
    end

    def notice
      logger.debug "Notice Method triggered..........."
      assign_params
      success_payment! if valid?
      head :ok
    end

    def cancel
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
      logger.debug "Validate host......................."
      valid_hosts = %W{'www.payfast.co.za' 'sandbox.payfast.co.za' 'w1w.payfast.co.za' 'w2w.payfast.co.za' 'localhost'}
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
      while @order.next; end

      @payment = @order.payments.create!({
        amount: @order.total,
        payment_method: payment_method
      })

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