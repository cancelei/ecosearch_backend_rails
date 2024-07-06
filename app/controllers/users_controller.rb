class UsersController < ApplicationController
  before_action :authenticate_user!

  # GET /users
  def index
    @users = User.all
    render json: @users
  end

  # GET /users/:id
  def show
    @user = User.find(params[:id])
    render json: @user
  end

  # PUT /users/:id
  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    head :no_content
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
