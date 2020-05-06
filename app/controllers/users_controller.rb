class UsersController < ApplicationController
  before_action :logged_in_user, only: [:edit, :update, :destroy]
  before_action :correct_user , only: [:edit, :destroy]


  def index
    @q = User.ransack(params[:q])
    users = @q.result(distinct: true)
    @users = users.page(params[:page]).per(30)
  end
  
  def new
    @user = User.new
  end
  
  def show
    @user = User.find(params[:id])
    @post = Post.new if current_user? @user
    
    posts = @user.posts.where(post_id: nil)
    @q = posts.ransack(params[:q])
    @posts = @q.result(distinct: true).page(params[:page]).per(30)
    
    @path = user_path(@user)
  end
  
  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_activation_email
      flash[:info] = "入力されたメールアドレスに送信したメールをご確認ください。"
      redirect_to root_url
    else
      flash.now[:danger] = "登録が失敗しました。"
      render 'new'
    end
  end
  
  def edit
    @user = User.find(params[:id])
  end
  
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      flash[:success] = "プロフィールを更新しました。"
      redirect_to user_path @user
    else
      render 'edit'
    end
  end
  
  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "ユーザーを削除しました。"
    redirect_to users_url
  end
  
  def following
    @user  = User.find(params[:id])
    @users = @user.following.page(params[:page])
    render 'show_follow'
  end
  
  def followers
    @user  = User.find(params[:id])
    @users = @user.followers.page(params[:page])
    render 'show_follow'
  end
  
  private
    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation,
                                   :profile, :image_name)
    end
    
    def correct_user
      @user = User.find(params[:id])
      redirect_to root_url unless current_user?(@user)
    end
    
    # def set_default_icon
    #   default_image = ImageNameUploader.default_url()
    #   self.update_attributes(image_name: default_image)
    # end
end
