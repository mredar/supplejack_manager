# The majority of The Supplejack Manager code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3. Some components are 
# third party components that are licensed under the MIT license or otherwise publicly available. 
# See https://github.com/DigitalNZ/supplejack_manager for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and the Department of Internal Affairs. 
# http://digitalnz.org/supplejack

class UsersController < ApplicationController
  load_and_authorize_resource

  def index
    if params[:active] == 'false'
      @users = User.deactivated
    else
      @users = User.active
    end
  end

  def new
  end

  def create
    if @user.save
      redirect_to users_path
    else
      render :new
    end
  end

  def edit
  end

  def update
    if params[:user]
      authorize! :edit_users, @user if params[:user][:role]

      if needs_password?(@user, params)
        if @user.update_attributes(params[:user])
          sign_in(@user, bypass: true) if @user == current_user
          redirect_to safe_users_path, notice: 'User was successfully updated.'
        else
          render :edit
        end
      else
        params[:user].delete(:password)
        @user.update_without_password(params[:user])
        redirect_to safe_users_path, notice: 'User was successfully updated.'
      end
    else
      redirect_to safe_users_path, notice: 'User could not be updated'
    end
  end

  private

  def needs_password?(user, params)
    @user.email != params[:user][:email] ||
      params[:user][:password].present?
  end
end
