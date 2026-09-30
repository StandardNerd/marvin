class DatasetsController < ApplicationController
  before_action :set_project
  before_action :set_dataset, only: [:show, :edit, :update, :destroy, :process_file]

  def new
    @dataset = @project.datasets.build(format: 'jsonl', status: 'uploaded')
  end

  def create
    @dataset = @project.datasets.build(dataset_params)
    @dataset.status = 'uploaded'
    @dataset.format ||= 'jsonl'

    if @dataset.save
      DatasetProcessingJob.perform_later(@dataset.id) if @dataset.file.attached?
      redirect_to project_dataset_path(@project, @dataset), notice: 'Dataset uploaded. Processing will begin shortly.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @filter = params[:filter] || 'all'
    examples = @dataset.dataset_examples
    examples = case @filter
               when 'accepted' then examples.accepted
               when 'rejected' then examples.rejected
               when 'needs_review' then examples.needs_review
               when 'errors' then examples.with_errors
               else examples
               end
    @pagy, @examples = pagy(examples.order(created_at: :asc))
  end

  def edit; end

  def update
    if @dataset.update(dataset_params.except(:file))
      redirect_to project_dataset_path(@project, @dataset), notice: 'Dataset updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @dataset.destroy
    redirect_to project_path(@project), notice: 'Dataset deleted.'
  end

  def process_file
    @dataset.update!(status: 'uploaded')
    DatasetProcessingJob.perform_later(@dataset.id)
    redirect_to project_dataset_path(@project, @dataset), notice: 'Reprocessing started.'
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_dataset
    @dataset = @project.datasets.find(params[:id])
  end

  def dataset_params
    params.require(:dataset).permit(:name, :description, :format, :file)
  end
end
