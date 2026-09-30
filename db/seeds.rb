# frozen_string_literal: true

puts "Seeding demo data..."

# Create demo user
user = User.find_or_create_by!(email: 'demo@example.com') do |u|
  u.name = 'Demo User'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end
puts "Created user: #{user.email}"

# Create demo project
project = Project.find_or_create_by!(user: user, name: 'Customer Support Bot') do |p|
  p.description = 'Fine-tuning a language model for customer support conversations using QLoRA.'
  p.base_model = 'Qwen/Qwen3-8B'
end
puts "Created project: #{project.name}"

# Create demo dataset
dataset = Dataset.find_or_create_by!(project: project, name: 'support-conversations-v1') do |d|
  d.description = 'Customer support conversations collected from the help desk system.'
  d.format = 'jsonl'
  d.status = 'ready'
end

# Create example conversations
conversations = [
  {
    messages: [
      { role: 'user', content: 'How do I reset my password?' },
      { role: 'assistant', content: 'To reset your password, go to the login page and click "Forgot Password". Enter your email address and we\'ll send you a reset link. The link expires after 24 hours.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'I can\'t access my account. It says it\'s locked.' },
      { role: 'assistant', content: 'Account lockouts typically occur after 5 failed login attempts. Your account will automatically unlock after 30 minutes. If you need immediate access, I can unlock it for you. Could you please verify your email address?' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'How do I upgrade my plan?' },
      { role: 'assistant', content: 'You can upgrade your plan by going to Settings > Billing > Change Plan. You\'ll see all available plans with their features and pricing. The upgrade takes effect immediately, and you\'ll be charged a prorated amount for the remainder of your billing cycle.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'Can I export my data?' },
      { role: 'assistant', content: 'Yes! Go to Settings > Data > Export. You can export your data in CSV or JSON format. The export includes all your projects, tasks, and attachments. Large exports may take a few minutes to prepare, and we\'ll email you the download link when it\'s ready.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'The app is running very slowly today.' },
      { role: 'assistant', content: 'I\'m sorry to hear that. Let me check a few things: 1) Clear your browser cache and cookies. 2) Try using an incognito/private window. 3) Check if the issue persists on a different browser. If the problem continues, it may be a temporary server issue. You can check our status page at status.example.com for any ongoing incidents.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'How do I add team members?' },
      { role: 'assistant', content: 'To add team members, go to Settings > Team > Invite Members. Enter their email addresses and select their role (Admin, Editor, or Viewer). They\'ll receive an invitation email with a link to join your workspace. Note that the number of team members depends on your plan.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'I accidentally deleted a project. Can I recover it?' },
      { role: 'assistant', content: 'Deleted projects are moved to the Trash and kept for 30 days. Go to Settings > Trash to find your deleted project and click "Restore". If more than 30 days have passed, the project is permanently deleted and cannot be recovered. For future reference, you can also create backups from Settings > Data > Backups.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'What integrations do you support?' },
      { role: 'assistant', content: 'We support integrations with: Slack (notifications & commands), GitHub (issue syncing), Jira (two-way sync), Google Calendar (deadline tracking), Zapier (1000+ apps), and our REST API for custom integrations. You can set up integrations from Settings > Integrations.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'How do I set up two-factor authentication?' },
      { role: 'assistant', content: 'To enable 2FA: 1) Go to Settings > Security > Two-Factor Authentication. 2) Click "Enable". 3) Scan the QR code with an authenticator app (Google Authenticator, Authy, etc.). 4) Enter the 6-digit code to verify. 5) Save the backup codes somewhere safe. Once enabled, you\'ll need the code each time you log in.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'Is there a mobile app?' },
      { role: 'assistant', content: 'Yes, we have mobile apps for both iOS and Android. You can download them from the App Store or Google Play Store. The mobile app supports most features including task management, notifications, and file uploads. Real-time collaboration and some admin features are currently desktop-only.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'How do I cancel my subscription?' },
      { role: 'assistant', content: 'To cancel your subscription, go to Settings > Billing > Cancel Subscription. Your account will remain active until the end of your current billing period. You can download your data before cancellation from Settings > Data > Export. If you change your mind, you can reactivate within 90 days without losing any data.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'The file upload keeps failing.' },
      { role: 'assistant', content: 'File upload issues are usually caused by: 1) File size exceeding the limit (max 100MB per file, 500MB per upload). 2) Unsupported file format. 3) Unstable network connection. Try: reducing the file size, using a supported format (PDF, DOCX, PNG, JPG, CSV), or using a wired connection. If the issue persists, try our desktop uploader which supports resume on interruption.' }
    ]
  },
  {
    messages: [
      { role: 'system', content: 'You are a helpful customer support assistant.' },
      { role: 'user', content: 'I was charged twice for my subscription this month.' },
      { role: 'assistant', content: 'I\'m sorry about the double charge. I can see your account and will investigate this right away. Double charges sometimes occur during plan changes or payment method updates. I\'ll process a refund for the duplicate charge within 3-5 business days. You\'ll receive a confirmation email once the refund is initiated. Is there anything else I can help with?' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'Can I use keyboard shortcuts?' },
      { role: 'assistant', content: 'Yes! Press Ctrl+/ (or Cmd+/ on Mac) to see all keyboard shortcuts. Some popular ones: Ctrl+K for quick search, Ctrl+N for new task, Ctrl+Enter to save, Esc to close modals. You can customize shortcuts in Settings > Preferences > Keyboard Shortcuts.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'How do I change my email address?' },
      { role: 'assistant', content: 'To change your email: 1) Go to Settings > Account > Email. 2) Enter your new email address. 3) Enter your current password to confirm. 4) We\'ll send a verification email to your new address. 5) Click the verification link to complete the change. Note: your login email will change immediately after verification.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'What\'s the difference between the Pro and Enterprise plans?' },
      { role: 'assistant', content: 'Key differences between Pro and Enterprise: Pro includes up to 50 team members, 100GB storage, standard integrations, and email support. Enterprise includes unlimited team members, 1TB storage, advanced integrations (SSO, SCIM), priority support with dedicated account manager, custom onboarding, audit logs, and advanced security features. Enterprise pricing is custom — contact our sales team for a quote.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'How do I create an API key?' },
      { role: 'assistant', content: 'To create an API key: 1) Go to Settings > Developer > API Keys. 2) Click "Generate New Key". 3) Give it a descriptive name (e.g., "Production Server"). 4) Set the permissions (read-only or read-write). 5) Copy the key immediately — it won\'t be shown again. You can revoke keys at any time from the same page. See our API documentation at docs.example.com/api for usage details.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'I need to transfer project ownership to another team member.' },
      { role: 'assistant', content: 'To transfer project ownership: 1) Open the project. 2) Go to Project Settings > General. 3) Click "Transfer Ownership". 4) Select the team member (they must be an Admin or Editor). 5) Confirm the transfer. The new owner will receive a notification. You\'ll retain your current role unless the new owner changes it. Note: only project owners and workspace admins can perform transfers.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'Is there a way to automate recurring tasks?' },
      { role: 'assistant', content: 'Yes! We support task automation in several ways: 1) Recurring tasks: Set any task to repeat daily, weekly, monthly, or on a custom schedule. 2) Templates: Create task templates with predefined subtasks and assignments. 3) Rules: Set up automation rules (e.g., "When task is completed, create a follow-up task"). 4) API/Zapier: Use our API or Zapier integration for more complex automations. Go to any task and click the repeat icon to set up recurrence.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'I forgot which email I used to sign up.' },
      { role: 'assistant', content: 'I can help you find your account. Here are a few options: 1) Check your email inboxes for a welcome email from us. 2) Try common email addresses you use. 3) If you signed up with Google or GitHub, try those login options on our login page. 4) Contact us at support@example.com with your name and any details you remember about your account, and we\'ll help locate it. For security reasons, we can\'t disclose account emails without proper identity verification.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'How does version control work for documents?' },
      { role: 'assistant', content: 'Our document version control saves a new version each time you make changes. You can: 1) View version history by clicking the clock icon on any document. 2) Compare versions side-by-side. 3) Restore any previous version. 4) Name important versions for easy reference. Versions are kept for 90 days on Pro plans and indefinitely on Enterprise. Auto-save creates checkpoints every 5 minutes while editing.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'Can multiple people edit a document at the same time?' },
      { role: 'assistant', content: 'Yes, we support real-time collaboration! Multiple users can edit the same document simultaneously. You\'ll see other users\' cursors and changes in real-time. Key features: colored cursors showing who\'s editing where, real-time change sync, comment threads for discussions, suggestion mode for tracked changes, and presence indicators showing who\'s currently viewing. Works best on Chrome, Firefox, and Edge.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'How do I set up email notifications?' },
      { role: 'assistant', content: 'To configure email notifications: 1) Go to Settings > Notifications > Email. 2) Choose your notification preferences: All activity, Mentions only, or Custom. 3) For Custom, select specific events: task assignments, comments, due dates, status changes, etc. 4) Set frequency: Immediate, hourly digest, or daily digest. 5) You can also set per-project notification preferences by going to the project settings. Tip: Use the "Do Not Disturb" schedule to pause notifications during off-hours.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'What file formats can I import?' },
      { role: 'assistant', content: 'We support importing from: CSV files (with column mapping), JSON files, Microsoft Project (.mpp), Trello (direct import via API), Asana (direct import via API), Jira (XML export), Notion (export & import), and plain text/Markdown files. To import: go to Settings > Import > select your source format. For large imports (>10,000 items), use our bulk import API for better performance.' }
    ]
  },
  {
    messages: [
      { role: 'user', content: 'How secure is my data?' },
      { role: 'assistant', content: 'Security is our top priority. Here\'s how we protect your data: 1) Encryption: AES-256 at rest, TLS 1.3 in transit. 2) Infrastructure: hosted on AWS with SOC 2 Type II certification. 3) Access: Role-based access control, SSO support, IP allowlisting (Enterprise). 4) Compliance: GDPR, CCPA, and HIPAA compliant (Enterprise). 5) Monitoring: 24/7 security monitoring, regular penetration testing, and bug bounty program. 6) Backups: Daily automated backups with 30-day retention. For more details, visit our security page at security.example.com.' }
    ]
  }
]

if dataset.dataset_examples.count == 0
  conversations.each_with_index do |conv, i|
    DatasetExample.create!(
      dataset: dataset,
      messages: conv[:messages],
      accepted: i < 20 ? true : nil, # Accept most, leave some for review
      validation_errors: nil
    )
  end
  dataset.update!(examples_count: dataset.dataset_examples.count)
  puts "Created #{conversations.size} example conversations"
end

# Create a completed (demo) training run
training_run = TrainingRun.find_or_create_by!(project: project, name: 'support-qlora-v1 (demo)') do |tr|
  tr.dataset = dataset
  tr.base_model = 'Qwen/Qwen3-8B'
  tr.status = 'completed'
  tr.started_at = 35.minutes.ago
  tr.finished_at = 3.minutes.ago
  tr.configuration = {
    'method' => 'qlora',
    'lora_r' => 16,
    'lora_alpha' => 32,
    'lora_dropout' => 0.05,
    'learning_rate' => 0.0002,
    'epochs' => 3,
    'batch_size' => 1,
    'gradient_accumulation_steps' => 8,
    'max_seq_length' => 2048,
    'quantization' => '4bit_nf4'
  }
  tr.metrics = {
    'latest_step' => 225,
    'latest_epoch' => 3.0,
    'latest_loss' => 0.8234
  }
end

# Create demo training metrics (simulate training curve)
if training_run.training_metrics.count == 0
  75.times do |i|
    step = (i + 1) * 3
    epoch = (step.to_f / 75).round(2)
    # Simulate a decreasing loss curve
    base_loss = 2.5 * Math.exp(-0.015 * step) + 0.7 + rand(-0.05..0.05)
    lr = 0.0002 * (1.0 - step.to_f / 230)

    TrainingMetric.create!(
      training_run: training_run,
      step: step,
      epoch: epoch,
      loss: base_loss.round(4),
      learning_rate: lr.round(6),
      raw_metrics: { step: step, epoch: epoch, loss: base_loss.round(4), learning_rate: lr.round(6) }
    )
  end
  puts "Created #{training_run.training_metrics.count} training metrics"
end

# Create demo evaluation
evaluation = Evaluation.find_or_create_by!(training_run: training_run, name: 'Evaluation - Demo') do |e|
  e.status = 'completed'
  e.metrics = {
    'exact_match' => 0.12,
    'text_similarity' => 0.67,
    'aggregate_score' => 0.45
  }
  e.results = conversations.first(5).map.with_index do |conv, i|
    user_msg = conv[:messages].find { |m| m[:role] == 'user' }
    assistant_msg = conv[:messages].find { |m| m[:role] == 'assistant' }
    {
      'input' => user_msg&.dig(:content),
      'expected' => assistant_msg&.dig(:content),
      'actual' => "[Demo] #{assistant_msg&.dig(:content)&.slice(0, 100)}...",
      'exact_match' => false,
      'similarity' => (0.5 + rand * 0.4).round(3)
    }
  end
end
puts "Created demo evaluation"

# Create demo model artifact
artifact = ModelArtifact.find_or_create_by!(training_run: training_run, name: 'support-assistant') do |a|
  a.version = 'v1'
  a.base_model = 'Qwen/Qwen3-8B'
  a.description = 'Demo adapter for customer support conversations. This is demo data and does not represent a real trained model.'
end
puts "Created demo model artifact: #{artifact.display_name}"

# Create a second project with a pending training run
project2 = Project.find_or_create_by!(user: user, name: 'Code Review Assistant') do |p|
  p.description = 'Fine-tuning for automated code review suggestions.'
  p.base_model = 'Qwen/Qwen3-8B'
end
puts "Created project: #{project2.name}"

puts "\n\nDemo data seeded successfully!"
puts "Login with: demo@example.com / password123"
puts "\nNote: Training runs marked as 'demo' do not represent real trained models."
