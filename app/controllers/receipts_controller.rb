require 'securerandom'

class ReceiptsController < ApplicationController

    def process_receipt
        retailer, purchase_date, purchase_time, total, items = params.expect(:retailer, :purchaseDate, :purchaseTime, :total, items: [[:shortDescription, :price]])
        receipt_data = { 
            retailer: retailer, 
            purchase_date: purchase_date, 
            purchase_time: purchase_time, 
            total: total, 
            items: items 
        }

        points = calculate_points(receipt_data)

        receipt_id = SecureRandom.uuid
        Rails.cache.write(receipt_id, points)
        render json: { id: receipt_id }
    rescue => e
        render status: :bad_request
    end

    def points
        points = Rails.cache.read(params[:id])

        if points
            render json: { points: points}
        else
            render status: :not_found
        end
    end

    private

    def calculate_points(receipt_data)
        total_points = 0
        
        total_points += get_retailer_name_points(receipt_data[:retailer])
        total_points += get_price_points(receipt_data[:total])
        total_points += get_item_points(receipt_data[:items])
        total_points += get_date_points(receipt_data[:purchase_date])
        total_points += get_time_points(receipt_data[:purchase_time])
        
        total_points
    end

    # Calculate points based on the retailer's name
    def get_retailer_name_points(retailer_name)
        retailer_name.count('A-Za-z0-9')
    end

    # Calculate points based on the total price
    def get_price_points(total_price)
        price_points = 0
        price_float = total_price.to_f

        price_points += 25 if (price_float % 0.25).zero?
        price_points += 50 if (price_float % 1).zero?

        price_points
    end
    
    # Calculate points based on the items
    def get_item_points(items)
        item_points = 0
        
        item_points += items.count / 2 * 5 # 5 points for every 2 items

        # 20% of the price of each item whose description length is a multiple of 3
        items.each do |item|
            description = item[:shortDescription].strip # strip leading and trailing whitespace
            multiple_of_three = (description.length % 3).zero?
            
            item_points += (item[:price].to_f * 0.2 ).ceil if multiple_of_three
        end

        item_points
    end

    # Calculate points based on the purchase date
    def get_date_points(purchase_date)
        date = Date.parse(purchase_date)
        date.day.odd? ? 6 : 0
    end

    # Calculate points based on the purchase time
    def get_time_points(purchase_time)
        time = Time.parse(purchase_time)

        # 10 points if the purchase time is between 2:00 PM and 4:00 PM Exclusive
        (time.hour == 14 && time.min > 0) || time.hour == 15 ? 10 : 0
    end
end