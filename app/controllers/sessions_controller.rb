class SessionsController < ApplicationController
  before_action :redirect_if_authenticated

  CIRTIFICATE_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'
  FIREBASE_PROJECT_ID = ENV['FIREBASE_PROJECT_ID']

  def create
    id_token = params.required(:idToken)

    # https://firebase.google.com/docs/auth/admin/verify-id-tokens?hl=ja
    _, decoded_token_header = JWT.decode(id_token, nil, false)

    uri = URI.parse(CIRTIFICATE_URL)
    certificate = JSON.parse(Net::HTTP.get_response(uri).body).fetch(decoded_token_header["kid"])
    public_key = OpenSSL::X509::Certificate.new(certificate).public_key
    decoded_token_payload, _ = JWT.decode(id_token, public_key, true, aud: FIREBASE_PROJECT_ID, verify_aud: true, algorithm: decoded_token_header["alg"])

    # decoded_token_payload = {
    #   "name"=>"Takeuchi Yuichi",
    #   "picture"=>"https://lh3.googleusercontent.com/a-/AAuE7mAZU7Rh7lIFStzfWGe3tC24qDIX4UIoEWR8426flA",
    #   "iss"=>"https://securetoken.google.com/rails-firebase-sample",
    #   "aud"=>"rails-firebase-sample",
    #   "auth_time"=>1580712233,
    #   "user_id"=>"Qgk3sd1HgoPLVbSy8uXAWnRmWmx1",
    #   "sub"=>"Qgk3sd1HgoPLVbSy8uXAWnRmWmx1",
    #   "iat"=>1580712233,
    #   "exp"=>1580715833,
    #   "email"=>"yuichi.takeuchi@takeyuweb.co.jp",
    #   "email_verified"=>true,
    #   "firebase"=>{
    #     "identities"=>{
    #       "google.com"=>["100008179958237311525"],
    #       "email"=>["yuichi.takeuchi@takeyuweb.co.jp"]
    #     },
    #     "sign_in_provider"=>"google.com"
    #   }
    # }
    session[:login_name] = decoded_token_payload["name"]

    render json: { ok: true }, status: :created
  rescue => e
    render json: { ok: false, message: e.message }, status: :internal_server_error
  end

  def destroy
    session.delete(:login_name)
    redirect_to new_session_path
  end

  private

  def redirect_if_authenticated
    redirect_to root_path if session[:logged_in]
  end
end
