class DatasetProcessingJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(dataset_id)
    dataset = Dataset.find(dataset_id)
    logger.info "[DatasetProcessing] Starting processing for dataset_id=#{dataset_id}"

    dataset.update!(status: 'processing')

    unless dataset.file.attached?
      dataset.update!(status: 'failed')
      logger.error "[DatasetProcessing] No file attached for dataset_id=#{dataset_id}"
      return
    end

    valid_count = 0
    error_count = 0

    begin
      dataset.file.open do |tempfile|
        tempfile.each_line.with_index(1) do |line, line_number|
          line = line.strip
          next if line.empty?

          process_line(dataset, line, line_number)
          valid_count += 1
        rescue => e
          error_count += 1
          logger.warn "[DatasetProcessing] Error on line #{line_number} for dataset_id=#{dataset_id}: #{e.message}"
        end
      end

      dataset.update!(
        status: 'ready',
        examples_count: dataset.dataset_examples.count
      )
      logger.info "[DatasetProcessing] Completed dataset_id=#{dataset_id}: #{valid_count} examples processed, #{error_count} errors"

    rescue => e
      dataset.update!(status: 'failed')
      logger.error "[DatasetProcessing] Failed for dataset_id=#{dataset_id}: #{e.message}"
      raise
    end
  end

  private

  def process_line(dataset, line, line_number)
    validation_errors = []

    begin
      data = JSON.parse(line)
    rescue JSON::ParserError => e
      dataset.dataset_examples.create!(
        messages: [],
        validation_errors: ["Line #{line_number}: Invalid JSON - #{e.message}"],
        accepted: nil
      )
      return
    end

    messages = data['messages']

    unless messages
      validation_errors << 'Missing "messages" field'
    end

    if messages && !messages.is_a?(Array)
      validation_errors << '"messages" must be an array'
      messages = []
    end

    if messages.is_a?(Array)
      valid_roles = %w[system user assistant]
      has_user = false
      has_assistant = false

      messages.each_with_index do |msg, i|
        unless msg.is_a?(Hash)
          validation_errors << "Message #{i + 1}: must be an object"
          next
        end

        role = msg['role']
        content = msg['content']

        unless role
          validation_errors << "Message #{i + 1}: missing 'role'"
        end

        unless valid_roles.include?(role)
          validation_errors << "Message #{i + 1}: invalid role '#{role}'"
        end

        unless content.present?
          validation_errors << "Message #{i + 1}: missing or empty 'content'"
        end

        has_user = true if role == 'user'
        has_assistant = true if role == 'assistant'
      end

      unless has_user && has_assistant
        validation_errors << 'Must have at least one user and one assistant message'
      end
    end

    dataset.dataset_examples.create!(
      messages: messages || [],
      metadata: data.except('messages'),
      validation_errors: validation_errors.presence,
      accepted: validation_errors.empty? ? nil : nil
    )
  end
end
