class Api::V1::UsersController < ApplicationController

  def index
    users = User.all
    render json: UserSerializer.new(users)
  end

  def show
    begin
      user = User.find(params[:id])
      render json: UserSerializer.new(user)
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'User not found.' }, status: :not_found
    end
  end

  def create
    begin
      user = User.create!(user_params)
    rescue ActiveRecord::RecordInvalid => error
      render json: {error: error.record.errors.full_messages.to_sentence}, status: :unprocessable_entity
    else
      render json: UserSerializer.new(user), status: :created
    end
  end


  private

  def user_params
    params.permit(:first_name, :last_name, :email, :lat, :lon, :is_remote, :about, :city, :state, :zipcode, :street)
  end
end
