# README

This micro service implements the requirements for the receipt processer API. The receipts controller has two main functions:

1. **process_receipt**: Handles generating the point totals for the receipt provided in the POST request. It performs simple input validation (ensuring the required fields exist) and stores the point total in an in-memory cache along with a generated GUID that is returned to the caller.
2. **points**: Returns the point total given a GUID, or a 404 status if the GUID was not found.

### Considerations

Receipts are processed in the `process_receipt` function during the initial POST request. This approach is efficient given the API's purpose. Not storing the full receipt in the database saves space.

If the microservice needs to process many receipts concurrently, calculating the point totals during the POST request may not be optimal. In such cases, a separate background task should be created to handle the processing. However, this would require handling the possibility of someone requesting the point totals before a receipt is fully processed.

## Prerequisites

If using Rails:
- Ruby version: 3.4.1
- Rails version: 8.0.1

If using Docker:
- Docker
- Docker Compose

## Usage instructions

### Using Docker
1. Build the Docker image:
    ```sh
    cd receipt-processor
    docker build -t receipt-processor .
    ```

2. Run the Docker image:
    ```sh
    docker run -d -p 3000:3000 --name receipt-processor-container receipt-processor
    ```

    The app will run on `http://localhost:3000`.

### Using Rails
1. Install dependencies:
    ```sh
    cd receipts-processor
    bundle install
    ```

2. Run the Rails server:
    ```sh
    rails s
    ```
    
    The app will run on `http://localhost:3000`.

## Running the Test Suite

To run the RSpec test suite, use the following command:

    bundle exec rspec
