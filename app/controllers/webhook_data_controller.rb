class WebhookDataController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :update]
  require 'httparty'

  def create
    webhook_data = WebhookData.new(webhook_data_params)
    if webhook_data.save
      notify_third_party_webhooks(webhook_data)
      render json: webhook_data, status: :created
    else
      render json: { errors: webhook_data.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    webhook_data = WebhookData.find(params[:id])
    if webhook_data.update(webhook_data_params)
      notify_third_party_webhooks(webhook_data)
      render json: webhook_data, status: :ok
    else
      render json: { errors: webhook_data.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def webhook_data_params
    params.require(:webhook_data).permit(:name, :data)
  end

  def notify_third_party_webhooks(webhook_data)
    endpoints = YAML.load_file('config/third_party_endpoints.yml')[Rails.env]

    endpoints.each do |endpoint|
      response = HTTParty.post(endpoint, body: webhook_data.to_json, headers: { 'Content-Type' => 'application/json' })

      # You can handle the response as per your requirements, e.g., logging or error handling
      puts "Webhook notification sent to #{endpoint}. Response code: #{response.code}, Response body: #{response.body}"
    end
  end
end
