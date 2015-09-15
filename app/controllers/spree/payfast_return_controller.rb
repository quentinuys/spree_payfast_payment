module Spree
  class PayfastReturnController < Spree::StoreController

    before_filter :assign_params

    def success
      #success_payment
    end

    def failure
      #failure_payment
    end

    def cancel
      #cancel_payment
    end

    def assign_params
      @params = params
      if @params.empty?
        flash.notice = "The params is empty"
      else
        flash.notice = "Params: #{@params}, Response: #{response.body}, Request: #{request.body}"
      end

      flash['order_completed'] = true
      redirect_to '/'
    end

    private

    def success_payment
      @order.payments.create!({
        amount: @order.total,
        payment_method: payment_method
      })
      @order.next
      if @order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:order_completed] = true
        session[:order_id] = nil
        redirect_to completion_route(@order)
      else
        redirect_to checkout_state_path(@order.state)
      end
    end

    def failure_payment
      
    end

    def cancel_payment
      flash[:notice] = Spree.t('flash.cancel', scope: 'paypal')
      redirect_to checkout_state_path(@order.state, cancel_token: @params[:m_payment_id])
    end

    def payment_method
      Spree::PaymentMethod.find(@params[:m_payment_id])
    end
  end
end