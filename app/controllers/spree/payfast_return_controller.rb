module Spree
  class PayfastReturnController < Spree::StoreController

    before_filter :assign_params

    def success
      success_payment
    end

    def failure
      failure_payment
    end

    def cancel
      cancel_payment
    end

    def assign_params
      @params = params
      puts "#####################################################PARAMS########################################################"
      puts @params
      puts "#####################################################END PARAMS######################################################"
      @order_id = @params[:m_payment_id]
      @order = Spree::Order.find(@order_id)
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