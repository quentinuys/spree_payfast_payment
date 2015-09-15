module Spree
  class PayfastReturnController < Spree::StoreController

    def success
      flash.notice = "Thank you, order num: #{session[:order_id]}. your payment has been made and your order is processed."
      flash['order_completed'] = true
      redirect_to '/cart'
    end

    def notice
      head :ok
      assign_params
      create_insert
    end

    def cancel
      assign_params
      flash.notice = "Not happy with the payment system? Try another."
      redirect_to '/checkout/payment'
    end

    def assign_params
      @params = params
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

    def cancel_payment
      flash[:notice] = Spree.t('flash.cancel', scope: 'paypal')
      redirect_to checkout_state_path(@order.state, cancel_token: @params[:m_payment_id])
    end

    def payment_method
      Spree::PaymentMethod.find(@params[:m_payment_id])
    end

    def create_insert
       @order = Spree::Order.find(@params[:m_payment_id])
       @order.special_instructions = @params[:item_description]
       @order.save!
    end
  end
end