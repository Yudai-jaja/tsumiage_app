require 'rails_helper'

RSpec.describe 'Users controller', type: :request do
  
  describe '#show' do
    context 'ユーザーが存在する場合' do
      let!(:user) { FactoryBot.create(:user) }
      
      before do
        get user_url(user)
      end
      
      it 'リクエストが成功する' do
        expect(response.status).to eq 200
      end
      
      it 'showテンプレートで表示されること' do
        expect(response).to render_template :show
      end
      
      it 'userが表示できている' do
        expect(response.body).to include user.name
      end
      
      it 'postsが表示できている' do
        expect(response.body).to include user.posts.find_by(id: user.posts.first.id).title
        expect(response.body).to include user.posts.find_by(id: user.posts.first.id).content
      end
    end
    context 'ユーザーが存在しない場合' do
      subject { -> { get user_path(id: 1 ) } }

      it { is_expected.to raise_error ActiveRecord::RecordNotFound }
    end
  end
  
  describe 'GET #new' do
    it 'リクエストが成功すること' do
      get new_user_url
      expect(response.status).to eq 200
    end
  end
  
  describe '#create' do
    context '値が正常な場合' do
      user_params = {    name: "Example Name",
                        email: "test@example.com",
                     password: "password",
        password_confirmation: "password"  }
                            
      it 'リクエストが成功すること(リダイレクト）' do
        post users_url, params: { user: user_params }
        expect(response.status).to eq 302
      end
      
      it 'リダイレクト先はユーザーroot_url' do
        post users_url, params: { user: user_params }
        expect(response).to redirect_to root_url
      end
      
      it 'ユーザーが登録されること' do
        expect do
          post users_url, params: { user: user_params }
        end.to change(User, :count).by(1)
      end
    end
    
    context '値が不正な場合' do
      user_params = {    name: "",
                        email: "",
                     password: "",
        password_confirmation: ""  }
      
      before { post users_url, params: { user: user_params } }
      
      it 'リクエストが成功すること（レンダー）' do
        expect(response.status).to eq 200
      end
      
      it 'エラーが表示されること' do
        expect(response.body).to include "登録が失敗しました。"
      end
      
      it 'ユーザー登録されないこと' do
        expect do
          post users_url, params: { user: user_params }
        end.not_to change(User, :count)
      end
    end
  end
  
  describe '#edit' do
    let(:user) { FactoryBot.create(:user) }
    
    context "未ログインの場合" do
      before do
        get edit_user_url(user)
      end
      
      it 'リダイレクトしているか' do
        expect(response.status).to eq 302
      end
      
      it 'リダイレクト先はroot_url' do
        expect(response).to redirect_to login_url
      end
    end
    
    context 'ログイン済みの場合' do
      before do
        post login_path, params: { session: { email: user.email,
                                      password: user.password,
                                      remember_me: '0'} }
        get edit_user_url(user)
      end
      
      it 'リクエストが成功すること' do
        expect(response.status).to eq 200
      end
      
      it 'userが表示出来ている' do
        expect(response.body).to include user.name
        expect(response.body).to include user.email
      end
    end
  end
  
  
  describe '#update' do
    #後で記述
    
  end
  
  describe '#destroy' do
    #後で記述
    
  end
  
  describe 'アクティベーション' do
    let!(:user_a) { FactoryBot.create(:user, activated: false) }
    
    context 'アクティベーションが成功する' do
      before do
        get edit_account_activation_path(user_a.activation_token, email: user_a.email)
      end
      
      it '正しいアクティベートURLにアクセスしてアクティベートされる' do
        expect(user_a.reload.activated?).to be_truthy
      end
      
      it 'userがログインされ、ユーザー画面が表示される' do
        expect(response).to redirect_to user_path(user_a)
      end
    end
    
    context 'アクティベーションが失敗する' do
      it 'トークンが間違っている' do
        get edit_account_activation_path(User.new_token, email: user_a.email)
        expect(user_a.reload.activated?).to be_falsey
      end
      
      it 'emailが間違っている' do
        get edit_account_activation_path(user_a.activation_token, email: 'wrong@example.com')
        expect(user_a.reload.activated?).to be_falsey
      end
    end
  end
    
  describe 'メール再送機能（resend_email_controller)' do
    let!(:user_a) { FactoryBot.create(:user, activated: false) }
    let!(:user_un) { FactoryBot.create(:user, activated: true) }
    
    context '未アクティブユーザーのメールアドレスの場合' do
      before do
        post resend_emails_path, params: { resend_emails: { email: user_a.email } }
      end
      
      it 'リクエストが成功し、root_urlにリダイレクトされる' do
        expect(response.status).to eq 302
        expect(response).to redirect_to root_url
      end
    end
    
    context 'アクティブ済みユーザーのメールアドレスの場合' do
      before do
        post resend_emails_path, params: { resend_emails: { email: user_un.email } }
      end
      
      it 'リクエストが成功し、login_pathにリダイレクトされる' do
        expect(response.status).to eq 302
        expect(response).to redirect_to login_path
      end
    end
    
    context '登録されていないメールアドレスの場合' do
      before do
        post resend_emails_path, params: { resend_emails: { email: "wrong@example.com" } }
      end
      
      it 'リクエストが成功し、new_pathにレンダーされる' do
        expect(response.status).to eq 200
      end
      
      it 'newテンプレートが表示される' do
        expect(response.body).to include "メールアドレスの確認メールの再送"
      end
    end
  end
  
  
end