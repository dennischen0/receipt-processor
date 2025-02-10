require 'securerandom'

class ReceiptsController < ApplicationController


    def initialize
        super
    end

    def process_receipt
        receipt_id = SecureRandom.uuid

        retailer, purchase_date, purchase_time, total, items = params.expect(:retailer, :purchaseDate, :purchaseTime, :total, items: [[:shortDescription, :price]])

        receipt_data = { retailer: retailer, purchase_date: purchase_date, purchase_time: purchase_time, total: total, items: items }

        points = calculate_points(receipt_data)

        Rails.cache.write(receipt_id, points)
        render json: { id: receipt_id }
    rescue => e
        render json: { error: "Invalid request" }, status: :bad_request
    end

    def points
        points = Rails.cache.read(params[:id])

        if points
            render json: { "points": points}
        else
            render json: { error: "Not found" }, status: :not_found
        end
    end

    def calculate_points(receipt_data)
        total_points = 0
        total_points += get_retailer_name_points(receipt_data[:retailer])
        total_points += get_price_points(receipt_data[:total])
        total_points += get_item_points(receipt_data[:items])
        total_points += get_date_points(receipt_data[:purchase_date])
        total_points += get_time_points(receipt_data[:purchase_time])
        
        total_points
    end

    def get_retailer_name_points(retailer_name)
        retailer_name.count('A-Za-z0-9')
    end

    def get_price_points(total_price)
        price_points = 0
        price_float = total_price.to_f

        price_points += (price_float % 0.25).zero? ? 25 : 0
        price_points += (price_float % 1).zero? ? 50 : 0

        price_points
    end

    def get_item_points(items)
        item_points = 0
        
        item_points += items.count / 2 * 5

        items.each do |item|
            description = item[:shortDescription].strip # strip leading and trailing whitespace
            multiple_of_three = description.length % 3 == 0 ? true : false
            
            item_points += (item[:price].to_f * 0.2 ).ceil if multiple_of_three
        end

        item_points
    end

    def get_date_points(purchase_date)
        date = Date.parse(purchase_date)
        date.day.odd? ? 6 : 0
    end

    def get_time_points(purchase_time)
        time = Time.parse(purchase_time)
        (time.hour == 14 && time.min > 0) || time.hour == 15 ? 10 : 0
    end
end