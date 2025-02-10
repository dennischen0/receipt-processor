class ReceiptsController < ApplicationController

    @receipts = {}

    def process_receipt
        render json: { message: "Hello, world!" }
    end

    def points
        render json: { message: "Hello, world!" }
    end
end