FROM ruby:3.0-alpine

RUN apk add --no-cache build-base

RUN gem install riemann-client faker

WORKDIR /app
COPY send_metrics.rb /app/

CMD ["ruby", "/app/send_metrics.rb"]