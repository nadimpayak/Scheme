class User < ActiveRecord::Base
  before_validation :ensure_session_token
  before_save :downcase_email_remove_whitespace
  validates :email, :name, :password_digest, :session_token, presence: true
  validates :email, uniqueness: true

  has_attached_file :avatar, default_url: 'http://schemeapp.com/assets/avatar-placeholder-3457dd70fea884c004730991df531cc8eb7d4b9abaca82d5e1b6aff46dde79e9.png';
  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\Z/

  has_many(
    :tasks,
    class_name: 'Task',
    primary_key: :id,
    foreign_key: :creator_id
  )

  has_one(
    :membership,
    class_name: 'Membership',
    primary_key: :id,
    foreign_key: :member_id
  )

  has_one(
    :team,
    through: :membership,
    source: :team
  )

  has_many(
    :teammates,
    through: :team,
    source: :members
  )

  has_many(
    :teammate_tasks,
    through: :team,
    source: :tasks
  )

  has_many(
    :projects,
    through: :team,
    source: :projects
  )

  has_many :task_comments


  attr_reader :password

  def password=(password)
    @password = password.strip
    self.password_digest = BCrypt::Password.create(password).to_s
  end

  def is_password?(password)
    BCrypt::Password.new(password_digest).is_password?(password.strip)
  end

  def self.find_by_credentials(email, password)
    user = User.find_by(email: email.downcase.strip)
    return nil unless user

    if user.is_password?(password)
      user
    else
      nil
    end
  end

  def reset_session_token!
    self.session_token = SecureRandom.urlsafe_base64
    save!
  end

  # return's tasks created by user & user's teammates
  def all_team_tasks
    self.teammate_tasks + self.tasks
  end

  private
    def ensure_session_token
      self.session_token ||= SecureRandom.urlsafe_base64
    end

    def downcase_email_remove_whitespace
      self.email = self.email.downcase.strip unless self.email.nil?
    end
end
