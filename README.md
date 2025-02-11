# README

This README documents the steps necessary to get the application up and running.

## Prerequisites

If using rails:
- Ruby version: 3.0.0
- Rails version: 6.1.4

If using docker:
- Docker
- Docker Compose

## Usage instructions

### Using Docker
1. Build the docker image
```
cd receipt-processor
docker build -t receipt-processor .
```

2. Run the docker image
```
docker run -d -p 3000:3000 --name receipt-processor-container receipt-processor
```

The app will run on localhost:3000

### Using rails
1. Install dependencies
```
cd receipts-processor
bundle install
```

2. Run
```
rails s
```

#### How to run the test suite
```
bundle exec rspec
```