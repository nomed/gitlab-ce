# frozen_string_literal: true

class Projects::DivergingCountsController < Projects::ApplicationController
  before_action :require_non_empty_project
  before_action :authorize_download_code!

  def index
    respond_to do |format|
      format.json do
        service = Branches::DivergingCommitCountsService.new(repository)

        render json: branches.to_h { |branch| [branch.name, service.call(branch)] }
      end
    end
  end

  private

  def branches
    return [] if params[:names].blank?

    branch_names = params[:names].to_set
    repository.branches.filter do |branch|
      branch_names.include?(branch.name)
    end
  end
end
