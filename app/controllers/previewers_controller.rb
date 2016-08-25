# The majority of The Supplejack Manager code is Crown copyright (C) 2014,
# New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# Some components are third party components that are licensed under
# the MIT license or otherwise publicly available.
# See https://github.com/DigitalNZ/supplejack_manager for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ and
# the Department of Internal Affairs.
# http://digitalnz.org/supplejack

# PreviewersController
class PreviewersController < ApplicationController
  before_filter :set_previewer, :validate_parser_content

  def create
    params[:environment] ||= 'staging'
    set_worker_environment_for(HarvestJob)

    render layout: false
  end

  # Initializes Parser and Version
  #
  # @author Eddie Gonzalez
  # @last_modified Eddie
  # def find_parser_and_version
  # end

  # Initializes Previewer
  #
  # @author Eddie
  # @last_modified Eddie
  def set_previewer
    @parser = Parser.find(params[:parser_id])
    @previewer = Previewer.new(@parser, params[:parser][:content],
                               current_user.id, params[:index],
                               params[:review])
    @previewer.create_preview_job
  end

  def validate_parser_content
    begin
      eval params[:parser][:content]
      @parser_error = false
    rescue => error
      @parser_error = { type: error.class, message: error.message }
    end
  end
end
