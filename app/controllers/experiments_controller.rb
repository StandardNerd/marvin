class ExperimentsController < ApplicationController
  def index
    @training_runs = TrainingRun.joins(:project)
                                .where(projects: { user_id: current_user.id })
                                .order(created_at: :desc)
                                .includes(:project, :dataset)
  end

  def compare
    ids = params[:ids]&.split(',') || []
    @training_runs = TrainingRun.joins(:project)
                                .where(projects: { user_id: current_user.id })
                                .where(id: ids)
                                .includes(:project, :dataset, :training_metrics, :evaluations)
    if @training_runs.empty?
      redirect_to experiments_path, alert: 'Select experiments to compare.'
    end
  end
end
