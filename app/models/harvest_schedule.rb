class HarvestSchedule < ActiveResource::Base
  include EnvironmentHelpers

  self.site = ENV["WORKER_HOST"]
  self.user = ENV["WORKER_API_KEY"]

  schema do
    attribute :parser_id,   :string
    attribute :start_time,  :datetime
    attribute :cron,        :string
    attribute :frequency,   :string
    attribute :at_hour,     :integer
    attribute :at_minutes,  :integer
    attribute :offset,      :integer
    attribute :environment, :string
    attribute :next_run_at, :datetime
    attribute :last_run_at, :datetime
    attribute :recurrent,   :boolean
    attribute :incremental, :boolean
    attribute :enrichments, :string
  end

  include ActiveResource::SchemaTypes

  validates_presence_of :parser_id, :start_time
  validates_presence_of :frequency, :at_hour, :at_minutes, if: ->(schedule) { schedule.recurrent && schedule.cron.blank? }

  class << self
    def find_from_environment(params, env)
      self.change_worker_env!(env)
      self.find(:all, params: params)
    end

    def destroy_all_for_parser(parser_id)
      environments = ['staging', 'production']
      environments = [Rails.env] if ['development','test'].include? Rails.env

      environments.each do |env|
        HarvestSchedule.find_from_environment({parser_id: parser_id}, env).each do |hs|
          HarvestSchedule.delete(hs.id)
        end
      end
    end
  end

  def simple?
    return true unless self.persisted?
    self.frequency.present?
  end

  def recurrent
    return true if @attributes["recurrent"].nil? || @attributes["recurrent"].to_s.match(/1|true/)
    return false if @attributes["recurrent"].to_s.match(/0|false/)
  end

  def parser
    @parser ||= begin
      Parser.find(self.parser_id) if self.respond_to?(:parser_id) && parser_id.present?
    rescue Mongoid::Errors::DocumentNotFound
      nil
    end
  end

  def oai?
    return false unless parser
    parser.oai?
  end

end