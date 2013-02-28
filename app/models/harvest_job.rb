class HarvestJob < ActiveResource::Base
  
  self.site = ENV["WORKER_HOST"]
  self.user = ENV["WORKER_API_KEY"]

  schema do
    attribute :start_time,            :datetime
    attribute :end_time,              :datetime
    attribute :records_harvested,     :integer
    attribute :throughput,            :float
    attribute :duration,              :float
    attribute :status,                :string
    attribute :user_id,               :string
    attribute :parser_id,             :string
    attribute :version_id,            :string
    attribute :harvest_schedule_id,   :string
    attribute :environment,           :string
    attribute :failed_records_count,  :integer
    attribute :invalid_records_count, :integer
    attribute :created_at,            :datetime
    attribute :incremental,           :boolean
  end

  include ActiveResource::SchemaTypes

  add_response_method :http

  class << self
    def build(attributes={})
      attributes.reverse_merge!({parser_id: nil, version_id: nil, user_id: nil, limit: nil, environment: nil})
      new(attributes)
    end

    def from_parser(parser, user=nil)
      self.new(parser_id: parser.id, version_id: nil, limit: nil, user_id: user.try(:id), environment: nil)
    end

    def search(params={})
      params = params.try(:dup).try(:symbolize_keys) || {}
      params.reverse_merge!(status: "active", page: 1, environment: ["staging","production"])
      harvest_jobs = self.find(:all, params: params)
      Kaminari::PaginatableArray.new(
        harvest_jobs,{
          limit: harvest_jobs.http['X-limit'].to_i,
          offset: harvest_jobs.http['X-offset'].to_i,
          total_count: harvest_jobs.http['X-total'].to_i
      })
    end
  end

  def user
    @user ||= begin
      User.find(self.user_id) if self.respond_to?(:user_id) && user_id.present?
    rescue Mongoid::Errors::DocumentNotFound
      nil
    end
  end

  def parser
    @parser ||= begin
      Parser.find(self.parser_id) if self.respond_to?(:parser_id) && parser_id.present?
    rescue Mongoid::Errors::DocumentNotFound
      nil
    end
  end

  def harvest_schedule
    @harvest_schedule ||= begin
      HarvestSchedule.find(self.harvest_schedule_id) if self.respond_to?(:harvest_schedule_id) && harvest_schedule_id.present?
    rescue Mongoid::Errors::DocumentNotFound
      nil
    end
  end

  def finished?
    self.status == "finished"
  end
end