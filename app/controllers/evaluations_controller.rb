class EvaluationsController < ApplicationController
  before_action :set_project
  before_action :set_training_run
  before_action :set_evaluation, only: [:show]

  def new
    @evaluation = @training_run.evaluations.build(
      name: "Evaluation - #{Time.current.strftime('%Y-%m-%d %H:%M')}",
      status: 'pending'
    )
    @datasets = @project.datasets.ready
  end

  def create
    @evaluation = @training_run.evaluations.build(evaluation_params)
    @evaluation.status = 'pending'

    if @evaluation.save
      EvaluationJob.perform_later(@evaluation.id)
      redirect_to project_training_run_evaluation_path(@project, @training_run, @evaluation),
                  notice: 'Evaluation started.'
    else
      @datasets = @project.datasets.ready
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_training_run
    @training_run = @project.training_runs.find(params[:training_run_id])
  end

  def set_evaluation
    @evaluation = @training_run.evaluations.find(params[:id])
  end

  def evaluation_params
    params.require(:evaluation).permit(:name, :eval_dataset_id)
  end
end
