class ModelArtifactsController < ApplicationController
  before_action :set_project
  before_action :set_artifact, only: [:show, :download]

  def index
    @artifacts = ModelArtifact.joins(:training_run)
                              .where(training_runs: { project_id: @project.id })
                              .order(created_at: :desc)
  end

  def new
    @training_run = @project.training_runs.completed.find(params[:training_run_id]) if params[:training_run_id]
    @completed_runs = @project.training_runs.completed
    @artifact = ModelArtifact.new(
      training_run: @training_run,
      base_model: @training_run&.base_model || @project.base_model,
      version: next_version
    )
  end

  def create
    @training_run = @project.training_runs.completed.find(artifact_params[:training_run_id])
    @artifact = @training_run.build_model_artifact(artifact_params)
    @artifact.base_model = @training_run.base_model

    if @artifact.save
      redirect_to project_model_artifact_path(@project, @artifact), notice: 'Adapter registered.'
    else
      @completed_runs = @project.training_runs.completed
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def download
    if @artifact.adapter_attached?
      redirect_to rails_blob_path(@artifact.adapter, disposition: 'attachment')
    else
      redirect_to project_model_artifact_path(@project, @artifact), alert: 'No adapter file available.'
    end
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_artifact
    @artifact = ModelArtifact.joins(:training_run)
                              .where(training_runs: { project_id: @project.id })
                              .find(params[:id])
  end

  def artifact_params
    params.require(:model_artifact).permit(:name, :version, :description, :training_run_id)
  end

  def next_version
    existing = ModelArtifact.joins(:training_run)
                            .where(training_runs: { project_id: @project.id })
                            .count
    "v#{existing + 1}"
  end
end
