class Authentication::PasswordsController < ApplicationController
  before_action :set_user

  class ::PasswordHolder
    include ActiveModel::Model
    include ActiveModel::Attributes

    def initialize(user, rest={password: "ddd"}
                  )
      super(rest)
      @user = user
    end

    attribute :current_password, :string
    attribute :password, :string
    attribute :password_confirmation, :string

    validates_length_of :password, minimum: 8
    # validates_presence_of :password_confirmation

    # I get repeqt errors if a use validates_confirmation_of
    validate do
      unless self.password == self.password_confirmation
        errors.add(:password_confirmation, "new passwords don't match")
      end
    end

    validate do
      unless @user.authenticate(current_password)
        errors.add(:current_password, "doesn't match what we have")
      end
    end

  end

  def edit
    @password_holder = PasswordHolder.new(@user)
  end

  def update

    params = password_params
    @password_holder = PasswordHolder.new(@user, params)
    unless @password_holder.valid?
      return render(:edit, status: :unprocessable_entity)
    end

    @user.password = @password_holder.password
    
    if @user.save()
       redirect_to root_path, notice: "Your password has been changed"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
  def set_user
    @user = Current.user
  end

  def password_params
    params
      .require(:password_holder)
      .permit(:password, :password_confirmation, :current_password)
      .with_defaults(current_password: "")
  end
end
