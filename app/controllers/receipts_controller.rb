require 'securerandom'

class ReceiptsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:process_receipt]

    def index
        @receipts = Rails.cache.read_multi(*Rails.cache.instance_variable_get(:@data).keys)
    end

    def process_receipt
        points = ReceiptPointsCalculator.new(receipt_params).calculate

        receipt_id = SecureRandom.uuid
        Rails.cache.write(receipt_id, points)
        render json: { id: receipt_id }
    rescue => e
        render json: { error: 'Bad request' }, status: :bad_request
    end

    def points
        points = Rails.cache.read(params[:id])

        if points
            render json: { points: points}
        else
            render json: { error: 'Not found' }, status: :not_found
        end
    end

    private

    def receipt_params
        retailer, purchase_date, purchase_time, total, items = params.expect(:retailer, :purchaseDate, :purchaseTime, :total, items: [[:shortDescription, :price]])
        receipt_data = { 
            retailer: retailer, 
            purchase_date: purchase_date, 
            purchase_time: purchase_time, 
            total: total, 
            items: items 
        }
    end
end