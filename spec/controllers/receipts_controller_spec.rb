require 'rails_helper'

RSpec.describe ReceiptsController, type: :controller do
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
  let(:cache) { Rails.cache }
  let(:receipt) {
    {
      retailer: retailer_name,
      purchaseDate: purchase_date,
      purchaseTime: purchase_time,
      total: total,
      items: items
    }
  }
  let(:retailer_name) { "Another Store" }
  let(:purchase_date) { "2023-10-02" }
  let(:purchase_time) { "15:00" }
  let(:total) { "15.00" }
  let(:items) { 
    [
      { shortDescription: "Item 1", price: "5.00" },
      { shortDescription: "Item 2", price: "10.00" }
    ]
  }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe "POST #process_receipt" do
    it "returns a successful response and a new receipt id" do
      post :process_receipt, params: receipt
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response["id"]).to be_present
    end

    context "when the request is invalid" do
      it "returns an error response" do
        post :process_receipt, params: { }

        expect(response).to have_http_status(:bad_request)
      end

      context "when there are 0 items" do
        let(:items) { [] }

        it "returns bad request" do
          post :process_receipt, params: receipt
          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    describe "#calculate_points" do
      it "returns the correct total points" do
        post :process_receipt, params: receipt
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(Rails.cache.read(json_response["id"])).to eq(105)
      end

      context "test cases for each helper method" do
        before do
          allow_any_instance_of(ReceiptsController).to receive(:get_retailer_name_points).and_return(0)
          allow_any_instance_of(ReceiptsController).to receive(:get_price_points).and_return(0)
          allow_any_instance_of(ReceiptsController).to receive(:get_item_points).and_return(0)
          allow_any_instance_of(ReceiptsController).to receive(:get_date_points).and_return(0)
          allow_any_instance_of(ReceiptsController).to receive(:get_time_points).and_return(0)
        end
        
        describe "#get_retailer_name_points" do
          before do
            allow_any_instance_of(ReceiptsController).to receive(:get_retailer_name_points).and_call_original
          end
          context "when the retailer name is different" do
            let(:retailer_name) { "Another Stores" }

            it "returns the correct total points" do
              post :process_receipt, params: receipt
              json_response = JSON.parse(response.body)
              expect(Rails.cache.read(json_response["id"])).to eq(13)
            end
          end

          context "when the retailer name has non alphanumeric characters" do
            let(:retailer_name) { "Another Store    @#$@$" }

            it "returns the correct total points" do
              post :process_receipt, params: receipt
              json_response = JSON.parse(response.body)
              expect(Rails.cache.read(json_response["id"])).to eq(12)
            end
          end

          context "when the retailer name doesn't exist" do
            it "returns the correct total points" do
              post :process_receipt, params: receipt.delete("retailer")
              expect(response).to have_http_status(:bad_request)
            end
          end
        end

        describe "#get_price_points" do
          before do
            allow_any_instance_of(ReceiptsController).to receive(:get_price_points).and_call_original
          end
          context "when the total price is a multiple of 1" do
            let(:total) { "15.00" }

            it "returns the correct total points" do
              post :process_receipt, params: receipt
              json_response = JSON.parse(response.body)
              expect(Rails.cache.read(json_response["id"])).to eq(75)
            end
          end
          context "when the total price is a multiple of 0.25" do
            let(:total) { "15.25" }

            it "returns the correct total points" do
              post :process_receipt, params: receipt
              json_response = JSON.parse(response.body)
              expect(Rails.cache.read(json_response["id"])).to eq(25)
            end
          end

          context "when the total price is not a multiple of 1 or .25" do
            let(:total) { "12.01" }

            it "returns the correct total points" do
              post :process_receipt, params: receipt
              json_response = JSON.parse(response.body)
              expect(Rails.cache.read(json_response["id"])).to eq(0)
            end
          end
        end

        describe "#get_item_points" do
          before do
            allow_any_instance_of(ReceiptsController).to receive(:get_item_points).and_call_original
          end

          context "when there is 1 item" do
            let(:items) { [{ shortDescription: "Item 1", price: "100.00" }] }

            it "returns the correct total points" do
              post :process_receipt, params: receipt
              json_response = JSON.parse(response.body)
              expect(Rails.cache.read(json_response["id"])).to eq(20)
            end
          end

          context "when there are 11 items" do
            let(:items) {
              [
                { shortDescription: "Item 1", price: "82.00" },
                { shortDescription: "Item 2", price: "100.00" },
                { shortDescription: "Item 3", price: "100.00" },
                { shortDescription: "Item 4", price: "100.00" },
                { shortDescription: "Item 5", price: "100.00" },
                { shortDescription: "Item 6", price: "100.00" },
                { shortDescription: "Item 7", price: "100.00" },
                { shortDescription: "Item 8", price: "100.00" },
                { shortDescription: "Item 9", price: "100.00" },
                { shortDescription: "Item 10", price: "100.00" },
                { shortDescription: "Item 11", price: "1.00" }
              ]
            }

            it "returns the correct total points" do
              post :process_receipt, params: receipt
              json_response = JSON.parse(response.body)
              expect(Rails.cache.read(json_response["id"])).to eq(177 + 25)
            end
          end
        end

        describe "#get_date_points" do
          before do
            allow_any_instance_of(ReceiptsController).to receive(:get_date_points).and_call_original
          end

          context "when the purchase date is odd" do
            let(:purchase_date) { "2023-10-01" }

            it "returns the correct total points" do
              post :process_receipt, params: receipt
              json_response = JSON.parse(response.body)
              expect(Rails.cache.read(json_response["id"])).to eq(6)
            end
          end

          context "when the purchase date is even" do
            let(:purchase_date) { "2023-10-02" }

            it "returns the correct total points" do
              post :process_receipt, params: receipt
              json_response = JSON.parse(response.body)
              expect(Rails.cache.read(json_response["id"])).to eq(0)
            end
          end
        end

        describe "#get_time_points" do
          before do
            allow_any_instance_of(ReceiptsController).to receive(:get_time_points).and_call_original
          end

          context "when the purchase time is between 14:00 and 16:00" do
            let(:purchase_time) { "14:20" }

            it "returns the correct total points" do
              post :process_receipt, params: receipt
              json_response = JSON.parse(response.body)
              expect(Rails.cache.read(json_response["id"])).to eq(10)
            end
          end

          context "when the purchase time is not between 14:00 and 16:00" do
            let(:purchase_time) { "16:00" }

            it "returns the correct total points" do
              post :process_receipt, params: receipt
              json_response = JSON.parse(response.body)
              expect(Rails.cache.read(json_response["id"])).to eq(0)
            end
          end
        end
      end
    end
  end

  describe "GET #points" do
    it "returns points if they exist" do
      post :process_receipt, params: receipt
      receipt_json = JSON.parse(response.body)
      receipt_id = receipt_json["id"]

      get :points, params: { id: receipt_id }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response["points"]).to be_a(Integer)
    end

    it "returns not found when the id is invalid" do
      get :points, params: { id: "non_existent_id" }
      expect(response).to have_http_status(:not_found)
    end
  end
end